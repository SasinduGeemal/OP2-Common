%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                       %
% This MATLAB routine generates the header file op_seq.h                %
%                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function op_seq_gen()

%
% this sets the max number of arguments in op_par_loop
%

maxargs = 10;

%
% first the top bit
%

file = strvcat(...
'//                                                                 ',...
'// header for sequential and MPI+sequentional execution            ',...
'//                                                                 ',...
'                                                                   ',...
'#include "op_lib_cpp.h"                                           ',...
'                                                                   ',...
'char blank_args[512]; // scratch space to use for blank args       ',...
'                                                                   ',...
'inline void op_arg_set(int n, op_arg arg, char **p_arg, int halo){ ',...
'  *p_arg = arg.data;                                               ',...
'                                                                   ',...
'  if (arg.argtype==OP_ARG_GBL) {                                   ',...
'    if (halo && (arg.acc != OP_READ)) *p_arg = blank_args;         ',...
'  }                                                                ',...
'  else {                                                           ',...
'    if (arg.map==NULL)         // identity mapping                 ',...
'      *p_arg += arg.size*n;                                        ',...
'    else                       // standard pointers                ',...
'      *p_arg += arg.size*arg.map->map[arg.idx+n*arg.map->dim];     ',...
'  }                                                                ',...
'}                                                                  ',...
'                                                                   ',...
'inline void op_arg_copy_in(int n, op_arg arg, char **p_arg) {',...
'  for (int i = 0; i < arg.map->dim; ++i)',...
'    p_arg[i] = arg.data + arg.map->map[i+n*arg.map->dim]*arg.size;',...
'}                                                                  ',...
'                                                                   ',...
'inline void op_args_check(op_set set, int nargs, op_arg *args,     ',...
'                                      int *ninds, const char *name) {    ',...
'  for (int n=0; n<nargs; n++)                                      ',...
'    op_arg_check(set,n,args[n],ninds,name);                         ',...
'}                                                                  ',...
'                                                                   ');

%
% now for op_par_loop defns
%

for nargs = 1:maxargs
  c_nargs = num2str(nargs);


  file = strvcat(file,' ', ...
    '// ',...
   ['// op_par_loop routine for ' c_nargs ' arguments '],...
    '// ',' ');

  n_per_line = 4;

  line = 'template < ';
  for n = 1:nargs
    line = [ line 'class T' num2str(n-1) ','];
    if (n==nargs)
      line = [line(1:end-1) ' >'];
    end
    if (mod(n,n_per_line)==0 || n==nargs)
      file = strvcat(file,line);
      line = '           ';
    elseif (n<=10)
      line = [line ' '];
    end
  end

  line = 'void op_par_loop(void (*kernel)( ';
  for n = 1:nargs
    line = [ line 'T' num2str(n-1) '*,'];
    if (n==nargs)
      line = [line(1:end-1) ' ),'];
    end
    if (mod(n,n_per_line)==0 || n==nargs)
      file = strvcat(file,line);
      line = '                                 ';
    elseif (n<=10)
      line = [line ' '];
    end
  end

  file = strvcat(file,'    char const * name, op_set set,');

  line = '    ';
  for n = 1:nargs
    line = [ line 'op_arg arg' num2str(n-1) ','];
    if (n==nargs)
      line = [line(1:end-1) ' ) {'];
    end
    if (mod(n,n_per_line)==0 || n==nargs)
      file = strvcat(file,line);
      line = '    ';
    elseif (n<=10)
      line = [line ' '];
    end
  end

  line = ['  char  *p_a[' c_nargs '] = {0'];
  for n = 1:nargs-1
    line = [line ',0'];
  end
  line = [line '};'];
  file = strvcat(file,' ', line);

  line = ['  op_arg args[' c_nargs '] = { '];

  for n = 1:nargs
    line = [ line 'arg' num2str(n-1) ',' ];
    if (n==nargs)
      line = [line(1:end-1) ' };'];
    end
    if (mod(n,n_per_line)==0 || n==nargs)
      file = strvcat(file,line);
      line = '                      ';
    elseif (n<=10)
      line = [line ' '];
    end
  end

  for n = 1:nargs
    file = strvcat(file,sprintf('  if(arg%d.idx == OP_ALL) {\n    p_a[%d] = (char *)malloc(args[%d].map->dim*sizeof(T%d));\n  }',n-1,n-1,n-1,n-1));
  end

%
% diagnostics and start of main loop
%

  file = strvcat(file,...
    '                                                                  ',...
    '  // consistency checks                                           ',...
    '                                                                  ',...
    '  int ninds = 0;                                                  ',...
    '                                                                  ',...
   ['  if (OP_diags>0) op_args_check(set,' c_nargs ',args,&ninds,name);'],...
    '                                                                  ',...
    '  if (OP_diags>2) {                                               ',...
    '    if (ninds==0)                                                 ',...
    '      printf(" kernel routine w/o indirection:  %s\n",name);     ',...
    '    else                                                          ',...
    '      printf(" kernel routine with indirection: %s\n",name);     ',...
    '  }                                                               ',...
    '                                                                  ',...
    '  // initialise timers',...
    '  double cpu_t1, cpu_t2, wall_t1, wall_t2;',...
    '  op_timers_core(&cpu_t1, &wall_t1); ',...
    '                                                                  ',...
    '  // MPI halo exchange and dirty bit setting, if needed           ',...
    '                                                                  ',...
   ['  int n_upper = op_mpi_halo_exchanges(set, ' c_nargs ',args);                         '],...
    '                                                                  ',...
    '  // loop over set elements                                       ',...
    '                                                                  ',...
    '  int halo = 0;                                               ',...
    '                                                                  ',...
    '  for (int n=0; n<n_upper; n++) {                                 ',...
   ['    if (n==set->core_size) op_mpi_wait_all(' c_nargs ',args);          '],...
    '    if (n==set->size) halo = 1;                               ',...
    '                                                                  ');

  for n = 1:nargs
    file = strvcat(file,['    if (args[',num2str(n-1),'].idx < -1) op_arg_copy_in(n,args[',num2str(n-1),'], (char **)p_a[',num2str(n-1),']);                     '],...
    ['    else op_arg_set(n,args[',num2str(n-1),'], &p_a[',num2str(n-1),'],halo);                     ']);
  end

  file = strvcat(file,...
    '                                                                  ',...
    '    // call kernel function, passing in pointers to data          ',...
    ' ');

%
% call to user's kernel
%

  line = ['    kernel( '];
  for n = 1:nargs
    line = [ line '(T' num2str(n-1) ' *)p_a['  num2str(n-1) '],'];
    if (n==nargs)
      line = [line(1:end-1) ' );'];
    end
    if (mod(n,n_per_line)==0 || n==nargs)
      file = strvcat(file,line);
      line = '            ';
    elseif (n<=10)
      line = [line '  '];
    end
  end

  file = strvcat(file,...
    '  }                                                  ',' ',...
    '  //set dirty bit on datasets touched                ',...
  sprintf('  op_mpi_set_dirtybit(%d, args);',nargs), ' ',...
    '  // global reduction for MPI execution, if needed   ',' ');

  for n = 1:nargs
    %file = strvcat(file,...
    %  [ '  if (arg' num2str(n-1) '.argtype==OP_ARG_GBL &&' ...
    %         ' arg' num2str(n-1) '.acc!=OP_READ) '         ]);
    file = strvcat(file,...
      [ '  op_mpi_reduce(&arg' num2str(n-1) ','       ...
                           '(T' num2str(n-1) ' *)'         ...
                         'p_a[' num2str(n-1) ']);'         ]);
  end

  file = strvcat(file,...
      '  // update timer record',...
      '  op_timers_core(&cpu_t2, &wall_t2); ',...
      '#ifdef COMM_PERF',...
      '  int k_i = op_mpi_perf_time(name, wall_t2 - wall_t1);',...
     ['  op_mpi_perf_comms(k_i, ' c_nargs ', args);'],...
      '#else',...
      '  op_mpi_perf_time(name, wall_t2 - wall_t1);',...
      '#endif');

  for n = 1:nargs
      file = strvcat(file,sprintf('  if(arg%d.idx == OP_ALL) {\n    free(p_a[%d]);\n  }',n-1,n-1));
  end

  file = strvcat(file,'}',' ');
end

%
% print out into file
%


fid = fopen('op_seq.h','wt');
fprintf(fid,'//\n//auto-generated by op_seq_gen.m on %s\n//\n\n',datestr(now));
for n=1:size(file,1)
  fprintf(fid,'%s\n',deblank(file(n,:)));
end
fclose(fid);

