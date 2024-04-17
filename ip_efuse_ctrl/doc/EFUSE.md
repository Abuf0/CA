## EFUSE 概述 
可编程电子保险丝，非易失存储器；SOC中用于存储信息和保护芯片。
#### EFUSE的作用和应用场景
- 芯片保护
  - 电路系统层面：防止大电压电流损伤芯片，类似保险丝熔断机制切断电流；
  - 芯片层面：记录产品信息、Secure Boot(即存放一段可执行程序，芯片初始化时执行，加载key并验证)
- 电源管理
  - 电路系统层面：限制电流和电压
- 电路校准
  - 产测同时在回片后，测试一些电路校准参数，比如时钟频率、电流偏置等，将这些信息写入EFUSE，掉点后也不会损失。当芯片正式投入应用时会直接读出这些参数使用。
  - 生产好die后，产测会测试芯片，将芯片信息写入EFUSE（比如工作电压、关键时钟频率、版本号、生产日期、产品信息等）；芯片在初次上电时，会读取EFUSE中一些信息，比如电压，从而
调节电压……
- 等
#### EFUSE工作原理
基于电子注入和热效应，类似RRAM，通过一定的读写电压，改变内部存储介质的形态，从而达到存0/1的效果；有些一次性，有些可编程；
本质就是非易失存储器

#### 常规EFUSE的工作模式和流程

#### SMIC 0.18um EFUSE Macro IP
- 256 bit = 32x8 bit
- PGM模式一次烧录1bit；READ模式一次读出8bit；
- EFUSE引脚
  - AVDD：模拟电源电压 <PGM：>5V，default：5V>
  - DVDD：数字电源电压 <5V>
  - DVSS：数字地
  - A[7:0]：地址
  - D[0:7]：数据
  - PGMEN：编程使能 <PGM：5V，READ：0V>
  - RDEN：读使能 <READ：5V，PGM：0V>
  - AEN：地址使能
- 工作模式<3种>，通过PGMEN和RDEN选择

| MODE | PGMEN | RDEN | AVDD | DVDD | 备注 |
| ---- | ----- |---| ---- | ----- |---|
| PGM | H | L | H | H | 初始0，烧录后为1; A[7:0]选中bit，使能AEN高脉冲写入，此时D[0:7]没用 |
| READ | L | H | - | H | A[4:0]选择某8bit，D[0:7]={ Fuse[i], Fuse[i+31], ... } |
| Inactive | L | L | - | H | 不在读写时就切换到该模式，建议AEN=L，此时此时D[0:7]没用 |
| 禁用 | - | - | - | - | - |

- 只有PGM和READ模式下，AEN可以为高
- AEN为高时，地址不能翻转
- 不能直接进行READ和PGM之间的切换

##### PGM的时序
- 关键边沿：PGMEN变化
  - AVDD拉高→PGMEN拉高-拉低→AVDD为H/L/F
  - RDEN拉低→PGMEN拉高-拉低→RDEN拉高
  - PGMEN拉高→AEN拉高-拉低-...-→PGMEN拉低
- 关键边沿：AEN变化
  - A[7:0]变化→AEN拉高-拉低→A[7:0]变化
  - AEN的脉宽要求
  - 前后两个AEN的posedge间距要求

##### READ的时序
- 关键边沿：RDEN变化
  - DVDD拉高→RDEN拉高-拉低→DVDD拉低
  - RDEN拉高→AEN拉高-拉低-...→RDEN拉低
- 关键边沿：AEN变化
  - A[7:0]变化→AEN拉高-拉低→A[7:0]变化
  - AEN的脉宽要求
  - 前后两个AEN的posedge间距要求
  - AEN拉高→D[0:7]有效

#### Cardiff Bs EFUSE CTRL
接口列表
| signal name | direction | width | comment | 备注 |
| ---- | ----- |---| ---- | ----- |
| clk | input | 1 | | |
| rstn | input | 1 | | |
| scan_mode | input | 1 | | |
| pmu_efuse_start_13m | input | 1 | 上电完成后，pmu给出efuse可以开始autoload流程的使能信号 | |
| rg_efuse_refresh | input | 1 | 纯寄存器模式下的刷新信号，WC | CA 待定 |
| rg_efuse_choose | input | 2 | efuse片选 | CA中delete |
| rg_efuse_mode | input | 2 | efuse控制模式，0：64b读，1：64b写 | |
| rg_efuse_start | input | 1 | 硬件读写efuse启动信号，WC | |
| rg_efuse_wr_data | input | 64 | 64bit写模式的写数据 | CA中如果没有片选，一次读写256bit |
| rg_efuse_rd_data | output | 64 | 64b读模式的数据，和autoload读到第一片efuse数据（？ | CA同上 |
| rg_efuse_read_done | output | 1 | 64b读模式完成，RO | |
| rg_efuse_write_done | output | 1 | 64b写模式完成，RO | |
| rg_efuse_no_blank | output | 4 | 4xefuse是否为空片，1：非空 | CA只需要1bit |
| rg_efuse_strobe_done | output | 1 | 纯寄存器模式写操作写，完成一次写返回done| strobe信号≈CA中的AEN |
| rg_efuse_password | input | 16 | 写保护，为0x55AA时才能写 | CA待定 |
| rg_efuse_trd | input | 6 | 读操作STROBE高电平时间，单位为cycle| CA中为AEN高脉宽，也叫TRD，位宽待定 |
| rg_efuse_tpgm | input | 10 | 写操作STROBE高电平时间，单位为cycle | CA同，位宽待定 |
| rg_efuse_reg_mode | input | 1 | 是否有寄存器直接控制efuse模式（？ 高有效 | CA待定 |
| rg_efuse_pgenb | input | 1 | 纯寄存器下PGEMB | CA中 |
| rg_efuse_strobe | input | 1 | 纯寄存器下STROBE（？读有效） | CA中AEN |
| rg_efuse_nr | input | 1 | 纯寄存器下NR | CA中 |
| rg_efuse_we | input | 64 | 纯寄存器下WE，一次一个非0位 | CA中地址译码A[7:0] |
| rg_efuse_q | output | 1 | 纯寄存器下EFUSE返回的读数据Q | CA中一次能8bit？ |
| efuse_<0-3>_pgenb_18p | output | 1 | 输出到器件efuse<0-3>的pgenb，1.8V | CA中有 |
| efuse_<0-3>_strobe_18p | output | 1 | 输出到器件efuse<0-3>的strobe，1.8V | CA中有 |
| efuse_<0-3>_nr_18p | output | 1 | 输出到器件efuse<0-3>的nr，1.8V | 
CA中有 |
| efuse_<0-3>_we_18p | output | 64 | 输出到器件efuse<0-3>的we，1.8V | 
CA中为地址 |
| efuse_<0-3>_q_18p | input | 1 | 器件efuse<0-3>给出的读数据q，1.8V | 
CA中有，位宽待定 |
| efuse_autoload_done | output | 1 | 上电后efuse完成autoload标志，电平，有时钟就会一定能拉高 | CA中保留 |
| efuse_autoload_vld | output | 1 | 上电后efuse完成autoload的有效标志，脉冲，控制reg_ctrl刷新对应autoload的寄存器 | CA中保留 |
| efuse_busy | output | 1 | efuse处于读写状态标志，1：忙碌 | CA中保留 |

efuce_ctrl内部架构
- 
