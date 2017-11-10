# Base image to use, this must be set as the first line
FROM centos:7.4.1708

# Maintainer: docker_user <docker_user at email.com> (@docker_user)
MAINTAINER wanxin <258621580@qq.com>

# 替换yum源为阿里云的，增加包下载的速度
RUN yum install -y wget \
	&& wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
	&& yum clean all && yum makecache

# 安装需要的软件包
RUN yum install -y passwd openssl openssh-server zip unzip python-setuptools
# 安装supervisor
RUN easy_install supervisor

# 配置supervisor
RUN mkdir -p /var/log/supervisor
COPY config/supervisord.conf /etc/supervisord.conf

# 配置允许root用户ssh登录
RUN mkdir -p /var/run/sshd
RUN echo "root:123456" | chpasswd
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
RUN groupadd oinstall && groupadd dba && useradd -m -g oinstall -G dba oracle && echo "oracle:123456" | chpasswd

# 创建Oracle安装文件夹以及数据存放文件夹
RUN mkdir /opt/oracle/102 -p && chown -R oracle:dba /opt/oracle

#拷贝启动建库用的自动交互脚本到oracle用户目录
COPY config/OracleShell.sh /home/oracle/OracleShell.sh
COPY config/RootShell.sh /root/RootShell.sh
RUN chmod 777 /home/oracle/OracleShell.sh && chmod 777 /root/RootShell.sh

# 安装依赖包
RUN yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 \
	elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc glibc.i686 \
	glibc-common glibc-devel glibc-devel.i686 glibc-headers ksh libaio \
	libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libstdc++ \
	libstdc++.i686 libstdc++-devel make sysstat && \
	yum -y install libXp

# 拷贝oracle安装包并解压
COPY package/linux.x64_11gR2_database.zip /opt/linux.x64_11gR2_database.zip
RUN unzip /opt/linux.x64_11gR2_database.zip -d /opt/ && \
    rm -f /opt/linux.x64_11gR2_database.zip && \
    chown -R oracle:dba /opt/linux.x64_11gR2_database && \
    chmod 777 /opt/linux.x64_11gR2_database/runInstaller && \
    chmod 777 /opt/linux.x64_11gR2_database/install/*.sh && \
    chmod 777 /opt/linux.x64_11gR2_database/install/unzip && \
    chmod 777 /opt/linux.x64_11gR2_database/install/.oui

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
RUN echo "#oracle账户登录的时候启动建库的交互脚本" >> ~/.bash_profile && \
    echo "./OracleShell.sh" >> ~/.bash_profile

#拷贝启动建库用的自动交互脚本到oracle用户目录
COPY config/OracleShell.sh ~

#拷贝oracle静默安装配置文件到容器
COPY config/rsp /opt/config/rsp

# 不切换到root用户会导致CMD启动supervisord失败
USER root

# 用supervisor启动相关服务
CMD ["/usr/bin/supervisord"]