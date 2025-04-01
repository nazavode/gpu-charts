# gpu-charts

### 1. Collect performance metrics with `ncu`

```
$ ncu $(./ncu-args.sh) mytest.x > mytest.ncu
```

### 2. Generate charts

Make sure the `.ncu` results file is in the root of the repository:

```
$ ls -1 *.ncu
mytest.ncu
```

You can generate a chart for each type by using proper `make` targets:

```
$ make mytest.roofline-fp.pdf
$ make mytest.roofline-inst.pdf
$ make mytest.roofline-shared.pdf
```

The previous commands generate charts considering the geometric average of *all* kernels in the profiling data.
To select and plot specific kernels:

```
$ make ... KERNELS="kernel1 kernel2"
```

## Available charts

All roofline charts are inspired by:

> N. Ding and S. Williams, “An Instruction Roofline Model for GPUs,” in 2019 IEEE/ACM Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems (PMBS), Denver, CO, USA: IEEE, Nov. 2019, pp. 7–18. doi: 10.1109/PMBS49563.2019.00007.

## 1. Instruction Roofline

![Instruction roofline](img/roofline-inst.png)

## 2. Floating Point Instruction Roofline

![Floating point instruction roofline](img/roofline-fp.png)

## 3. Shared Memory Roofline

*Work in progress.*

## 4. Instruction Mix

*Work in progress.*
