!=========================================================================
!Fermion t-J model on the triangle/square Lattice 
!H=-t*[\sum_{<ij>s}](C^+_{i,s}C_{j,s}+h.c.)+J[\sum_<ij>(S_i.S_j-n_i.n_j/4)
!=========================================================================
module pubdata
	implicit none

	!Num_site: number of sites of the system
	!up_bias: bias of quantum number for up spin
	!down_bias: bias of quantum number for down spin
	integer,parameter :: Nx=24,Ny=4,nc=1,nly=1, nleg=nc*ny,Num_site=Nleg*Nx
	integer,parameter :: Num_site0=Nleg*(Nx+2), su=2, num_site1=num_site+num_site/2
	integer,parameter :: up_bias=1,down_bias=1, nxx=6*Ny, add_op=1
        integer infi_del, xi1, xj1, qn0(num_site,2),num_k  !!
	real(8),parameter :: PI=3.14159265358979d0
        integer restart1, restart2, sys_len_start
        integer tjmodel, hubmodel,v123, N_max, nrr, SS, kc

        !! for measurement
        logical density1,  measbl,  measli,  superc

	!Prameters of t-J model
        complex*16  cone,ci, czero !Jn is coef of -Jn*(n_i.n_j) term
	integer :: tot_num_up,tot_num_down, delta
        real*8 hubbard(num_site)
        integer, parameter :: open=1  !!! pbc open=0,   open=1, then obc
        integer, parameter :: square=0, triangle=1, kagome=0, honeycomb=0
                                        !! doing one of lattices, choose it to
                                        !be one, set others to zero
        integer, parameter :: neibt1=6 !!   neib  min
        integer, parameter :: neibt=18 !!   neib to max  
        integer neib(0:num_site,neibt),neiba(0:num_site,0:num_site)
        double complex jd(neibt,0:num_site),jz(neibt,0:num_site),jt(neibt,0:num_site),jt1, jz1,jd1,jn1
        double complex :: jz00(neibt), jd00(neibt), jt00(neibt), jn(neibt,num_site)
        double precision:: esite(0:num_site), phasex !!! on site energy
         integer inb(-4:num_site),nleg11(num_site),inb1(0:num_site,0:num_site)
         integer nleg1s(num_site), inb1s(0:num_site,0:num_site), openy

        integer nposib(0:num_site), nposi(0:num_site), nposi1(0:num_site)
        integer nposi_dm(0:num_site),  nposi_lat(0:num_site)
        integer coup_bb(2),coup_bs(2,2),coup_ss  !!!
        integer bond_ss,  mshift, nxc
!!! for chiral interaction
        integer num_spin2(4*num_site,num_site,8), num_spin3(4*num_site,8)
        integer tri3(num_site,num_site,4*2*2),tri3b(num_site*2,num_site,8), ms
        integer tri3s(num_site,num_site,8), tri0(num_site*2,4)
        complex*16 tri3ph(num_site, num_site,8)
        integer ind2e(num_site*num_site*4, num_site,2)
        integer        nleg2(num_site,2),nleg3(num_site),nleg21, lring
        integer spin2q(num_site) 
        double complex  jring(num_site)
        integer  kk1,kk11


! parameter for SU2 symmetry
        integer iw6j1(0:num_site1, 0:num_site1, 0:2, 0:2, 0:2, 0:num_site1)
        real*8 w6j1(0:num_site1, 0:num_site1, 0:2, 0:2, 0:2, 0:num_site1)
        integer iw9j1(0:num_site1,  -2:2, 0:num_site1, -2:2, 0:num_site1, -2:2)
        real*8 w9j1(0:num_site1,  -2:2, 0:num_site1, -2:2, 0:num_site1, -2:2)
        integer iw6j2(0:num_site1, 0:2, -2:2, 0:2, 0:num_site1, 0:2)
        real*8 w6j2(0:num_site1, 0:2, -2:2, 0:2, 0:num_site1, 0:2)
        integer iw6j3(0:num_site1, 0:2, -2:2, 0:num_site1, 0:2, 0:num_site1)
        real*8   w6j3(0:num_site1, 0:2, -2:2, 0:num_site1, 0:2, 0:num_site1)

	!===================================================================
	!General parameter used in the program
	!kept: number of states kept in the program
	!lanzero: truncation error set in lanzero method
	logical :: System_block,Spectrum, realcode
	integer :: kept_min,kept_max,kept_maxf, sweep_num,hopt_num,Jcoup_num
	real(8) :: Lanzero,Entropys,Entropy0,Energys(8),Energy0

	!Name of files for saving data to disk
	integer :: Lattice(2,Num_site),Latticever(Nx,Ny)
	integer :: sys_lat(3,Num_site),env_lat(3,Num_site)
	character(len=20) :: sysname(Num_site,4),envname(Num_site,4)
	character(len=20) :: sysmsn(Num_site),envmsn(Num_site)
	character(len=20) :: sysmsd(Num_site),envmsd(Num_site)
	character(len=20) :: wave_name(8)
	

	!===================================================
	!For sub-basis for original block and new site
	type Sub_Basis_Map
		integer :: spos,sdim
		integer :: bl_num_up,bl_num_down
		integer :: st_num_up,st_num_down
	end type Sub_Basis_Map

	!Sub-basis between block/site and new enlarged block
	type Basis_Map
		integer :: idx,num,dim
		integer :: new_num_up,new_num_down
		type(Sub_Basis_Map),allocatable :: sub(:)
	end type Basis_Map

	!Total basis between
	type Total_Basis
		integer :: len,num,dim
		type(Basis_Map),allocatable :: sub(:)
	end type Total_Basis


	!===================================================
	!Configuration: [sys_bl--cen_st--env_bl]
	!For superblock configuration consist of sys and env
	type Sub_Super_Basis
		integer :: sys_num_up,sys_num_down
		integer :: env_num_up,env_num_down
		integer :: sys_dim,env_dim
	end type Sub_Super_Basis

	type Super_Basis
		integer :: sys_len,env_len,num,dim,idx
		type(Sub_Super_Basis),allocatable :: sub(:)
	end type Super_Basis

	!Wavefunction
	type Sub_Wave
		integer :: sys_num_up,sys_num_down
		integer :: env_num_up,env_num_down
		integer :: sys_dim,env_dim
		double complex,  allocatable :: vec(:,:)
	end type Sub_Wave

	type Wavefunction
		integer :: sys_len,env_len,num,dim
		type(Sub_Wave),allocatable :: sub(:)
	end type Wavefunction


	!============================================
	!Data structure of Block Operators
	type Sub_Block
		integer :: num_up,num_down,down_dif,row_dim,sdim
		double complex,allocatable :: mat(:,:)
	end type Sub_Block

	type Total_Block
		integer :: len,num,dim,up_dif,down_dif
		type(Sub_Block),allocatable :: sub(:)
	end type Total_Block


	!Data structure of reduced density matrix
	type Sub_Den
		integer :: num_up,num_down,row_dim,sdim
		integer,allocatable :: idx(:)
		double complex, allocatable ::eigvec(:,:)
		double precision, allocatable :: eigval(:)
	end type Sub_Den

	type Density
		integer :: len,num,dim,up_dif,down_dif
		type(Sub_Den),allocatable :: sub(:)
	end type Density


	!Block operators needed at one end
	type Block_Set
		type(Total_Block) :: elec_up,elec_down,spin_sd,spin_sz,num_sn, double
	end type Block_Set
	type Block_Set1
		type(Total_Block) :: spin_sd
	end type Block_Set1

	!Hamiltonian
	type Total_Model
		integer :: len
		type(Total_Block) :: ham   
		type(Block_Set) :: sub(nxx), snc(2), sdc(2)  !For middle operators
		type(Block_Set) :: sub_s(nxx)  !For middle operators
		type(Block_Set1) :: spin1(num_site*4) !For pbc operators
	end type Total_Model


	!=============================================================
	!General data of the program
	!=============================================================
	type(Total_Basis) :: st_basis
	type(Total_Block) :: st_elec_up,st_elec_down,st_double !C^+_{i,up}/C^+_{i,down}
	type(Total_Block) :: num_elec_up,num_elec_down,num_elec  !N_{i,up},N_{i,down},N_i
	type(Total_Block) :: st_sz_up,st_sz_down,st_sz,st_sd,st_si !S^z_{up},S^z_{down},S^z,S^+
	type(Total_Basis) :: sys_bsm(Num_site),env_bsm(Num_site)
	type(Total_Block) :: systruns(Num_site),envtruns(Num_site)
	type(Total_Block) :: sysopers(Num_site),envopers(Num_site)
	type(Wavefunction) :: Ground_state

end module pubdata

