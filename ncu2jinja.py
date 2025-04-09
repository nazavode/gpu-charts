#!/usr/bin/env python3

import sys
import re
import argparse
import pandas as pd
from typing import TypeAlias
from jinja2 import Environment, FileSystemLoader

Metrics: TypeAlias = dict[str, float]

#
# Derived metrics
#


def elapsed_s(d: Metrics) -> float:
    return d["sm__cycles_elapsed.avg"] / d["sm__cycles_elapsed.avg.per_second"]


def scalar_flop(d: Metrics) -> float:
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


def tensor_flop(d: Metrics) -> float:
    return 512 * d["sm__inst_executed_pipe_tensor.sum"]


def flop(d: Metrics) -> float:
    return scalar_flop(d) + tensor_flop(d)


def thread_instructions(d: Metrics) -> float:
    return d["smsp__thread_inst_executed.sum"] / 32.0


def l1_global_transactions(d: Metrics) -> float:
    return (
        d["l1tex__t_sectors_pipe_lsu_mem_global_op_ld.sum"]
        + d["l1tex__t_sectors_pipe_lsu_mem_global_op_st.sum"]
    )


def l1_shared_transactions(d: Metrics) -> float:
    return (
        d["l1tex__data_pipe_lsu_wavefronts_mem_shared_op_ld.sum"]
        + d["l1tex__data_pipe_lsu_wavefronts_mem_shared_op_st.sum"]
    )


def l2_transactions(d: Metrics) -> float:
    return (
        d["lts__t_sectors_op_read.sum"]
        + d["lts__t_sectors_op_atom.sum"] * 2
        + d["lts__t_sectors_op_red.sum"] * 2
        + d["lts__t_sectors_op_write.sum"]
    )


def dram_transactions(d: Metrics) -> float:
    return d["dram__sectors_read.sum"] + d["dram__sectors_write.sum"]


def warp_instructions(d: Metrics) -> float:
    return d["smsp__inst_executed.sum"]


def l1_total_32B_transactions(d: Metrics) -> float:
    return l1_global_transactions(d) + 4 * l1_shared_transactions(d)


def warp_global_ld_st_instructions(d: Metrics) -> float:
    return d["smsp__inst_executed_op_global_ld.sum"]


def warp_shared_ld_st_instructions(d: Metrics) -> float:
    return (
        d["smsp__inst_executed_op_shared_ld.sum"]
        + d["smsp__inst_executed_op_shared_st.sum"]
    )


def dram_bytes(d: Metrics) -> float:
    return d["dram__bytes.sum"]


def l2_bytes(d: Metrics) -> float:
    return d["lts__t_bytes.sum"]


def l1_bytes(d: Metrics) -> float:
    return d["l1tex__t_bytes.sum"]


def fp_instructions(d: Metrics) -> float:
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


def int_instructions(d: Metrics) -> float:
    return d["sm__sass_thread_inst_executed_op_integer_pred_on.sum"]


def cf_instructions(d: Metrics) -> float:
    return d["sm__sass_thread_inst_executed_op_control_pred_on.sum"]


def threadcomm_instructions(d: Metrics) -> float:
    return d["sm__sass_thread_inst_executed_op_inter_thread_communication_pred_on.sum"]


def mem_instructions(d: Metrics) -> float:
    return d["sm__sass_thread_inst_executed_op_memory_pred_on.sum"]


def misc_instructions(d: Metrics) -> float:
    return (
        d["sm__sass_thread_inst_executed_op_bit_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_conversion_pred_on.sum"]
        + d["sm__sass_thread_inst_executed_op_misc_pred_on.sum"]
    )


def tot_instructions(d: Metrics) -> float:
    return (
        fp_instructions(d)
        + int_instructions(d)
        + cf_instructions(d)
        + threadcomm_instructions(d)
        + mem_instructions(d)
        + misc_instructions(d)
    )


#
# Charts
#


def instmix(df: pd.DataFrame) -> Metrics:
    res = pd.DataFrame(
        {
            "fp_instructions": fp_instructions(df),
            "int_instructions": int_instructions(df),
            "mem_instructions": mem_instructions(df),
            "cf_instructions": cf_instructions(df),
            "threadcomm_instructions": threadcomm_instructions(df),
            "misc_instructions": misc_instructions(df),
            "tot_instructions": tot_instructions(df),
        }
    )
    columns = [
        "fp_instructions",
        "int_instructions",
        "mem_instructions",
        "cf_instructions",
        "threadcomm_instructions",
        "misc_instructions",
    ]
    row_sums = res[columns].sum(axis=1)
    for col in columns:
        res[f"{col}_pct"] = (res[col] / row_sums * 100).round(10)
    return res.to_dict()


def occupancy(d: Metrics) -> Metrics:
    peak = d["sm__maximum_warps_per_active_cycle_pct"]
    sustained = d["sm__warps_active.avg.pct_of_peak_sustained_active"]
    return {
        "peak_occupancy_margin_pct": peak - sustained,
        "sustained_occupancy_pct": sustained,
    }


def efficiency(d: Metrics) -> Metrics:
    return {"efficiency": thread_instructions(d) / warp_instructions(d) * 100}


def performance(d: Metrics) -> Metrics:
    return {"flops": flop(d) / (elapsed_s(d) * 10**9)}


def roofline(d: Metrics) -> Metrics:
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
        "warp_shared_instruction_performance": warp_shared_ld_st_instructions(d)
        / (elapsed_s(d) * 10**9),
        "shared_warp_inst_intensity": warp_shared_ld_st_instructions(d)
        / l1_shared_transactions(d),
    }


def get_metrics(df: pd.DataFrame) -> pd.DataFrame:
    return pd.DataFrame(
        {
            "name": df["Symbol Name"],
            # Timing
            "elapsed_s": elapsed_s(df),
            # Bandwidth
            "dram_bytes": dram_bytes(df),
            "l2_bytes": l2_bytes(df),
            "l1_bytes": l1_bytes(df),
            # FLOP
            "flop": flop(df),
            "scalar_flop": scalar_flop(df),
            "tensor_flop": tensor_flop(df),
            # 1. Instruction Intensity and Performance
            "thread_instructions": thread_instructions(df),
            "l1_global_transactions": l1_global_transactions(df),
            "l1_shared_transactions": l1_shared_transactions(df),
            "l2_transactions": l2_transactions(df),
            "dram_transactions": dram_transactions(df),
            # 2. Thread Predication
            "warp_instructions": warp_instructions(df),
            # 3. Global Memory Pattern Walls
            "l1_total_32B_transactions": l1_total_32B_transactions(df),
            "warp_global_ld_st_instructions": warp_global_ld_st_instructions(df),
            # 4. Shared Memory Walls
            "warp_shared_ld_st_instructions": warp_shared_ld_st_instructions(df),
            "warp_shared_transactions": l1_shared_transactions(df),
            # Instruction mix
            **instmix(df),
            # Occupancy
            **occupancy(df),
            # Efficiency
            **efficiency(df),
            # Performance
            **performance(df),
            # Instruction roofline plots
            **roofline(df),
        }
    )


def normalize_identifier(symbol: str) -> str:
    identifier = symbol.replace("::", "_")
    identifier = re.sub(r"\W+", "_", identifier)
    if re.match(r"^\d", identifier):
        identifier = "_" + identifier
    return identifier


def normalize_ncu(df: pd.DataFrame) -> pd.DataFrame:
    symbol_names = df["Kernel Name"].apply(
        lambda x: (
            re.search(r"([\w:]+)(?:<.*?>)?\s*\(", x).group(1)
            if isinstance(x, str) and re.search(r"([\w:]+)(?:<.*?>)?\s*\(", x)
            else None
        )
    )
    metric_values = pd.to_numeric(
        df["Metric Value"].str.replace(",", "", regex=False), errors="coerce"
    )
    metrics = pd.DataFrame(
        {
            "Symbol Name": symbol_names,
            "Metric Name": df["Metric Name"],
            "Metric Value": metric_values,
        }
    )
    metrics = (
        metrics.groupby(["Symbol Name", "Metric Name"])["Metric Value"]
        .mean()
        .reset_index()
    )
    metrics = metrics.pivot(
        index="Symbol Name", columns="Metric Name", values="Metric Value"
    ).reset_index()
    return metrics


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Instantiate Jinja template files from an NVIDIA Nsight profiler (ncu) CSV output. Reads the ncu data from stdin and writes the result to stdout."
    )
    parser.add_argument(
        "--template",
        "-t",
        default=None,
        help="Jinja2 template file to be instantiated with result metrics; if not specified, emits the contents from the resulting Jinja environment",
    )
    parser.add_argument(
        "--kernel",
        action="append",
        help="List of kernels to be taken into account; if not specified, all kernels are emitted.",
    )

    args = parser.parse_args()

    df = pd.read_csv(sys.stdin)
    df = normalize_ncu(df)
    df = get_metrics(df)

    df["identifier"] = df["name"].apply(normalize_identifier)

    if args.kernel:
        kernels = [s.strip() for s in args.kernel if s.strip()]
        df = df[df["name"].apply(lambda x: any(sub in x for sub in kernels))]

    if args.template:
        env = Environment(
            loader=FileSystemLoader("."), lstrip_blocks=True, trim_blocks=True
        )
        template = env.get_template(args.template)
        print(template.render(kernels=df.to_dict(orient="records")))
    else:
        df.to_csv(sys.stdout, index=False)
