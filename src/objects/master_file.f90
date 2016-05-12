module master_file
    use data_structures
    use time, only      : Time_type
    use string, only    : str
    
    implicit none
    private

    ! Init takes as input a string with tokens in the form of {Y} {M} etc to be replaced with a year and month
    ! Accepted tokens and their replacement meaning are: 
    ! 
    ! {Y} = YEAR
    ! {M} = MONTH
    ! {D} = DAY
    ! {h} = HOUR
    ! {m} = MINUTE
    ! {s} = SECOND
    ! 
    
    ! define the parameters that are used to tell what type each substitution object is
    integer, parameter :: YEAR   = 1
    integer, parameter :: MONTH  = 2
    integer, parameter :: DAY    = 3
    integer, parameter :: HOUR   = 4
    integer, parameter :: MINUTE = 5
    integer, parameter :: SECOND = 6
    integer, parameter :: CHAR   = 7
    
    type :: substitution
        integer :: object_type
        character(len=MAXFILELENGTH) :: name
    end type substitution
    
    type, public :: master_file_type
        private
        character(len=MAXFILELENGTH) :: name
        integer :: nparts
        type(substitution), dimension(:), allocatable :: master_string
    contains
        procedure, public   :: init      => init
        procedure, public   :: get_file  => get_file
        procedure, public   :: as_string => as_string
    end type master_file_type
    
contains
    
    subroutine init(this, name)
        implicit none
        class(master_file_type), intent(inout)  :: this
        character(len=MAXVARLENGTH), intent(in) :: name
        
        integer :: i, n, j, last
        
        this%name = name
        
        if (name(1:1)=="{") then
            n=0
        else
            n=1
        endif
        
        ! first pass, find how many segments there are. 
        do i=1,len(name)
            if (name(i:i)=="{") then
                n=n+1
            elseif ( (name(i:i)=="}") .and. (i/=len(name)) ) then
                n=n+1
            endif
        end do
        
        allocate(this%master_string(n))
        this%nparts = n
        
        i = 1
        last = 1
        do while ( i <= n )
            
            ! first find the next token location
            if (last==1) last=0
            j = index(name(last+1:),"{")
            if (j/=0) j=j+last ! preserve j==0 so we can handle this case below
            if (last==0) last=1
            
            if (j==0) then
                ! handle the case in which there are no more "{" in the name
                this%master_string(i)%object_type = CHAR
                this%master_string(i)%name = name(last:)
                i = i+1
            else if (j==1) then
                ! handle the edge case of a token at the beginning of the file
                this%master_string(i)%object_type = read_token(name,j+1)
                last = j+3
                i = i+1
            else
                ! handle the generic case of a token somewhere other than the start
                this%master_string(i)%object_type = CHAR
                this%master_string(i)%name = name(last:j-1)
                this%master_string(i+1)%object_type = read_token(name,j+1)
                last = j+3
                i = i+2
            endif
        end do
    end subroutine init
    
    function read_token(name, index) result(object_type)
        implicit none
        character(len=*), intent(in) :: name
        integer, intent(in) :: index
        integer :: object_type
        
        select case (name(index:index))
            case ("Y")
                object_type = YEAR
            case ("M")
                object_type = MONTH
            case ("D")
                object_type = DAY
            case ("h")
                object_type = HOUR
            case ("m")
                object_type = MINUTE
            case ("s")
                object_type = SECOND
            ! case default
            !     stop "ERROR: unknown token : " // name(index:index) // " in string : " // trim(name)
        end select
        
    end function read_token

    function as_string(this) result(name)
        implicit none
        class(master_file_type), intent(inout)  :: this
        character(len=MAXFILELENGTH) :: name
        
        print*, "in object"
        print*, this%name
        name = this%name
        
    end function as_string


    function get_file(this, time) result(file)
        implicit none
        class(master_file_type), intent(inout)  :: this
        type(Time_type), intent(in) :: time
        character(len=MAXFILELENGTH) :: file
        
        integer :: i, last
        
        last = 1
        print*, last
        print*, time%as_string()
        do i = 1, this%nparts
            print*, i
            call FLUSH()
            print*,this%master_string(i)%object_type
            select case (this%master_string(i)%object_type)
                case (YEAR)
                    file(last:last+4) = str(time%year,  length=4, pad="0")
                    last=last+4
                case (MONTH)
                    file(last:last+2) = str(time%month, length=2, pad="0")
                    last=last+2
                case (DAY)
                    file(last:last+2) = str(time%day,   length=2, pad="0")
                    last=last+2
                case (HOUR)
                    file(last:last+2) = str(time%hour,  length=2, pad="0")
                    last=last+2
                case (MINUTE)
                    file(last:last+2) = str(time%minute, length=2, pad="0")
                    last=last+2
                case (SECOND)
                    file(last:last+2) = str(time%second, length=2, pad="0")
                    last=last+2
                case (CHAR)
                    file(last:last+len_trim(this%master_string(i)%name)) = trim(this%master_string(i)%name)
                    last=last+len_trim(this%master_string(i)%name)
                    print*, i, last, trim(this%master_string(i)%name)

                ! case default
                    ! stop "ERROR: Unknown object type: "//trim(str(this%master_string(i)%object_type))
            end select
        end do
        
    end function get_file
end module master_file
