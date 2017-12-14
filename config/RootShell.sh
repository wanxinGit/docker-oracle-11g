# 修改挂载的目录读写权限
chown -R oracle:dba /opt/oracle/oradata
chown -R oracle:dba /opt/oracle/flash_recovery_area
echo "change oradata & flash_recovery_area mod finish!"


# 各种登录密码的重置
sshRootPass="${SSH_ROOT_PASS}"
sshOraclePass="${SSH_ORACLE_PASS}"
# oracleSysPass="${ORACLE_SYS_PASS}"
# oracleSystemPass="${ORACLE_SYSTEM_PASS}"

if [ "$SSH_PASS_RANDOM" == "true" ]; then
	sshRootPass=`mkpasswd -l 16`
	sshOraclePass=`mkpasswd -l 16`
	# oracleSysPass=`mkpasswd -l 16`
	# oracleSystemPass=`mkpasswd -l 16`
fi

# 进行ssh密码的设置
echo "root:${sshRootPass}" | chpasswd
echo "oracle:${sshOraclePass}" | chpasswd

# 将root用户密码保存到临时文件中，后续oracle安装完成后执行脚本需要用到
echo "${sshRootPass}" > /tmp/tempPass

# 由于sed指定中对&符号的特殊处理，暂时补救办法是将密码中&替换成s
# oracleSysPass=${oracleSysPass//&/s}
# oracleSystemPass=${oracleSystemPass//&/s}
# 进行oracle管理员密码的设置
# sed -ri "s/^oracle.install.db.config.starterdb.password.SYS=\s*.*/oracle.install.db.config.starterdb.password.SYS=${oracleSysPass}/" /opt/config/rsp/db_install.rsp
# sed -ri "s/^oracle.install.db.config.starterdb.password.SYSTEM=\s*.*/oracle.install.db.config.starterdb.password.SYSTEM=${oracleSystemPass}/" /opt/config/rsp/db_install.rsp

# 将密码设置结果输出的docker日志中
echo "root远程连接密码被设置为 ${sshRootPass}，请牢记！" >> /dev/console
echo "oracle远程连接密码被设置为 ${sshOraclePass}，请牢记！" >> /dev/console
# echo "oracle的sys账户密码被设置为 ${oracleSysPass}，请牢记！" >> /dev/console
# echo "oracle的system账户密码被设置为 ${oracleSystemPass}，请牢记！" >> /dev/console