# 登录oracle账户时启动交互式的建库脚本

# 检查是否存在旧的数据库数据，并提示用户是选择新建后者恢复实例操作
oradataPath="/opt/oracle/oradata/orcl"
flashRecoveryAreaPath1="/opt/oracle/flash_recovery_area/orcl"
flashRecoveryAreaPath2="/opt/oracle/flash_recovery_area/ORCL"
if [ -d "$oradataPath" ] && [ -d "$flashRecoveryAreaPath1" ] && [ -d "$flashRecoveryAreaPath2" ]; then
	echo "检测到存在数据文件，建议5恢复数据库实例，如果选择4创建数据库实例将清除旧数据！"
fi

# 安装oracle数据库
function install_oracle(){
	/opt/linux.x64_11gR2_database/runInstaller -ignoreSysPrereqs -ignorePrereq -silent -responseFile /opt/config/rsp/db_install.rsp
}

# 创建数据库监听
function create_linsener(){
	netca /silent /responsefile /opt/config/rsp/netca.rsp
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
	dbca -silent -responseFile /opt/config/rsp/dbca_create.rsp
}

# 启动实例
function start_instance(){
	echo "此项功能暂无"
}

# 暂停实例
function stop_instance(){
	echo "此项功能暂无"
}

# 删除实例
function remove_instance(){
	dbca -silent -responseFile /opt/config/rsp/dbca_delete.rsp
}

# 恢复实例，用于删除容器重建后恢复数据库
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
	#stop_instance
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
		mv "${flashRecoveryAreaPath1}_old" "$oradataPath"
	else
		echo "备份的文件夹${flashRecoveryAreaPath1}_old不存在，恢复操作终止！"
		return
	fi
	if [ -d "${flashRecoveryAreaPath2}_old" ]; then
		mv "${flashRecoveryAreaPath2}_old" "$oradataPath"
	else
		echo "备份的文件夹${flashRecoveryAreaPath2}_old不存在，恢复操作终止！"
		return
	fi
	# 启动实例和监听
	start_instance
	start_linsener
	echo "完成数据库恢复!!"
}

while(true)
do
	echo -e "请输入指令：\n 1 安装数据库(不要重复执行,安装完成后需要根据提示su到root账户执行的两个脚本)  \n 2 创建监听(不要重复执行) \n 3 启动监听 \n 4 停止监听 \n 5 创建数据库实例 \n 6 启动数据库实例(创建后会默认启动，不需要重复操作) \n 7 停止数据库实例 \n 8 删除orcl数据库实例 \n 9 恢复orcl实例(用于删除重建容器后恢复数据库) \n 退出操作请输入q"
	read operationType
	case $operationType in
		1)  install_oracle
    		;;
		2)  create_linsener
    		;;
    		3)  start_linsener
    		;;
    		4)  stop_linsener
    		;;
    		5)  create_instance
    		;;
		6)  start_instance
    		;;
		7)  stop_instance
    		;;
		8)  remove_instance
    		;;
		9)  recover_instance
    		;;
		"q" | "quit" | "Q" | "exit" )  break
    		;;
    		*)  echo "输入错误，请重新选择！"
    		;;
	esac
done