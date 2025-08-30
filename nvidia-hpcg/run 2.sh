#!/bin/bash
#SBATCH --job-name=HPCG__      # 作业名
#SBATCH --nodes=1                  # 节点数
#SBATCH --ntasks-per-node=2        # 每个节点任务数
#SBATCH --gres=gpu:2               # 每个节点 GPU 数量
#SBATCH --cpus-per-task=4          # 每个 rank 使用的 CPU 核心
#SBATCH --time=01:00:00            # 最长运行时间
#SBATCH -p V100
#SBATCH --output=job_%j.out        # 标准输出
#SBATCH --error=job_%j.err         # 错误输出

# ========== 加载环境 ==========
source /pxe/opt/spack/share/spack/setup-env.sh
spack load nvhpc@25.1
spack load openmpi@5.0.6        # 用 Spack 的 OpenMPI
spack load cuda@12.8.0

# ======== 设置环境变量 ========
if [[ -z "${MPI_PATH}" ]]; then
    export MPI_PATH=$(spack location -i openmpi@5.0.6)
fi

if [[ -z "${MATHLIBS_PATH}" ]]; then
    export MATHLIBS_PATH=$(spack location -i cuda@12.8)/lib64
fi

if [[ -z "${NCCL_PATH}" ]]; then
    export NCCL_PATH=$(spack location -i nvhpc@25.1)/Linux_x86_64/2025/comm_libs/nccl
fi

if [[ -z "${CUDA_PATH}" ]]; then
    export CUDA_PATH=$(spack location -i cuda@12.8)
fi


export PATH=$MPI_PATH/bin:$CUDA_PATH/bin:$PATH
export LD_LIBRARY_PATH=$MPI_PATH/lib:$CUDA_PATH/lib64:$NCCL_PATH/lib:$MATHLIBS_PATH:$LD_LIBRARY_PATH
export CPATH=$CUDA_PATH/include:$NCCL_PATH/include:$CPATH

# ========== 运行程序 ==========
srun --oversubscribe ./bin/hpcg.sh --exec-name ./bin/xhpcg --dat ./bin/hpcg.dat
