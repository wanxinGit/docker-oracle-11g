#!/bin/bash

# 引入Oracle操作相关的脚本
. ./OracleShell.sh

# 本文件为登录oracle账户时启动交互式的建库脚本

while(true)
do
	if [ ! -f "$installed_flag" ]; then
		echo "数据库安装中...请等待"
		sleep 2s
		continue
	fi
	if [ ! -f "$root_shell_ran_flag" ]; then
		echo "两个root权限脚本执行中...请等待"
		sleep 2s
		continue
	fi
	
	if [ -d "$oradataPath" ] && [ -d "$flashRecoveryAreaPath1" ] && [ -d "$flashRecoveryAreaPath2" ]; then
		echo -e "重装数据库后监测到已存在的数据库文件，您可以选择如下操作：\
			\n \t1 恢复数据库(恢复原有数据) \
			\n \t2 重新创建数据库(删除原有数据，重建新库) \
			\n 退出操作请输入q"
		read -p "Enter a number：" operationType
		case $operationType in
			1)  recover_instance
				;;
			2)  
				create_linsener
				create_instance
				;;
			"q" | "quit" | "Q" | "exit" )  break
				;;
				*)  echo "输入错误，请重新选择！"
				;;
		esac
	fi
	
	if [ ! -f "$linsener_created_flag" ]; then
		echo "数据库监听创建中...请等待"
		sleep 2s
		continue
	fi
	if [ ! -f "$instance_created_flag" ]; then
		echo "数据库实例创建中...请等待"
		sleep 2s
		continue
	fi
	
	
	echo -e "请输入指令： \
		\n \t1 启动监听(创建后会默认启动，不需要重复操作) \
		\n \t2 停止监听 \
		\n \t3 启动数据库实例(创建后会默认启动，不需要重复操作) \
		\n \t4 停止数据库实例 \
		\n \t5 删除orcl数据库实例 \
		\n \t6 从init_data目录导入数据库 \
		\n 退出操作请输入q"
	read -p "Enter a number：" operationType
	case $operationType in
    	1)  start_linsener
    		;;
    	2)  stop_linsener
    		;;
		3)  start_instance
    		;;
		4)  stop_instance
    		;;
		5)  remove_instance
    		;;
		6)  import_from_dmp
		;;
		"q" | "quit" | "Q" | "exit" )  break
    		;;
    		*)  echo "输入错误，请重新选择！"
    		;;
	esac
done