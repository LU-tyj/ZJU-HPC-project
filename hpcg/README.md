## 编译
使用`build.sh`在登陆节点进行代码的编译。需要使用的spack软件包有：`openmpi@5.0.6, cuda@12.8, nvhpc@25.1`。
先下载指定的软件包，然后使用`./build.sh`即可以进行编译（已在build.sh进行了spack load），若出现。。。则编译成功

## 运行
将`run.sh`提交到V100上进行运行，`sbatch run.sh`