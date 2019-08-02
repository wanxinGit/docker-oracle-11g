支持SSH，集成supervisor的centos镜像
基于centos:7.4.1708

镜像启动参考脚本：
docker run -idt -p 2222:22 -p 1522:1521 \
 -v /opt/docker/storage/oracle/oradata:/opt/oracle/oradata \
 -v /opt/docker/storage/oracle/flash_recovery_area:/opt/oracle/flash_recovery_area \
 -v /opt/docker/storage/oracle/init_data:/opt/oracle/init_data \
 -v /etc/localtime:/etc/localtime:ro \
 -e TZ="Asia/Shanghai" \
 -e SSH_PASS_RANDOM=false \
 -e SSH_ROOT_PASS=123456 \
 -e SSH_ORACLE_PASS=123456 \
 --name oracle11g \
 wanxin/docker-oracle-11g

其中参数：
1、SSH_PASS_RANDOM配置为true表示全部密码随机生成（默认为false，配置打开将覆盖参数指定的密码）
2、SSH_ROOT_PASS、SSH_ORACLE_PASS分别为root和oracle两个账户的ssh密码

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


--20171113
1、增加菜单，解决oracle安装后脚本执行的问题，安装后只需根据提示输入2即可自动切换root账户，执行对应脚本
2、可通过菜单完成实例的启停操作
3、完成重建容器后实例的恢复操作，重建容器后只需要完成oracle安装(还有sh执行)后即可通过该菜单项自动完成数据恢复

--后续待完善的地方：
1、docker日志部分，要给出一些提示，告知用户如何使用镜像
2、涉及密码部分，目前都是写死的简单密码，后续最好通过随机密码，然后日志的形式告知用户

--20171116
1、完成日志提示及ssh随机密码生成


--20190801
1、数据库安装、root脚本执行、监听安装、数据库实例安装等操作放到容器启动后自动执行，不再需要一步步操作。
2、如果存在旧数据才提示用户进行交互操作，可选择恢复数据或者重新建库。
3、登陆oracle账户后不会自动启动选择框，而是提示用户启动进程

--20190730
1、准备新增一个dmp_data挂载目录，用作放置dmp文件，用于数据导入。
2、另外此目录下应该还有一个init.ini文件，用于配置数据库用户创建、命名空间创建，其格式如下：
[HS_CB]
namespace=HS_CB_DATA
db_schema=HS_CB
db_user=HS_CB
db_pass=cqpgx
db_imp_file=file/hs_cb.dmp


--后续待完善的地方：
1、完成oracle账户密码的生成，目前准备通过交互的方式卸载建库的脚本中（要把密码同步到删库脚本中，否则无法进行）
2、完成oracle的一些编码之类参数的可通过启动参数配置