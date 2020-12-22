Air72XU系列的模块Flash总空间都为64Mb=8MB
用户二次开发有两个分区可用，脚本文件区和文件系统区

脚本文件区：通过Luatools烧写的所有文件，都存放在此区域
        此区域的大小参考：http://doc.openluat.com/article/1334/0


文件系统区：程序运行过程中实时创建的文件都会存放在此区域
            此区域的大小参考：http://doc.openluat.com/article/1334/0           
            不同版本的core可能会有差异，可通过rtos.get_fs_free_size()查询剩余的文件系统可用空间







Air720XU系列模块的RAM总空间都为128Mb=16MB

其中Lua运行可用内存：1.36MB
可通过collectgarbage("count")查询已经使用的内存空间（返回值单位为KB）
