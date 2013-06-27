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
#define nfmpi_rename_dim_ NFMPI_RENAME_DIM
#elif defined(F77_NAME_LOWER_2USCORE)
#define nfmpi_rename_dim_ nfmpi_rename_dim__
#elif !defined(F77_NAME_LOWER_USCORE)
#define nfmpi_rename_dim_ nfmpi_rename_dim
/* Else leave name alone */
#endif


/* Prototypes for the Fortran interfaces */
#include "mpifnetcdf.h"
FORTRAN_API int FORT_CALL nfmpi_rename_dim_ ( int *v1, int *v2, char *v3 FORT_MIXED_LEN(d3) FORT_END_LEN(d3) ){
    int ierr;
    int l2 = *v2 - 1;
    char *p3;

    {char *p = v3 + d3 - 1;
     int  li;
        while (*p == ' ' && p > v3) p--;
        p++;
        p3 = (char *)malloc( p-v3 + 1 );
        for (li=0; li<(p-v3); li++) { p3[li] = v3[li]; }
        p3[li] = 0; 
    }
    ierr = ncmpi_rename_dim( *v1, l2, p3 );
    free( p3 );
    return ierr;
}
