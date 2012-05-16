//
// auto-generated by op2.m on 15-May-2012 22:50:07
//

// user function

#include "dirichlet.h"


// x86 kernel function

void op_x86_dirichlet(
  int    blockIdx,
  double *ind_arg0,
  int   *ind_map,
  short *arg_map,
  int   *ind_arg_sizes,
  int   *ind_arg_offs,
  int    block_offset,
  int   *blkmap,
  int   *offset,
  int   *nelems,
  int   *ncolors,
  int   *colors,
  int   set_size) {


  int   *ind_arg0_map, ind_arg0_size;
  double *ind_arg0_s;
  int    nelem, offset_b;

  char shared[128000];

  if (0==0) {

    // get sizes and shift pointers and direct-mapped data

    int blockId = blkmap[blockIdx + block_offset];
    nelem    = nelems[blockId];
    offset_b = offset[blockId];

    ind_arg0_size = ind_arg_sizes[0+blockId*1];

    ind_arg0_map = &ind_map[0*set_size] + ind_arg_offs[0+blockId*1];

    // set shared memory pointers

    int nbytes = 0;
    ind_arg0_s = (double *) &shared[nbytes];
  }

  // copy indirect datasets into shared memory or zero increment


  // process set elements

  for (int n=0; n<nelem; n++) {
    // user-supplied kernel call


    dirichlet(  ind_arg0_s+arg_map[0*set_size+n+offset_b]*1 );
  }

  // apply pointered write/increment

  for (int n=0; n<ind_arg0_size; n++)
    for (int d=0; d<1; d++)
      ind_arg0[d+ind_arg0_map[n]*1] = ind_arg0_s[d+n*1];

}


// host stub function

void op_par_loop_dirichlet(char const *name, op_set set,
  op_arg arg0 ){


  int    nargs   = 1;
  op_arg args[1] = {arg0};

  int    ninds   = 1;
  int    inds[1] = {0};

  if (OP_diags>2) {
    printf(" kernel routine with indirection: dirichlet\n");
  }

  // get plan

  #ifdef OP_PART_SIZE_1
    int part_size = OP_PART_SIZE_1;
  #else
    int part_size = OP_part_size;
  #endif

  int set_size = op_mpi_halo_exchanges(set, nargs, args);

  // initialise timers

  double cpu_t1, cpu_t2, wall_t1, wall_t2;
  op_timers_core(&cpu_t1, &wall_t1);

  if (set->size >0) {


    op_plan *Plan = op_plan_get(name,set,part_size,nargs,args,ninds,inds);
    // execute plan

    int block_offset = 0;

    for (int col=0; col < Plan->ncolors; col++) {
      if (col==Plan->ncolors_core) op_mpi_wait_all(nargs, args);

      int nblocks = Plan->ncolblk[col];

#pragma omp parallel for
      for (int blockIdx=0; blockIdx<nblocks; blockIdx++)
      op_x86_dirichlet( blockIdx,
         (double *)arg0.data,
         Plan->ind_map,
         Plan->loc_map,
         Plan->ind_sizes,
         Plan->ind_offs,
         block_offset,
         Plan->blkmap,
         Plan->offset,
         Plan->nelems,
         Plan->nthrcol,
         Plan->thrcol,
         set_size);

      block_offset += nblocks;
    }

  op_timing_realloc(1);
  OP_kernels[1].transfer  += Plan->transfer;
  OP_kernels[1].transfer2 += Plan->transfer2;

  }


  // combine reduction data

  op_mpi_set_dirtybit(nargs, args);

  // update kernel record

  op_timers_core(&cpu_t2, &wall_t2);
  op_timing_realloc(1);
  OP_kernels[1].name      = name;
  OP_kernels[1].count    += 1;
  OP_kernels[1].time     += wall_t2 - wall_t1;
}

