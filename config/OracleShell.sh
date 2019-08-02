#!/bin/bash

# 此脚本包含oracle的常用路径和方法，供其他脚本引用，本身不需要执行权限

# 检查是否存在旧的数据库数据，并提示用户是选择新建后者恢复实例操作
oradataPath="/opt/oracle/oradata/orcl"
flashRecoveryAreaPath1="/opt/oracle/flash_recovery_area/orcl"
flashRecoveryAreaPath2="/opt/oracle/flash_recovery_area/ORCL"
# 创建数据库命名空间和用户的配置文件
dbInitFile="/opt/oracle/init_data/init.ini"
# 最新的数据库dmp文件目录
dmpPath="/opt/oracle/init_data/last_dmp"

# 以下为数据库安装各个阶段的标识，对应会存放到各个文件中，防止安装步骤错乱和冲突
flag_base_path="/home/oracle/"
installing_flag=$flag_base_path"flag_installing"
installed_flag=$flag_base_path"flag_installed"
root_shell_ran_flag=$flag_base_path"flag_root_shell_ran"
linsener_created_flag=$flag_base_path"flag_linsener_created"
instance_created_flag=$flag_base_path"flag_instance_created"

# 安装oracle数据库
function install_oracle(){
	if [ -f "$installing_flag" ]; then
 		echo "oracle安装中，请勿重复执行安装操作..."
		return
	fi
	if [ -f "$installed_flag" ]; then
 		echo "oracle安装已完成，请勿重复安装..."
		return
	fi
	touch $installing_flag
	/opt/database/runInstaller -ignoreSysPrereqs -ignorePrereq -silent -waitforcompletion -responseFile /opt/oracle/rsp/db_install.rsp

	rm -f $installing_flag
	touch $installed_flag
}

# 安装oracle之后用root权限执行两个脚本
function run_sh_as_root_after_install_oracle(){
	if [ ! -f "$installed_flag" ]; then
 		echo "Oracle安装尚未完成，无法执行两个root权限的shell脚本"
		return
	fi
	
	#从临时文件中获取root账户密码
	rootPass=$(cat /tmp/tempPass)

	/usr/bin/expect <<EOF3
	set timeout 5
	spawn su -
	expect "Password:"
	send "${rootPass}\r"
	expect "#"
	send "/opt/oracle/oraInventory/orainstRoot.sh\r"
	expect "#"
	send "/opt/oracle/102/root.sh\r"
	expect eof
EOF3
	echo -e "orainstRoot.sh & root.sh has runned!\n next step you can create linsener and instance."
	touch $root_shell_ran_flag
}

# 创建数据库监听
function create_linsener(){
	if [ ! -f "$root_shell_ran_flag" ]; then
 		echo "两个root权限的shell脚本尚未执行，无法创建和启动监听"
		return
	fi
	netca /silent /responsefile /opt/oracle/rsp/netca.rsp
	touch $linsener_created_flag
}

# 启动监听
function start_linsener(){
	lsnrctl start
}

# 停止监听
function stop_linsener(){
	lsnrctl stop
}

# 创建实例
function create_instance(){
	if [ ! -f "$linsener_created_flag" ]; then
 		echo "监听尚未创建，无法创建实例"
		return
	fi

	# 1、询问是否自动生成密码
	# 2、如果是选择否，则一次提示输入SYS和SYSTEM的密码
	# 3、提示编码类型选择
	dbca -silent -responseFile /opt/oracle/rsp/dbca_create.rsp
	# 4、完成创建后将sys密码输出到dbca_delete.rsp中，以便后续删除数据库时可用
	# 5、输出数据库账号密码信息，并提示用户牢记

	touch $instance_created_flag
}

# 启动实例
function start_instance(){
	export ORACLE_SID=orcl
	sqlplus /nolog <<EOF1
	conn / as sysdba
	startup
	exit
EOF1
}

# 暂停实例
function stop_instance(){
	export ORACLE_SID=orcl
	sqlplus /nolog <<EOF2
	conn / as sysdba
	shutdown immediate
	exit
EOF2
}

# 删除实例
function remove_instance(){
	dbca -silent -responseFile /opt/oracle/rsp/dbca_delete.rsp
}

# 恢复实例，用于删除容器重建后恢复数据库(主体流程备份原目录-建库建监听-停止监听和实例-还原原目录删除新建目录-重启实例和监听)
function recover_instance(){
	# 备份原文件为xxxx_old（先检查数据库文件是否存在）
	if [ -d "${oradataPath}" ]; then
		mv "${oradataPath}" "${oradataPath}_old"
	else
		echo "备份的文件夹${oradataPath}不存在，恢复操作终止！"
		return
	fi
	if [ -d "${flashRecoveryAreaPath1}" ]; then
		mv "${flashRecoveryAreaPath1}" "${flashRecoveryAreaPath1}_old"
	else
		echo "备份的文件夹${flashRecoveryAreaPath1}不存在，恢复操作终止！"
		return
	fi
	if [ -d "${flashRecoveryAreaPath2}" ]; then
		mv "${flashRecoveryAreaPath2}" "${flashRecoveryAreaPath2}_old"
	else
		echo "备份的文件夹${flashRecoveryAreaPath2}不存在，恢复操作终止！"
		return
	fi

	# 新建数据库实例和监听
	create_linsener
	create_instance
	# 停止实例和监听
	stop_instance
	stop_linsener
	# 删除新文件，并将xxxx_old改回来
	rm -rf ${oradataPath}
	rm -rf ${flashRecoveryAreaPath1}
	rm -rf ${flashRecoveryAreaPath2}
	if [ -d "${oradataPath}_old" ]; then
		mv "${oradataPath}_old" "$oradataPath"
	else
		echo "备份的文件夹${oradataPath}_old不存在，恢复操作终止！"
		return
	fi
	if [ -d "${flashRecoveryAreaPath1}_old" ]; then
		mv "${flashRecoveryAreaPath1}_old" "${flashRecoveryAreaPath1}"
	else
		echo "备份的文件夹${flashRecoveryAreaPath1}_old不存在，恢复操作终止！"
		return
	fi
	if [ -d "${flashRecoveryAreaPath2}_old" ]; then
		mv "${flashRecoveryAreaPath2}_old" "${flashRecoveryAreaPath2}"
	else
		echo "备份的文件夹${flashRecoveryAreaPath2}_old不存在，恢复操作终止！"
		return
	fi
	# 启动实例和监听
	start_instance
	start_linsener
	echo "完成数据库恢复!!"
}

# 根据配置文件删除已经存在的用户和命名空间
function dropExistUserAndNameSpace(){
	echo "旧数据删除待完成..."
}

# 根据配置文件创建命名空间、用户，并导入dmp文件
function createUserNameSpaceAndImportDmp(){
	echo "新数据创建和导入待完成..."
}


# 从指定目录
function import_from_dmp(){
	# 根据配置文件删除已经存在的用户和命名空间
	dropExistUserAndNameSpace
	
	# 根据配置文件创建命名空间、用户，并导入dmp文件
	createUserNameSpaceAndImportDmp
	
	echo "完成数据库导入!!"
}
