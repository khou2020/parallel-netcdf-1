/*
 *  Copyright (C) 2003, Northwestern University and Argonne National Laboratory
 *  See COPYRIGHT notice in top-level directory.
 */
/* $Id$ */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#include <stdio.h>

#include <mpi.h>

#include <pnc_debug.h>
#include <common.h>
#include "nc.h"
#include "ncx.h"

/*----< ncmpio_free_NC() >----------------------------------------------------*/
void
ncmpio_free_NC(NC *ncp)
{
    if (ncp == NULL) return;

    ncmpio_free_NC_dimarray(&ncp->dims);
    ncmpio_free_NC_attrarray(&ncp->attrs);
    ncmpio_free_NC_vararray(&ncp->vars);

    if (ncp->comm    != MPI_COMM_NULL) MPI_Comm_free(&ncp->comm);
    if (ncp->mpiinfo != MPI_INFO_NULL) MPI_Info_free(&ncp->mpiinfo);

    if (ncp->get_list != NULL) NCI_Free(ncp->get_list);
    if (ncp->put_list != NULL) NCI_Free(ncp->put_list);
    if (ncp->abuf     != NULL) NCI_Free(ncp->abuf);
    if (ncp->path     != NULL) NCI_Free(ncp->path);

    NCI_Free(ncp);
}

/*----< ncmpio_dup_NC() >----------------------------------------------------*/
NC *
ncmpio_dup_NC(const NC *ref)
{
    NC *ncp;

    ncp = (NC *) NCI_Calloc(1, sizeof(NC));
    if (ncp == NULL) return NULL;

    *ncp = *ref;

    if (ncmpio_dup_NC_dimarray(&ncp->dims,   &ref->dims)  != NC_NOERR ||
        ncmpio_dup_NC_attrarray(&ncp->attrs, &ref->attrs) != NC_NOERR ||
        ncmpio_dup_NC_vararray(&ncp->vars,   &ref->vars)  != NC_NOERR) {
        ncmpio_free_NC(ncp);
        return NULL;
    }

    /* fields below should not copied from ref */
    ncp->comm       = MPI_COMM_NULL;
    ncp->mpiinfo    = MPI_INFO_NULL;
    ncp->get_list   = NULL;
    ncp->put_list   = NULL;
    ncp->abuf       = NULL;
    ncp->path       = NULL;

    return ncp;
}

/*----< ncmpio_cktype() >----------------------------------------------------*/
/*  Verify that this is a user nc_type */
int
ncmpio_cktype(int cdf_ver, nc_type type)
{
    /* the max data type supported by CDF-5 is NC_UINT64 */
    if (type <= 0 || type > NC_UINT64)
        DEBUG_RETURN_ERROR(NC_EBADTYPE)

    /* For CDF-1 and CDF-2 files, only classic types are allowed. */
    if (cdf_ver < 5 && type > NC_DOUBLE)
        DEBUG_RETURN_ERROR(NC_ESTRICTCDF2)

    return NC_NOERR;
}

/*----< ncmpio_NC_check_vlens() >--------------------------------------------*/
/* Given a valid ncp, check all variables for their sizes against the maximal
 * allowable sizes. Different CDF formation versions have different maximal
 * sizes. This function returns NC_EVARSIZE if any variable has a bad len
 * (product of non-rec dim sizes too large), else return NC_NOERR.
 */
int
ncmpio_NC_check_vlens(NC *ncp)
{
    NC_var **vpp;
    /* maximum permitted variable size (or size of one record's worth
       of a record variable) in bytes.  This is different for format 1
       and format 2. */
    MPI_Offset ii, vlen_max, rec_vars_count;
    MPI_Offset large_fix_vars_count, large_rec_vars_count;
    int last = 0;

    if (ncp->vars.ndefined == 0) /* no variable defined */
        return NC_NOERR;

    if (ncp->format >= 5) /* CDF-5 has no such limitation */
        return NC_NOERR;

    /* only CDF-1 and CDF-2 need to continue */

    if (ncp->format == 2) /* CDF2 format */
        vlen_max = X_UINT_MAX - 3; /* "- 3" handles rounded-up size */
    else
        vlen_max = X_INT_MAX - 3; /* CDF1 format */

    /* Loop through vars, first pass is for non-record variables */
    large_fix_vars_count = 0;
    rec_vars_count = 0;
    vpp = ncp->vars.value;
    for (ii = 0; ii < ncp->vars.ndefined; ii++, vpp++) {
        if (!IS_RECVAR(*vpp)) {
            last = 0;
            if (ncmpio_NC_check_vlen(*vpp, vlen_max) == 0) {
                /* check this variable's shape product against vlen_max */
                large_fix_vars_count++;
                last = 1;
            }
        } else {
            rec_vars_count++;
        }
    }
    /* OK if last non-record variable size too large, since not used to
       compute an offset */
    if (large_fix_vars_count > 1)  /* only one "too-large" variable allowed */
        DEBUG_RETURN_ERROR(NC_EVARSIZE)

    /* The only "too-large" variable must be the last one defined */
    if (large_fix_vars_count == 1 && last == 0)
        DEBUG_RETURN_ERROR(NC_EVARSIZE)

    if (rec_vars_count == 0) return NC_NOERR;

    /* if there is a "too-large" fixed-size variable, no record variable is
     * allowed */
    if (large_fix_vars_count == 1)
        DEBUG_RETURN_ERROR(NC_EVARSIZE)

    /* Loop through vars, second pass is for record variables.   */
    large_rec_vars_count = 0;
    vpp = ncp->vars.value;
    for (ii = 0; ii < ncp->vars.ndefined; ii++, vpp++) {
        if (IS_RECVAR(*vpp)) {
            last = 0;
            if (ncmpio_NC_check_vlen(*vpp, vlen_max) == 0) {
                /* check this variable's shape product against vlen_max */
                large_rec_vars_count++;
                last = 1;
            }
        }
    }

    /* For CDF-2, no record variable can require more than 2^32 - 4 bytes of
     * storage for each record's worth of data, unless it is the last record
     * variable. See
     * http://www.unidata.ucar.edu/software/netcdf/docs/file_structure_and_performance.html#offset_format_limitations
     */
    if (large_rec_vars_count > 1)  /* only one "too-large" variable allowed */
        DEBUG_RETURN_ERROR(NC_EVARSIZE)

    /* and it has to be the last one */
    if (large_rec_vars_count == 1 && last == 0)
        DEBUG_RETURN_ERROR(NC_EVARSIZE)

    return NC_NOERR;
}

/*----< ncmpio_read_NC() >---------------------------------------------------*/
/* Re-read in the header.
 * On PnetCDF, this is of no use, as header metadata is always sync-ed among
 * all processes, except for numrecs, which can be sync-ed by calling
 * ncmpio_sync_numrecs()
 */
int
ncmpio_read_NC(NC *ncp) {
  int status = NC_NOERR;

  ncmpio_free_NC_dimarray(&ncp->dims);
  ncmpio_free_NC_attrarray(&ncp->attrs);
  ncmpio_free_NC_vararray(&ncp->vars);

  status = ncmpio_hdr_get_NC(ncp);

  if (status == NC_NOERR)
      fClr(ncp->flags, NC_NDIRTY);

  return status;
}

#ifdef _CHECK_HEADER_IN_DETAIL
/*----< NC_check_header() >--------------------------------------------------*/
/*
 * Check the consistency of defined header metadata across all processes and
 * overwrite the local header objects with root's if inconsistency is found.
 * This function is collective.
 */
static int
NC_check_header(NC         *ncp,
                void       *buf,
                MPI_Offset  local_xsz) /* size of buf */
{
    int h_size, rank, g_status, status=NC_NOERR, mpireturn;

    /* root's header size has been broadcasted in NC_begin() and saved in
     * ncp->xsz.
     */

    /* TODO: When root process 0 broadcasts its header,
     * currently the header size cannot be larger than 2^31 bytes,
     * due to the 2nd argument, count, of MPI_Bcast being of type int.
     * Possible solution is to broadcast in chunks of 2^31 bytes.
     */
    h_size = (int)ncp->xsz;
    if (ncp->xsz != h_size)
        DEBUG_RETURN_ERROR(NC_EINTOVERFLOW)

    MPI_Comm_rank(ncp->nciop->comm, &rank);

    if (rank == 0) {
        TRACE_COMM(MPI_Bcast)(buf, h_size, MPI_BYTE, 0, ncp->nciop->comm);
    }
    else {
        bufferinfo gbp;
        void *cmpbuf = (void*) NCI_Malloc((size_t)h_size);

        TRACE_COMM(MPI_Bcast)(cmpbuf, h_size, MPI_BYTE, 0, ncp->nciop->comm);

        if (h_size != local_xsz || memcmp(buf, cmpbuf, h_size)) {
            /* now part of this process's header is not consistent with root's
             * check and report the inconsistent part
             */

            /* Note that gbp.nciop and gbp.offset below will not be used in
             * ncmpio_hdr_check_NC() */
            gbp.nciop  = ncp->nciop;
            gbp.offset = 0;
            gbp.size   = h_size;   /* entire header is in the buffer, cmpbuf */
            gbp.index  = 0;
            gbp.pos    = gbp.base = cmpbuf;

            /* find the inconsistent part of the header, report the difference,
             * and overwrite the local header object with root's.
             * ncmpio_hdr_check_NC() should not have any MPI communication
             * calls.
             */
            status = ncmpio_hdr_check_NC(&gbp, ncp);

            /* header consistency is only checked on non-root processes. The
             * returned status can be a fatal error or header inconsistency
             * error, (fatal errors are due to object allocation), but never
             * NC_NOERR.
             */
        }
        NCI_Free(cmpbuf);
    }

    if (ncp->safe_mode) {
        TRACE_COMM(MPI_Allreduce)(&status, &g_status, 1, MPI_INT, MPI_MIN,
                                  ncp->nciop->comm);
        if (mpireturn != MPI_SUCCESS) {
            return ncmpio_handle_error(mpireturn, "MPI_Allreduce"); 
        }
        if (g_status != NC_NOERR) { /* some headers are inconsistent */
            if (status == NC_NOERR) DEBUG_ASSIGN_ERROR(status, NC_EMULTIDEFINE)
        }
    }

    return status;
}
#endif

