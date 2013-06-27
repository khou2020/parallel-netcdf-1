/* -*- Mode: C; c-basic-offset:4 ; -*- */
/*  
 *  (C) 2003 by Argonne National Laboratory and Northwestern University.
 *      See COPYRIGHT in top-level directory.
 *
 * This file is automatically generated by ./buildiface -infile=../lib/pnetcdf.h -deffile=defs
 * DO NOT EDIT
 */
#include "mpinetcdf_impl.h"


#ifdef F77_NAME_UPPER
#define nfmpi_begin_indep_data_ NFMPI_BEGIN_INDEP_DATA
#elif defined(F77_NAME_LOWER_2USCORE)
#define nfmpi_begin_indep_data_ nfmpi_begin_indep_data__
#elif !defined(F77_NAME_LOWER_USCORE)
#define nfmpi_begin_indep_data_ nfmpi_begin_indep_data
/* Else leave name alone */
#endif


/* Prototypes for the Fortran interfaces */
#include "mpifnetcdf.h"
FORTRAN_API int FORT_CALL nfmpi_begin_indep_data_ ( int *v1 ){
    int ierr;
    ierr = ncmpi_begin_indep_data( *v1 );
    return ierr;
}
