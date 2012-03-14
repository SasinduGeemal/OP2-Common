//
// auto-generated by op2.m on 14-Mar-2012 14:11:38
//

// user function

__device__
#include "update.h"


// CUDA kernel function

__global__ void op_cuda_update(
  double *arg0,
  double *arg1,
  double *arg2,
  double *arg3,
  double *arg4,
  int   offset_s,
  int   set_size ) {

  double arg0_l[4];
  double arg1_l[4];
  double arg2_l[4];
  double arg4_l[1];
  for (int d=0; d<1; d++) arg4_l[d]=ZERO_double;
  int   tid = threadIdx.x%OP_WARPSIZE;

  extern __shared__ char shared[];

  char *arg_s = shared + offset_s*(threadIdx.x/OP_WARPSIZE);

  // process set elements

  for (int n=threadIdx.x+blockIdx.x*blockDim.x;
       n<set_size; n+=blockDim.x*gridDim.x) {

    int offset = n - tid;
    int nelems = MIN(OP_WARPSIZE,set_size-offset);

    // copy data into shared memory, then into local

    for (int m=0; m<4; m++)
      ((double *)arg_s)[tid+m*nelems] = arg0[tid+m*nelems+offset*4];

    for (int m=0; m<4; m++)
      arg0_l[m] = ((double *)arg_s)[m+tid*4];

    for (int m=0; m<4; m++)
      ((double *)arg_s)[tid+m*nelems] = arg2[tid+m*nelems+offset*4];

    for (int m=0; m<4; m++)
      arg2_l[m] = ((double *)arg_s)[m+tid*4];


    // user-supplied kernel call

    update( arg0_l,
            arg1_l,
            arg2_l,
            arg3+n,
            arg4_l );

    // copy back into shared memory, then to device

    for (int m=0; m<4; m++)
      ((double *)arg_s)[m+tid*4] = arg1_l[m];

    for (int m=0; m<4; m++)
      arg1[tid+m*nelems+offset*4] = ((double *)arg_s)[tid+m*nelems];

    for (int m=0; m<4; m++)
      ((double *)arg_s)[m+tid*4] = arg2_l[m];

    for (int m=0; m<4; m++)
      arg2[tid+m*nelems+offset*4] = ((double *)arg_s)[tid+m*nelems];

  }

  // global reductions

  for(int d=0; d<1; d++)
    op_reduction<OP_INC>(&arg4[d+blockIdx.x*1],arg4_l[d]);
}


// host stub function

void op_par_loop_update(char const *name, op_set set,
  op_arg arg0,
  op_arg arg1,
  op_arg arg2,
  op_arg arg3,
  op_arg arg4 ){

  double *arg4h = (double *)arg4.data;

  int    nargs   = 5;
  op_arg args[5] = {arg0,arg1,arg2,arg3,arg4};

  if (OP_diags>2) {
    printf(" kernel routine w/o indirection:  update \n");
  }

  op_mpi_halo_exchanges(set, nargs, args);

  // initialise timers

  double cpu_t1, cpu_t2, wall_t1, wall_t2;
  op_timers(&cpu_t1, &wall_t1);

  if (set->size >0) {


    // set CUDA execution parameters

    #ifdef OP_BLOCK_SIZE_4
      int nthread = OP_BLOCK_SIZE_4;
    #else
      // int nthread = OP_block_size;
      int nthread = 128;
    #endif

    int nblocks = 200;

    // transfer global reduction data to GPU

    int maxblocks = nblocks;

    int reduct_bytes = 0;
    int reduct_size  = 0;
    reduct_bytes += ROUND_UP(maxblocks*1*sizeof(double));
    reduct_size   = MAX(reduct_size,sizeof(double));

    reallocReductArrays(reduct_bytes);

    reduct_bytes = 0;
    arg4.data   = OP_reduct_h + reduct_bytes;
    arg4.data_d = OP_reduct_d + reduct_bytes;
    for (int b=0; b<maxblocks; b++)
      for (int d=0; d<1; d++)
        ((double *)arg4.data)[d+b*1] = ZERO_double;
    reduct_bytes += ROUND_UP(maxblocks*1*sizeof(double));

    mvReductArraysToDevice(reduct_bytes);

    // work out shared memory requirements per element

    int nshared = 0;
    nshared = MAX(nshared,sizeof(double)*4);
    nshared = MAX(nshared,sizeof(double)*4);
    nshared = MAX(nshared,sizeof(double)*4);

    // execute plan

    int offset_s = nshared*OP_WARPSIZE;

    nshared = MAX(nshared*nthread,reduct_size*nthread);

    op_cuda_update<<<nblocks,nthread,nshared>>>( (double *) arg0.data_d,
                                                 (double *) arg1.data_d,
                                                 (double *) arg2.data_d,
                                                 (double *) arg3.data_d,
                                                 (double *) arg4.data_d,
                                                 offset_s,
                                                 set->size );

    cutilSafeCall(cudaThreadSynchronize());
    cutilCheckMsg("op_cuda_update execution failed\n");

    // transfer global reduction data back to CPU

    mvReductArraysToHost(reduct_bytes);

    for (int b=0; b<maxblocks; b++)
      for (int d=0; d<1; d++)
        arg4h[d] = arg4h[d] + ((double *)arg4.data)[d+b*1];

  op_mpi_reduce(&arg4,arg4h);

  }


  // update kernel record

  op_mpi_barrier();
  op_timers(&cpu_t2, &wall_t2);
  op_timing_realloc(4);
  OP_kernels[4].name      = name;
  OP_kernels[4].count    += 1;
  OP_kernels[4].time     += wall_t2 - wall_t1;
  OP_kernels[4].transfer += (float)set->size * arg0.size;
  OP_kernels[4].transfer += (float)set->size * arg1.size;
  OP_kernels[4].transfer += (float)set->size * arg2.size * 2.0f;
  OP_kernels[4].transfer += (float)set->size * arg3.size;
}

