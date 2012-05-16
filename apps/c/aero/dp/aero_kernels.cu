//
// auto-generated by op2.m on 15-May-2012 22:48:16
//

// header

#include "op_lib_cpp.h"

#include "op_cuda_rt_support.h"
#include "op_cuda_reduction.h"
// global constants

#ifndef MAX_CONST_SIZE
#define MAX_CONST_SIZE 128
#endif

__constant__ double gam;
__constant__ double gm1;
__constant__ double gm1i;
__constant__ double m2;
__constant__ double wtg1[2];
__constant__ double xi1[2];
__constant__ double Ng1[4];
__constant__ double Ng1_xi[4];
__constant__ double wtg2[4];
__constant__ double Ng2[16];
__constant__ double Ng2_xi[32];
__constant__ double minf;
__constant__ double freq;
__constant__ double kappa;
__constant__ double nmode;
__constant__ double mfan;
__constant__ int stride;

void op_decl_const_char(int dim, char const *type,
            int size, char *dat, char const *name){
  cutilSafeCall(cudaMemcpyToSymbol(name, dat, dim*size));
}

// user kernel files

#include "res_calc_kernel.cu"
#include "dirichlet_kernel.cu"
#include "init_cg_kernel.cu"
#include "spMV_kernel.cu"
#include "dotPV_kernel.cu"
#include "updateUR_kernel.cu"
#include "dotR_kernel.cu"
#include "updateP_kernel.cu"
#include "update_kernel.cu"
