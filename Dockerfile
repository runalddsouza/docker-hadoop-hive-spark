FROM openjdk:8-jdk

RUN apt-get update
RUN apt -y install software-properties-common
RUN apt-get install -y openssh-server
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys

RUN mkdir /home/hadoop
WORKDIR /opt
ENV HADOOP_VERSION=2.7.7
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CLASSPATH=$JAVA_HOME/lib/tools.jar
RUN curl -sL \
  "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    | gunzip \
    | tar -x -C /opt/
RUN rm -rf $HADOOP_HOME/share/doc \
  && chown -R root:root $HADOOP_HOME \
  && mkdir -p $HADOOP_HOME/logs \
  && mkdir -p $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_HOME/logs
RUN echo "export JAVA_HOME=/usr/local/openjdk-8" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY hadoop/* $HADOOP_HOME/etc/hadoop/
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# Install Spark
ENV SPARK_VERSION=2.4.4
ENV SPARK_HOME=/opt/spark-$SPARK_VERSION-bin-hadoop2.7
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH $PATH:$SPARK_HOME/bin

RUN curl -sL \
  "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $SPARK_HOME \
  && mkdir -p /data/spark/ \
  && mkdir -p $SPARK_HOME/logs \
  && mkdir -p $SPARK_CONF_DIR \
  && chmod 777 $SPARK_HOME/logs

#Install Hive
ENV HIVE_VERSION=2.3.1
ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH

RUN apt-get update && apt-get install -y wget procps && \
	wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
	tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
	mv apache-hive-$HIVE_VERSION-bin hive && \
	rm apache-hive-$HIVE_VERSION-bin.tar.gz && \
	apt-get --purge remove -y wget && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*
COPY hive/* $HIVE_HOME/conf/

#MYSQLDB as Hive Metastore
RUN apt-get update && apt-get -y install default-mysql-server
WORKDIR $HIVE_HOME/lib/
RUN apt-get update && apt-get install -y wget && \
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.13/mysql-connector-java-8.0.13.jar
RUN cp $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/
RUN cp $HIVE_HOME/lib/mysql-connector-java-8.0.13.jar $SPARK_HOME/jars/

WORKDIR /home/hadoop
COPY entrypoint.sh ./
COPY scripts/mysql.sql ./
RUN chmod 777 entrypoint.sh

EXPOSE 10000 10002 8020 9864 9870 19888 8088 22 8042
ENTRYPOINT ["/home/hadoop/entrypoint.sh"]