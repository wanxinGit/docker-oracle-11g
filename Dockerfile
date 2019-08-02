# Base image to use, this must be set as the first line
FROM centos:7.4.1708

# Maintainer: docker_user <docker_user at email.com> (@docker_user)
MAINTAINER wanxin <258621580@qq.com>

# 替换yum源为阿里云的，增加包下载的速度
RUN yum install -y wget \
	&& wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
	&& yum clean all && yum makecache

# 安装需要的软件包
RUN yum install -y passwd openssl openssh-server zip unzip python-setuptools expect dos2unix
# 安装supervisor
RUN easy_install supervisor

# 配置supervisor
RUN mkdir -p /var/log/supervisor
COPY config/supervisord.conf /etc/supervisord.conf

# 配置相关环境变量
ENV SSH_PASS_RANDOM false
ENV SSH_ROOT_PASS 123456
ENV SSH_ORACLE_PASS 123456
# ENV ORACLE_SYS_PASS adminroot
# ENV ORACLE_SYSTEM_PASS adminroot

# 配置允许root用户ssh登录
RUN mkdir -p /var/run/sshd
# RUN echo "root:123456" | chpasswd
RUN ssh-keygen -q -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key  -N ''
RUN sed -ri "s/^PermitRootLogin\s+.*/PermitRootLogin yes/" /etc/ssh/sshd_config
RUN sed -ri "s/UsePAM yes/#UsePAM yes/g" /etc/ssh/sshd_config

# 对外暴露端口
EXPOSE 22 8080 1521

# 关闭防火墙(不需要)

# 关闭SELINUX(不需要)

# 修改hostname和host文件，暂时先不管试一下后续启动监听会不会有问题

#  创建oracle用户组
RUN groupadd oinstall && groupadd dba && useradd -m -g oinstall -G dba oracle
# && echo "oracle:123456" | chpasswd

# 创建Oracle安装文件夹以及数据存放文件夹
RUN mkdir /opt/oracle/102 -p && chown -R oracle:dba /opt/oracle

#拷贝启动建库用的自动交互脚本到oracle用户目录
COPY config/OracleShell.sh /home/oracle/OracleShell.sh
COPY config/AutoRootShell.sh /root/AutoRootShell.sh
COPY config/AutoOracleShell.sh /home/oracle/AutoOracleShell.sh
COPY config/LoopSelectOption.sh /home/oracle/LoopSelectOption.sh
RUN chmod 777 /home/oracle/OracleShell.sh \
	&& chmod 777 /root/AutoRootShell.sh \
	&& chmod 777 /home/oracle/AutoOracleShell.sh \
	&& chmod 777 /home/oracle/LoopSelectOption.sh \
	&& dos2unix /home/oracle/OracleShell.sh \
	&& dos2unix /root/AutoRootShell.sh \
	&& dos2unix /home/oracle/AutoOracleShell.sh \
	&& dos2unix /home/oracle/LoopSelectOption.sh

# 安装依赖包
RUN yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 \
	elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc glibc.i686 \
	glibc-common glibc-devel glibc-devel.i686 glibc-headers ksh libaio \
	libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libstdc++ \
	libstdc++.i686 libstdc++-devel make sysstat && \
	yum -y install libXp

# 拷贝oracle安装包并解压
COPY package /opt/package
RUN unzip -o /opt/package/linux.x64_11gR2_database_1of2.zip -d /opt/ && \
    unzip -o /opt/package/linux.x64_11gR2_database_2of2.zip -d /opt/ && \
# rm -rf /opt/package && \
    chown -f -R oracle:dba /opt/database && \
    chmod -f 755 /opt/database/runInstaller && \
    chmod -f 755 /opt/database/install/*.sh && \
    chmod -f 755 /opt/database/install/unzip && \
    chmod -f 755 /opt/database/install/.oui

# root账户下修改配置文件
RUN echo "oracle soft nproc 2047" >> /etc/security/limits.conf && \
    echo "oracle hard nproc 16384" >> /etc/security/limits.conf && \
    echo "oracle soft nofile 1024" >> /etc/security/limits.conf && \
    echo "oracle hard nofile 65536" >> /etc/security/limits.conf

#RUN echo "kernel.shmall = 4294967296" >> /etc/sysctl.conf && \
#    echo "kernel.shmmax = 68719476736" >> /etc/sysctl.conf && \
#    echo "kernel.shmmni = 4096" >> /etc/sysctl.conf && \
#    echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf && \
#    echo "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf && \
#    echo "net.core.rmem_default=4194304" >> /etc/sysctl.conf && \
#    echo "net.core.rmem_max=4194304" >> /etc/sysctl.conf && \
#    echo "net.core.wmem_default=262144" >> /etc/sysctl.conf && \
#    echo "net.core.wmem_max=262144" >> /etc/sysctl.conf && \
#    echo "vm.hugetlb_shm_group=1001" >> /etc/sysctl.conf && \
#    sysctl -p

RUN echo "session required /lib64/security/pam_limits.so" >> /etc/pam.d/login && \
    echo "session required pam_limits.so" >> /etc/pam.d/login

# 不再直接在启动脚本中加交互脚本
RUN echo "请使用oracle账户登录进行数据库管理操作" >> /etc/motd2 && \
    echo "登录后请使用./LoopSelectOption.sh进入数据库操作菜单" >> /etc/motd2 && \
	mv -f /etc/motd2 /etc/motd
	# 似乎不一定需要如下转码操作
	#iconv -f GBK -t UTF-8 /etc/motd2 > /etc/motd
	
# 切换到oracle用户
USER oracle

# 修改相关配置文件
RUN echo "ORACLE_BASE=/opt/oracle" >> ~/.bash_profile && \
    echo "ORACLE_HOME=\$ORACLE_BASE/102" >> ~/.bash_profile && \
    echo "ORACLE_SID=orcl" >> ~/.bash_profile && \
    echo "LD_LIBRARY_PATH=\$ORACLE_HOME/lib" >> ~/.bash_profile && \
    echo "PATH=\$PATH:\$ORACLE_HOME/bin:\$HOME/bin" >> ~/.bash_profile && \
    echo "export ORACLE_BASE ORACLE_HOME ORACLE_SID LD_LIBRARY_PATH PATH" >> ~/.bash_profile && \
    source ~/.bash_profile

# 在oracle账户添加启动建库交互脚本(不能和上面的脚本一起添加，否则source的时候会因为这个循环报错)
#RUN echo "#oracle账户登录的时候启动建库的交互脚本" >> ~/.bash_profile && \
#    echo "./LoopSelectOption.sh" >> ~/.bash_profile


#拷贝oracle静默安装配置文件到容器
COPY config/rsp /opt/oracle/rsp

# 不切换到root用户会导致CMD启动supervisord失败
USER root

# 用supervisor启动相关服务
CMD ["/usr/bin/supervisord"]