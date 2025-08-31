# 实验报告hpcg 部分

钭亦骏3240100298

## 实验平台

V100 集群 共 32 个节点，每个节点有 2 个 GPU

- GPU：NVIDIA V100 32GB * 2
- Ethernet：10Gbps
- Infiniband：HDR 200Gbps



## 优化方法与思路

### 编译过程

刚开始使用了/usr/local/cuda的cuda以及自己在$HOME中安装的spack来搭建编译以及运行的环境，使用了intel-oneapi-openmpi，但由于版本不匹配等原因导致了`daErrorInvalidDevice: invalid device ordinal`以及mpi运行时访问到不合法的地址的问题，后来选择使用集群自带的spack以及其中的nvhpc@25.1, openmpi@5.0.6, cuda@12.8.0解决了该报错。尝试了自带的gcc@12.2.0以及cuda@12.9的nvcc，以及cuda@12.8的nvcc，最后使用前两者进行编译。

### hpcg.dat修改

对**hpcg.dat**这个输入文件进行了修改，尝试了$256*256*256$ 1810、$128*128*128$ 1810、$104 * 104 * 104$ 60等组合，最终选取了$256*256*256$​ 1810。

选择这个规模，运算规模增大，增大内存访问量，使 GPU 的 HBM 带宽更接近饱和；更多迭代避免了初始化、IO、MPI setup 等开销的干扰，保证了统计的 GFLOP/s 更稳定；在 MPI + GPU 的环境里，大规模问题划分后每个 rank 的子网格更均衡，减少了边界通信占比。如果过大的话则会造成内存溢出，缓存局部下降等问题。

### 进程配置修改

其次对进程数量进行了修改实验，尝试了5、4、2、1个进程数量，通过写sbatch脚本以及mpirun来进行控制，过程中遇到了使用`srun`结果两个节点分别运行了一遍的问题，使得虽然写了`#SBATCH --ntasks-per-node=2`但仍为1个进程，导致了`ranks != npx*npy*npz`的报错，后使用`mpirun -n`来指定固定的进程来解决了这个问题。最后选择了2个进程来进行优化。并且通过比较，选了`--npx 1 --npy 1 --npz 2`的进程网格维度。

进程数量过多的话会导致通信消耗过大，这样做增加了并行性，减少mpi通信过程造成的损失。使用112的进程网格维度与相临访问更连续，提高了性能。

### mpi参数修改

修改添加了mpi的参数，先通过`--oversubscribe`来进行核心的分配，也尝试了`--bind-to core --map-by socket:PE=2`，两者相差不多，因此选择了前者来进行。

​	最后使用了自带的hpcg.sh所可以使用的参数，最后选择了如下的编译选项：
```bash
mpirun -np 2 --oversubscribe \
    ./bin/hpcg.sh --exec-name ./bin/xhpcg --dat ./bin/sample-dat/hpcg.dat \
    --p2p 4 \
    --gss 1024 \
    --npx 1 --npy 1 --npz 2 \
    --gpu-affinity 0:1 \
    --b 1 \
    --of 1
```

- --p2p 4 采用nccl来实现点对点通信
- --gss 1024 指定每个 GPU 排行的切片大小为1024
- --b 1 跳过CPU标准执行



## 运行结果截图

![image-20250831112401068](/Users/touyijun/Library/Application Support/typora-user-images/image-20250831112401068.png)







