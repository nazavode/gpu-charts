# gpu-charts

Utilities to generate fancy profiling plots for CUDA kernels by parsing output from [NVIDIA Nsight compute CLI](https://docs.nvidia.com/nsight-compute/NsightComputeCli/index.html).

> Note: architectural limits are currently specified for NVIDIA V100 GPUs. Automatic parametrization of plots is not currently supported. You can adapt plots for your favorite GPU by editing values labeled as `Device parameters` in `.jinja` files.

### 1. Collect performance metrics with `ncu`

```
$ ncu $(./ncu-args.sh) myapp.x > myapp.ncu
```

### 2. Generate charts

Make sure the `.ncu` output file is in the root of the repository:

```
$ ls -1 *.ncu
myapp.ncu
```

You can generate a chart for each type by using proper `make` targets:

```
$ make myapp.roofline-fp.pdf
$ make myapp.roofline-inst.pdf
$ make myapp.roofline-shared.pdf
```

The previous commands generate charts considering the geometric average of *all* kernels in the profiling data.
To select and plot specific kernels:

```
$ make ... KERNELS="KernelA KernelB"
```

## Available charts

All roofline charts are inspired by:

> N. Ding and S. Williams, “An Instruction Roofline Model for GPUs,” in 2019 IEEE/ACM Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems (PMBS), Denver, CO, USA: IEEE, Nov. 2019, pp. 7–18. doi: 10.1109/PMBS49563.2019.00007.

## 1. Instruction Roofline

![Instruction roofline](img/roofline-inst.png)

## 2. Floating Point Instruction Roofline

![Floating point instruction roofline](img/roofline-fp.png)

## 3. Shared Memory Roofline

![Shared memory roofline](img/roofline-shared.png)

## 4. Instruction Mix

*Work in progress.*
