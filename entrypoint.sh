#!/bin/bash

echo "Host localhost
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
echo "Host 0.0.0.0
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
/etc/init.d/ssh start
$HADOOP_HOME/bin/hdfs namenode -format
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

hdfs dfs -mkdir      /tmp
hdfs dfs -mkdir -p   /user/hive/warehouse
hdfs dfs -chmod g+w  /tmp
hdfs dfs -chmod g+w  /user/hive/warehouse

mkdir -p /var/log/hive
cd /home/hadoop || exit
service mysql start
mysql -u root < mysql.sql
$HIVE_HOME/bin/schematool -initSchema -dbType mysql
$HIVE_HOME/bin/hiveserver2 --hiveconf hive.server2.enable.doAs=false>/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log &

hdfs dfs -mkdir /spark-jars
hdfs dfs -put $SPARK_HOME/jars/* /spark-jars/

bash