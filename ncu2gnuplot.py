#!/usr/bin/env python3

import csv
import sys
import argparse
import statistics
import math
import json
from collections import defaultdict
from jinja2 import Environment, FileSystemLoader


def elapsed_s(d):
    return d["sm__cycles_elapsed.avg"] / float(d["sm__cycles_elapsed.avg.per_second"])


def scalar_flop(d):
    return (
        2 * d["sm__sass_thread_inst_executed_op_dfma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_dmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_dadd_pred_on.sum"]
        + 2 * d["sm__sass_thread_inst_executed_op_ffma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_fmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_fadd_pred_on.sum"]
        + 2 * d["sm__sass_thread_inst_executed_op_hfma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_hmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_hadd_pred_on.sum"]
    )


def tensor_flop(d):
    return 512 * d["sm__inst_executed_pipe_tensor.sum"]


def flop(d):
    return scalar_flop(d) + tensor_flop(d)


def thread_instructions(d):
    return d["smsp__thread_inst_executed.sum"] / 32.0


def l1_global_transactions(d):
    return (
        d["l1tex__t_sectors_pipe_lsu_mem_global_op_ld.sum"]
        + d["l1tex__t_sectors_pipe_lsu_mem_global_op_st.sum"]
    )


def l1_shared_transactions(d):
    return (
        d["l1tex__data_pipe_lsu_wavefronts_mem_shared_op_ld.sum"]
        + d["l1tex__data_pipe_lsu_wavefronts_mem_shared_op_st.sum"]
    )


def l2_transactions(d):
    return (
        d["lts__t_sectors_op_read.sum"]
        + d["lts__t_sectors_op_atom.sum"] * 2
        + d["lts__t_sectors_op_red.sum"] * 2
        + d["lts__t_sectors_op_write.sum"]
    )


def dram_transactions(d):
    return d["dram__sectors_read.sum"] + d["dram__sectors_write.sum"]


def warp_instructions(d):
    return d["smsp__inst_executed.sum"]


def l1_total_32B_transactions(d):
    return l1_global_transactions(d) + 4 * l1_shared_transactions(d)


def warp_global_ld_st_instructions(d):
    return d["smsp__inst_executed_op_global_ld.sum"]


def warp_shared_ld_st_instructions(d):
    return (
        d["smsp__inst_executed_op_shared_ld.sum"]
        + d["smsp__inst_executed_op_shared_st.sum"]
    )


def dram_bytes(d):
    return d["dram__bytes.sum"]


def l2_bytes(d):
    return d["lts__t_bytes.sum"]


def l1_bytes(d):
    return d["l1tex__t_bytes.sum"]


def fp_instructions(d):
    return (
        d["sm__sass_thread_inst_executed_op_dfma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_dmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_dadd_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_ffma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_fmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_fadd_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_hfma_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_hmul_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_hadd_pred_on.sum"]
        + d["sm__inst_executed_pipe_tensor.sum"]
    )


def int_instructions(d):
    return d["sm__sass_thread_inst_executed_op_integer_pred_on.sum"]


def cf_instructions(d):
    return d["sm__sass_thread_inst_executed_op_control_pred_on.sum"]


def threadcomm_instructions(d):
    return d["sm__sass_thread_inst_executed_op_inter_thread_communication_pred_on.sum"]


def mem_instructions(d):
    return d["sm__sass_thread_inst_executed_op_memory_pred_on.sum"]


def misc_instructions(d):
    return (
        d["sm__sass_thread_inst_executed_op_bit_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_conversion_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_misc_pred_on.sum"]
    )


def tot_instructions(d):
    return (
        fp_instructions(d)
        + int_instructions(d)
        + cf_instructions(d)
        + threadcomm_instructions(d)
        + mem_instructions(d)
        + misc_instructions(d)
    )


def instmix_pct(d):
    tot = tot_instructions(d)
    keys = [
        "fp_instructions_pct",
        "int_instructions_pct",
        "mem_instructions_pct",
        "cf_instructions_pct",
        "threadcomm_instructions_pct",
        "misc_instructions_pct",
    ]
    values = [
        fp_instructions(d) / tot * 100,
        int_instructions(d) / tot * 100,
        mem_instructions(d) / tot * 100,
        cf_instructions(d) / tot * 100,
        threadcomm_instructions(d) / tot * 100,
        misc_instructions(d) / tot * 100,
    ]
    # Apply largest remainder method to compensate for rounding errors
    components = [math.modf(v) for v in values]
    integral = [v[1] for v in components]
    fractional = list(sorted(enumerate(v[0] for v in components), key=lambda x: x[1]))
    while sum(integral) < 100:
        idx, _ = fractional.pop()
        integral[idx] += 1
    return {keys[i]: integral[i] for i in range(len(keys))}


def instmix(d):
    return {
        "fp_instructions": fp_instructions(d),
        "int_instructions": int_instructions(d),
        "mem_instructions": mem_instructions(d),
        "cf_instructions": cf_instructions(d),
        "threadcomm_instructions": threadcomm_instructions(d),
        "misc_instructions": misc_instructions(d),
        "tot_instructions": tot_instructions(d),
    }


def occupancy(d):
    peak = d["sm__maximum_warps_per_active_cycle_pct"]
    sustained = d["sm__warps_active.avg.pct_of_peak_sustained_active"]
    return {
        "peak_occupancy_margin_pct": peak - sustained,
        "sustained_occupancy_pct": sustained,
    }


def efficiency(d):
    return {"efficiency": thread_instructions(d) / warp_instructions(d) * 100}


def performance(d):
    return {"flops": flop(d) / (elapsed_s(d) * 1000000000)}


def roofline(d):
    return {
        "warp_instruction_performance": warp_instructions(d) / (elapsed_s(d) * 10**9),
        "thread_instruction_performance": thread_instructions(d)
        / (elapsed_s(d) * 10**9),
        "l1_thread_inst_intensity": thread_instructions(d)
        / l1_total_32B_transactions(d),
        "l2_thread_inst_intensity": thread_instructions(d) / l2_transactions(d),
        "hbm_thread_inst_intensity": thread_instructions(d) / dram_transactions(d),
        "thread_fp_performance": flop(d) / (elapsed_s(d) * 10**9),
        "l1_thread_fp_intensity": flop(d) / l1_bytes(d),
        "l2_thread_fp_intensity": flop(d) / l2_bytes(d),
        "hbm_thread_fp_intensity": flop(d) / dram_bytes(d),
        # "warp_shared_instruction_performance": warp_shared_ld_st_instructions(d)
        # / (elapsed_s(d) * 10**9),
        # "shared_warp_inst_intensity": warp_shared_ld_st_instructions(d)
        # / l1_shared_transactions(d),
    }


def canonicalize(d):
    return {
        # Timing
        "elapsed_s": elapsed_s(d),
        # Bandwidth
        "dram_bytes": dram_bytes(d),
        "l2_bytes": l2_bytes(d),
        "l1_bytes": l1_bytes(d),
        # FLOP
        "flop": flop(d),
        "scalar_flop": scalar_flop(d),
        "tensor_flop": tensor_flop(d),
        # 1. Instruction Intensity and Performance
        "thread_instructions": thread_instructions(d),
        "l1_global_transactions": l1_global_transactions(d),
        "l1_shared_transactions": l1_shared_transactions(d),
        "l2_transactions": l2_transactions(d),
        "dram_transactions": dram_transactions(d),
        # 2. Thread Predication
        "warp_instructions": warp_instructions(d),
        # 3. Global Memory Pattern Walls
        "l1_total_32B_transactions": l1_total_32B_transactions(d),
        "warp_global_ld_st_instructions": warp_global_ld_st_instructions(d),
        # 4. Shared Memory Walls
        "warp_shared_ld_st_instructions": warp_shared_ld_st_instructions(d),
        "warp_shared_transactions": l1_shared_transactions(d),
        # Instruction mix
        **instmix(d),
        **instmix_pct(d),
        # Occupancy
        **occupancy(d),
        # Efficiency
        **efficiency(d),
        # Performance
        **performance(d),
        # Instruction roofline plots
        **roofline(d),
    }


def mean(data):
    try:
        return statistics.geometric_mean(data)
    except statistics.StatisticsError:
        # With empty series or series with just zeros
        return 0.0


def accumulate(d):
    return {k: mean(v) for k, v in d.items()}


def group_by(r, kernels=None):
    data = defaultdict(list)
    for row in r:
        groups = [k for k in kernels if k in row["Kernel Name"]]
        assert len(groups) <= 1
        if not groups:
            continue
        group = groups[0]
        data[group].append(row)
    return data


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate gnuplot data file from an NVIDIA Nsight profiler CSV file. Reads the CSV from stdin and writes the result to stdout."
    )
    parser.add_argument(
        "--template",
        "-t",
        default=None,
        help="Template file containing a python format string to be instantiated with resulting values",
    )
    parser.add_argument(
        "--kernel",
        action="append",
        help="List of kernels to be taken into account; if not specified, average values across all kernels are emitted",
    )

    args = parser.parse_args()

    r = csv.DictReader(sys.stdin, delimiter=",", quotechar='"')

    kernels = None
    if args.kernel:
        kernels = [s.strip() for s in args.kernel if s.strip()]

    if kernels:
        data = group_by(r, kernels=kernels)
    else:
        data = {"all": r}

    metrics = {}
    for kernel, rows in data.items():
        d = defaultdict(list)
        for row in rows:
            k = row["Metric Name"]
            v = float(row["Metric Value"].replace(",", ""))
            d[k].append(v)
        metrics[kernel] = d

    result = {
        kernel: {"name": kernel, **canonicalize(accumulate(data))}
        for kernel, data in metrics.items()
    }

    if args.template:
        env = Environment(
            loader=FileSystemLoader("."), lstrip_blocks=True, trim_blocks=True
        )
        template = env.get_template(args.template)
        print(template.render(kernels=result.values()))
    else:
        json.dump(result, sys.stdout, indent=4)
