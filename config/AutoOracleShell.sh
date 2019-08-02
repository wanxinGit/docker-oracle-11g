#!/bin/bash

# 引入Oracle操作相关的脚本
cd /home/oracle
. ./.bash_profile
. ./OracleShell.sh

# 启动容器后依次进行如下步骤来完成数据库安装

echo "准备自动进行oracle安装..."
install_oracle
echo "数据库安装完成，准备进行两个root权限脚本的执行..."
run_sh_as_root_after_install_oracle
echo "root权限脚本执行完成，准备进行监听创建.."


if [ -d "$oradataPath" ] && [ -d "$flashRecoveryAreaPath1" ] && [ -d "$flashRecoveryAreaPath2" ]; then
	echo "监测到存在旧的数据库文件，数据库自动安装终止！"
	exit
fi

create_linsener
echo "监听创建完成，准备创建数据库实例.."
create_instance
echo "数据库实例创建完成，数据库自动安装所有脚本完成！"