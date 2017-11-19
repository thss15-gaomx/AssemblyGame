# AssemblyGame
### 编译工具：masm32
### 汇编指令：
- ml /c /coff PCE.asm
- rc /v PCE_RC.rc
- cvtres /machine:ix86 PCE_RC.res
- link /subsystem:windows PCE.obj PCE_RC.obj
- 或者直接在PCE.asm PCE_RC.rc所在目录下打开命令行，输入“make PCE PCE_RC”，即可成功编译static中存放所有的图片资源
- 首次游戏结束会生成Best.txt存放历史最高纪录，每次游戏结束会刷新其中存放的最高值
