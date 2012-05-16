//
// auto-generated by op2.m on 15-May-2012 22:50:01
//

// user function

__device__
#include "dotPV.h"


// CUDA kernel function

__global__ void op_cuda_dotPV(
  double *arg0,
  double *arg1,
  double *arg2,
  int   offset_s,
  int   set_size ) {

  double arg2_l[1];
  for (int d=0; d<1; d++) arg2_l[d]=ZERO_double;

  // process set elements

  for (int n=threadIdx.x+blockIdx.x*blockDim.x;
       n<set_size; n+=blockDim.x*gridDim.x) {
    // user-supplied kernel call


    dotPV(  arg0+n,
            arg1+n,
            arg2_l );
  }

  // global reductions

  for(int d=0; d<1; d++)
    op_reduction<OP_INC>(&arg2[d+blockIdx.x*1],arg2_l[d]);
}


// host stub function

void op_par_loop_dotPV(char const *name, op_set set,
  op_arg arg0,
  op_arg arg1,
  op_arg arg2 ){

  double *arg2h = (double *)arg2.data;

  int    nargs   = 3;
  op_arg args[3] = {arg0,arg1,arg2};

  if (OP_diags>2) {
    printf(" kernel routine w/o indirection:  dotPV\n");
  }

  op_mpi_halo_exchanges(set, nargs, args);

  // initialise timers

  double cpu_t1, cpu_t2, wall_t1, wall_t2;
  op_timers_core(&cpu_t1, &wall_t1);

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
    arg2.data   = OP_reduct_h + reduct_bytes;
    arg2.data_d = OP_reduct_d + reduct_bytes;
    for (int b=0; b<maxblocks; b++)
      for (int d=0; d<1; d++)
        ((double *)arg2.data)[d+b*1] = ZERO_double;
    reduct_bytes += ROUND_UP(maxblocks*1*sizeof(double));

    mvReductArraysToDevice(reduct_bytes);

    // work out shared memory requirements per element

    int nshared = 0;

    // execute plan

    int offset_s = nshared*OP_WARPSIZE;

    nshared = MAX(nshared*nthread,reduct_size*nthread);

    op_cuda_dotPV<<<nblocks,nthread,nshared>>>( (double *) arg0.data_d,
                                                (double *) arg1.data_d,
                                                (double *) arg2.data_d,
                                                offset_s,
                                                set->size );

    cutilSafeCall(cudaThreadSynchronize());
    cutilCheckMsg("op_cuda_dotPV execution failed\n");

    // transfer global reduction data back to CPU

    mvReductArraysToHost(reduct_bytes);

    for (int b=0; b<maxblocks; b++)
      for (int d=0; d<1; d++)
        arg2h[d] = arg2h[d] + ((double *)arg2.data)[d+b*1];

  arg2.data = (char *)arg2h;

  op_mpi_reduce(&arg2,arg2h);

  }


  op_mpi_set_dirtybit(nargs, args);

  // update kernel record

  op_timers_core(&cpu_t2, &wall_t2);
  op_timing_realloc(4);
  OP_kernels[4].name      = name;
  OP_kernels[4].count    += 1;
  OP_kernels[4].time     += wall_t2 - wall_t1;
  OP_kernels[4].transfer += (float)set->size * arg0.size;
  OP_kernels[4].transfer += (float)set->size * arg1.size;
}

