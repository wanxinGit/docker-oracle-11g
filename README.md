支持SSH，集成supervisor的centos镜像
基于centos:7.4.1708

镜像启动参考脚本：
docker run -idt -p 2222:22 -p 1522:1521 \
 -v /opt/docker/storage/oracle/oradata:/opt/oracle/oradata \
 -v /opt/docker/storage/oracle/flash_recovery_area:/opt/oracle/flash_recovery_area \
 wanxin/oracle:v1

默认账号密码相关：
root/123456
oracle/123456
数据库默认信息：
SID：orcl
SYS/adminroot
SYSTEM/adminroot
CHARACTERSET = "ZHS16GBK"
NATIONALCHARACTERSET= "AL16UTF16"


FAQ：
1、考虑到镜像最终的体积，没有进行oracle的安装，执行后登陆oracle账户可根据提示进行安装(安装完成后需要su到root账户执行两个脚本)。
2、由于git上传文件的限制，没有包含oracle11gr2的安装包（文件夹中是一个假的文件），需要自行下载后放到package目录再build