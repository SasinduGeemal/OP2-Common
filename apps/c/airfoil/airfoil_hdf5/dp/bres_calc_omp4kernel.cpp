//
// auto-generated by op2.py
//

//user function
int opDat0_bres_calc_stride_OP2CONSTANT;
int opDat0_bres_calc_stride_OP2HOST=-1;
int opDat2_bres_calc_stride_OP2CONSTANT;
int opDat2_bres_calc_stride_OP2HOST=-1;
//user function

void bres_calc_omp4_kernel(
  int *map0,
  int *map2,
  int *data5,
  double *data0,
  double *data2,
  double *data3,
  double *data4,
  int *col_reord,
  int set_size1,
  int start,
  int end,
  int num_teams,
  int nthread,
  int opDat0_bres_calc_stride_OP2CONSTANT,
  int opDat2_bres_calc_stride_OP2CONSTANT);

// host stub function
void op_par_loop_bres_calc(char const *name, op_set set,
  op_arg arg0,
  op_arg arg1,
  op_arg arg2,
  op_arg arg3,
  op_arg arg4,
  op_arg arg5){

  int nargs = 6;
  op_arg args[6];

  args[0] = arg0;
  args[1] = arg1;
  args[2] = arg2;
  args[3] = arg3;
  args[4] = arg4;
  args[5] = arg5;

  // initialise timers
  double cpu_t1, cpu_t2, wall_t1, wall_t2;
  op_timing_realloc(3);
  op_timers_core(&cpu_t1, &wall_t1);
  OP_kernels[3].name      = name;
  OP_kernels[3].count    += 1;

  int  ninds   = 4;
  int  inds[6] = {0,0,1,2,3,-1};

  if (OP_diags>2) {
    printf(" kernel routine with indirection: bres_calc\n");
  }

  // get plan
  int set_size = op_mpi_halo_exchanges_cuda(set, nargs, args);

  #ifdef OP_PART_SIZE_3
    int part_size = OP_PART_SIZE_3;
  #else
    int part_size = OP_part_size;
  #endif
  #ifdef OP_BLOCK_SIZE_3
    int nthread = OP_BLOCK_SIZE_3;
  #else
    int nthread = OP_block_size;
  #endif


  int ncolors = 0;

  if (set->size >0) {

    if ((OP_kernels[3].count==1) || (opDat0_bres_calc_stride_OP2HOST != getSetSizeFromOpArg(&arg0))) {
      opDat0_bres_calc_stride_OP2HOST = getSetSizeFromOpArg(&arg0);
      opDat0_bres_calc_stride_OP2CONSTANT = opDat0_bres_calc_stride_OP2HOST;
    }
    if ((OP_kernels[3].count==1) || (opDat2_bres_calc_stride_OP2HOST != getSetSizeFromOpArg(&arg2))) {
      opDat2_bres_calc_stride_OP2HOST = getSetSizeFromOpArg(&arg2);
      opDat2_bres_calc_stride_OP2CONSTANT = opDat2_bres_calc_stride_OP2HOST;
    }

    //Set up typed device pointers for OpenMP
    int *map0 = arg0.map_data_d;
    int *map2 = arg2.map_data_d;

    int* data5 = (int*)arg5.data_d;
    double *data0 = (double *)arg0.data_d;
    double *data2 = (double *)arg2.data_d;
    double *data3 = (double *)arg3.data_d;
    double *data4 = (double *)arg4.data_d;

    op_plan *Plan = op_plan_get_stage(name,set,part_size,nargs,args,ninds,inds,OP_COLOR2);
    ncolors = Plan->ncolors;
    int *col_reord = Plan->col_reord;
    int set_size1 = set->size + set->exec_size;

    // execute plan
    for ( int col=0; col<Plan->ncolors; col++ ){
      if (col==1) {
        op_mpi_wait_all_cuda(nargs, args);
      }
      int start = Plan->col_offsets[0][col];
      int end = Plan->col_offsets[0][col+1];

      bres_calc_omp4_kernel(
        map0,
        map2,
        data5,
        data0,
        data2,
        data3,
        data4,
        col_reord,
        set_size1,
        start,
        end,
        part_size!=0?(end-start-1)/part_size+1:(end-start-1)/nthread,
        nthread,
        opDat0_bres_calc_stride_OP2CONSTANT,
        opDat2_bres_calc_stride_OP2CONSTANT);

    }
    OP_kernels[3].transfer  += Plan->transfer;
    OP_kernels[3].transfer2 += Plan->transfer2;
  }

  if (set_size == 0 || set_size == set->core_size || ncolors == 1) {
    op_mpi_wait_all_cuda(nargs, args);
  }
  // combine reduction data
  op_mpi_set_dirtybit_cuda(nargs, args);

  if (OP_diags>1) deviceSync();
  // update kernel record
  op_timers_core(&cpu_t2, &wall_t2);
  OP_kernels[3].time     += wall_t2 - wall_t1;
}
