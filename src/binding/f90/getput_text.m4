dnl Process this m4 file to produce 'C' language file.
dnl
dnl If you see this line, you can ignore the next one.
! Do not edit this file. It is produced from the corresponding .m4 source
dnl
!
!  Copyright (C) 2013, Northwestern University and Argonne National Laboratory
!  See COPYRIGHT notice in top-level directory.
!
! $Id$
!

dnl
dnl TEXTVAR1(ncid, varid, values, start, count, stride, map)
dnl
define(`TEXTVAR1',dnl
`dnl
   function nf90mpi_$1_var_text$3(ncid, varid, values, start, count, stride, map)
     integer,                                                intent(in) :: ncid, varid
     character (len=*),                                      intent($2) :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: map

     integer                                     :: nf90mpi_$1_var_text$3
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer                                     :: numDims, nelms

     ! allocate local arrays
     nf90mpi_$1_var_text$3 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_text$3 .NE. NF_NOERR) return

     nelms = numDims + 1
     if (present(start)  .AND. nelms .LT. SIZE(start))  nelms = SIZE(start)
     if (present(count)  .AND. nelms .LT. SIZE(count))  nelms = SIZE(count)
     if (present(stride) .AND. nelms .LT. SIZE(stride)) nelms = SIZE(stride)
     allocate(localStart(nelms))
     allocate(localCount(nelms))
     allocate(localStride(nelms))

     ! Set local arguments to default values
     localStart (:) = 1
     localCount (1) = LEN(values)
     localCount (2:) = 1
     localStride(:) = 1

     if (present(start))  localStart (:size(start) ) = start(:)
     if (present(count))  localCount (:size(count) ) = count(:)
     if (present(stride)) localStride(:size(stride)) = stride(:)
     if (present(map)) then
       nf90mpi_$1_var_text$3 = nfmpi_$1_varm_text$3(ncid, varid, localStart, localCount, localStride, map, values)
     else
       nf90mpi_$1_var_text$3 = nfmpi_$1_vars_text$3(ncid, varid, localStart, localCount, localStride, values)
     end if
     deallocate(localStart)
     deallocate(localCount)
     deallocate(localStride)
   end function nf90mpi_$1_var_text$3
')dnl

!
! Independent put APIs
!

TEXTVAR1(put, in)
TEXTVAR1(get, out)

!
! Collective put APIs
!

TEXTVAR1(put, in,  _all)
TEXTVAR1(get, out, _all)


dnl
dnl TEXTVAR(ncid, varid, values, start, count, stride, map)
dnl
define(`TEXTVAR',dnl
`dnl
   function nf90mpi_$1_var_$2D_text$6(ncid, varid, values, start, count, stride, map)
     integer,                                                intent(in) :: ncid, varid
     character (len=*), dimension($3),                       intent($5) :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent(in) :: map

     integer                                     :: nf90mpi_$1_var_$2D_text$6
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localMap(:)
     integer                                     :: numDims, nelms
     ifelse(`$2', `1', ,`integer :: counter')

     ! allocate local arrays
     nf90mpi_$1_var_$2D_text$6 = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$2D_text$6 .NE. NF_NOERR) return

     nelms = numDims + 1
     if (present(start)  .AND. nelms .LT. SIZE(start))  nelms = SIZE(start)
     if (present(count)  .AND. nelms .LT. SIZE(count))  nelms = SIZE(count)
     if (present(stride) .AND. nelms .LT. SIZE(stride)) nelms = SIZE(stride)
     if (present(map)    .AND. nelms .LT. SIZE(map))    nelms = SIZE(map)
     allocate(localStart(nelms))
     allocate(localCount(nelms))
     allocate(localStride(nelms))
     allocate(localMap(nelms))

     ! Set local arguments to default values
     localStart (:) = 1
     localCount (:$2+1) = (/ LEN(values($4)), shape(values) /)
     localCount ($2+2:) = 0
     localStride(:) = 1
     ! localMap(:$2) = (/ 1, (product(localCount(:counter)), counter = 1, $2 - 1) /)
     localMap(1) = 1
     ifelse(`$2', `1', ,`
     do counter = 1, $2 - 1
        localMap(counter+1) = localMap(counter) * localCount(counter)
     enddo')

     if (present(start))  localStart (:SIZE(start) ) =  start(:)
     if (present(count))  localCount (:SIZE(count) ) =  count(:)
     if (present(stride)) localStride(:SIZE(stride)) = stride(:)
     if (present(map)) then
       localMap(:SIZE(map)) = map(:)
       nf90mpi_$1_var_$2D_text$6 = &
          nfmpi_$1_varm_text$6(ncid, varid, localStart, localCount, localStride, localMap, values($4))
     else
       nf90mpi_$1_var_$2D_text$6 = &
          nfmpi_$1_vars_text$6(ncid, varid, localStart, localCount, localStride, values($4))
     end if
     deallocate(localStart)
     deallocate(localCount)
     deallocate(localStride)
     deallocate(localMap)
   end function nf90mpi_$1_var_$2D_text$6
')dnl

TEXTVAR(put, 1,  :,               1,              in)
TEXTVAR(put, 2, `:,:',           `1,1',           in)
TEXTVAR(put, 3, `:,:,:',         `1,1,1',         in)
TEXTVAR(put, 4, `:,:,:,:',       `1,1,1,1',       in)
TEXTVAR(put, 5, `:,:,:,:,:',     `1,1,1,1,1',     in)
TEXTVAR(put, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   in)
TEXTVAR(put, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', in)

TEXTVAR(get, 1,  :,               1,              out)
TEXTVAR(get, 2, `:,:',           `1,1',           out)
TEXTVAR(get, 3, `:,:,:',         `1,1,1',         out)
TEXTVAR(get, 4, `:,:,:,:',       `1,1,1,1',       out)
TEXTVAR(get, 5, `:,:,:,:,:',     `1,1,1,1,1',     out)
TEXTVAR(get, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   out)
TEXTVAR(get, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', out)

!
! Collective APIs
!

TEXTVAR(put, 1,  :,               1,              in, _all)
TEXTVAR(put, 2, `:,:',           `1,1',           in, _all)
TEXTVAR(put, 3, `:,:,:',         `1,1,1',         in, _all)
TEXTVAR(put, 4, `:,:,:,:',       `1,1,1,1',       in, _all)
TEXTVAR(put, 5, `:,:,:,:,:',     `1,1,1,1,1',     in, _all)
TEXTVAR(put, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   in, _all)
TEXTVAR(put, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', in, _all)

TEXTVAR(get, 1,  :,               1,              out, _all)
TEXTVAR(get, 2, `:,:',           `1,1',           out, _all)
TEXTVAR(get, 3, `:,:,:',         `1,1,1',         out, _all)
TEXTVAR(get, 4, `:,:,:,:',       `1,1,1,1',       out, _all)
TEXTVAR(get, 5, `:,:,:,:,:',     `1,1,1,1,1',     out, _all)
TEXTVAR(get, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   out, _all)
TEXTVAR(get, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', out, _all)

!
! Nonblocking APIs
!

dnl
dnl NBTEXTVAR1(ncid, varid, values, req, start, count, stride, map)
dnl
define(`NBTEXTVAR1',dnl
`dnl
   function nf90mpi_$1_var_text(ncid, varid, values, req, start, count, stride, map)
     integer,                                                intent( in) :: ncid, varid
     integer,                                                intent(out) :: req
     character (len=*),                                      intent( $2) :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: map

     integer                                     :: nf90mpi_$1_var_text
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer                                     :: numDims, nelms

     ! allocate local arrays
     nf90mpi_$1_var_text = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_text .NE. NF_NOERR) return

     nelms = numDims + 1
     if (present(start)  .AND. nelms .LT. SIZE(start))  nelms = SIZE(start)
     if (present(count)  .AND. nelms .LT. SIZE(count))  nelms = SIZE(count)
     if (present(stride) .AND. nelms .LT. SIZE(stride)) nelms = SIZE(stride)
     allocate(localStart(nelms))
     allocate(localCount(nelms))
     allocate(localStride(nelms))

     ! Set local arguments to default values
     localStart (:) = 1
     localCount (1) = LEN(values)
     localCount (2:) = 1
     localStride(:) = 1

     if (present(start))  localStart (:size(start) ) = start(:)
     if (present(count))  localCount (:size(count) ) = count(:)
     if (present(stride)) localStride(:size(stride)) = stride(:)
     if (present(map)) then
       nf90mpi_$1_var_text = nfmpi_$1_varm_text(ncid, varid, localStart, localCount, localStride, map, values, req)
     else
       nf90mpi_$1_var_text = nfmpi_$1_vars_text(ncid, varid, localStart, localCount, localStride, values, req)
     end if
     deallocate(localStart)
     deallocate(localCount)
     deallocate(localStride)
   end function nf90mpi_$1_var_text
')dnl

!
! iput APIs
!

NBTEXTVAR1(iput, in)
NBTEXTVAR1(iget, out)

!
! bput APIs
!

NBTEXTVAR1(bput, in)


dnl
dnl NBTEXTVAR(ncid, varid, values, req, start, count, stride, map)
dnl
define(`NBTEXTVAR',dnl
`dnl
   function nf90mpi_$1_var_$2D_text(ncid, varid, values, req, start, count, stride, map)
     integer,                                                intent( in) :: ncid, varid
     integer,                                                intent(out) :: req
     character (len=*), dimension($3),                       intent( $5) :: values
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: start
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: count
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: stride
     integer (kind=MPI_OFFSET_KIND), dimension(:), optional, intent( in) :: map

     integer                                     :: nf90mpi_$1_var_$2D_text
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStart(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localCount(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localStride(:)
     integer (kind=MPI_OFFSET_KIND), allocatable :: localMap(:)
     integer                                     :: numDims, nelms
     ifelse(`$2', `1', ,`integer :: counter')

     ! allocate local arrays
     nf90mpi_$1_var_$2D_text = nfmpi_inq_varndims(ncid, varid, numDims)
     if (nf90mpi_$1_var_$2D_text .NE. NF_NOERR) return

     nelms = numDims + 1
     if (present(start)  .AND. nelms .LT. SIZE(start))  nelms = SIZE(start)
     if (present(count)  .AND. nelms .LT. SIZE(count))  nelms = SIZE(count)
     if (present(stride) .AND. nelms .LT. SIZE(stride)) nelms = SIZE(stride)
     if (present(map)    .AND. nelms .LT. SIZE(map))    nelms = SIZE(map)
     allocate(localStart(nelms))
     allocate(localCount(nelms))
     allocate(localStride(nelms))
     allocate(localMap(nelms))

     ! Set local arguments to default values
     localStart (:) = 1
     localCount (:$2+1) = (/ LEN(values($4)), shape(values) /)
     localCount ($2+2:) = 0
     localStride(:) = 1
     ! localMap(:$2) = (/ 1, (product(localCount(:counter)), counter = 1, $2 - 1) /)
     localMap(1) = 1
     ifelse(`$2', `1', ,`
     do counter = 1, $2 - 1
        localMap(counter+1) = localMap(counter) * localCount(counter)
     enddo')

     if (present(start))  localStart (:SIZE(start) ) =  start(:)
     if (present(count))  localCount (:SIZE(count) ) =  count(:)
     if (present(stride)) localStride(:SIZE(stride)) = stride(:)
     if (present(map)) then
       localMap(:SIZE(map)) = map(:)
       nf90mpi_$1_var_$2D_text = &
          nfmpi_$1_varm_text(ncid, varid, localStart, localCount, localStride, localMap, values($4), req)
     else
       nf90mpi_$1_var_$2D_text = &
          nfmpi_$1_vars_text(ncid, varid, localStart, localCount, localStride, values($4), req)
     end if
     deallocate(localStart)
     deallocate(localCount)
     deallocate(localStride)
     deallocate(localMap)
   end function nf90mpi_$1_var_$2D_text
')dnl

NBTEXTVAR(iput, 1,  :,               1,              in)
NBTEXTVAR(iput, 2, `:,:',           `1,1',           in)
NBTEXTVAR(iput, 3, `:,:,:',         `1,1,1',         in)
NBTEXTVAR(iput, 4, `:,:,:,:',       `1,1,1,1',       in)
NBTEXTVAR(iput, 5, `:,:,:,:,:',     `1,1,1,1,1',     in)
NBTEXTVAR(iput, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   in)
NBTEXTVAR(iput, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', in)

NBTEXTVAR(iget, 1,  :,               1,              out)
NBTEXTVAR(iget, 2, `:,:',           `1,1',           out)
NBTEXTVAR(iget, 3, `:,:,:',         `1,1,1',         out)
NBTEXTVAR(iget, 4, `:,:,:,:',       `1,1,1,1',       out)
NBTEXTVAR(iget, 5, `:,:,:,:,:',     `1,1,1,1,1',     out)
NBTEXTVAR(iget, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   out)
NBTEXTVAR(iget, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', out)

!
! bput APIs
!

NBTEXTVAR(bput, 1,  :,               1,              in)
NBTEXTVAR(bput, 2, `:,:',           `1,1',           in)
NBTEXTVAR(bput, 3, `:,:,:',         `1,1,1',         in)
NBTEXTVAR(bput, 4, `:,:,:,:',       `1,1,1,1',       in)
NBTEXTVAR(bput, 5, `:,:,:,:,:',     `1,1,1,1,1',     in)
NBTEXTVAR(bput, 6, `:,:,:,:,:,:',   `1,1,1,1,1,1',   in)
NBTEXTVAR(bput, 7, `:,:,:,:,:,:,:', `1,1,1,1,1,1,1', in)
