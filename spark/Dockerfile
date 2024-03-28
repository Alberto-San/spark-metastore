FROM eclipse-temurin:11-jre-alpine

MAINTAINER Cam Saul <cam@metabase.com>

WORKDIR /spark

# Set necessary environment variables.
ENV HADOOP_HOME="/opt/hadoop"
ENV PATH="/opt/spark/bin:/opt/hadoop/bin:${PATH}"
ENV DATABASE_DRIVER=org.postgresql.Driver
ENV DATABASE_TYPE=postgres
ENV DATABASE_TYPE_JDBC=postgresql
ENV DATABASE_PORT=5432
ENV SPARK_VERSION 3.4.2
ENV SPARK_ARCHIVE spark-${SPARK_VERSION}-bin-hadoop3.tgz
ENV HADOOP_VERSION 3.3.0
ENV SPARK_DIR "/spark/spark-${SPARK_VERSION}-bin-hadoop3"

# Copy necessary files
COPY ${SPARK_ARCHIVE} .
COPY run.sh .

RUN apk update && apk add libc6-compat

RUN tar -xf $SPARK_ARCHIVE && \
    rm $SPARK_ARCHIVE && \
    echo "Download and install the database connector" && \
    wget https://jdbc.postgresql.org/download/postgresql-42.2.18.jar && \
    cp postgresql-42.2.18.jar /opt/ && \
    ln -s /opt/postgresql-42.2.18.jar ${SPARK_DIR}/jars/

COPY hive-site.xml ${SPARK_DIR}/conf/

EXPOSE 10000

ENTRYPOINT java \
  -Duser.timezone=Etc/UTC \
  -Djava.io.tmpdir=/tmp \
  -cp "${SPARK_DIR}/conf:${SPARK_DIR}/jars/*" \
  org.apache.spark.deploy.SparkSubmit \
  --conf spark.executor.extraJavaOptions=-Duser.timezone=Etc/UTC \
  --conf spark.eventLog.enabled=false \
  --conf spark.sql.hive.metastore.version=2.3.9 \
  --packages org.apache.hadoop:hadoop-aws:3.3.1,org.apache.hive:hive-common:2.3.6,org.apache.hive:hive-serde:2.3.6 \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.hadoop.fs.s3a.access.key=test \
  --conf spark.hadoop.fs.s3a.secret.key=test \
  --conf spark.hadoop.fs.s3a.endpoint=http://localstack:4566 \
  --conf spark.hadoop.fs.s3a.connection.ssl.enabled=false \
  --conf spark.sql.warehouse.dir=s3a://local-test/data \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --name "Thrift JDBC/ODBC Server" \
  spark-internal