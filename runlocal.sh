#!/usr/bin/env bash

AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=testSecret
LOCALSTACK_ENDPOINT=localstack
LOCALSTACK_PORT=4566
S3_BUCKET=local-test
S3_PREFIX=data
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret
POSTGRES_DB=metastore
DATABASE_DRIVER=org.postgresql.Driver
DATABASE_TYPE=postgres
DATABASE_TYPE_JDBC=postgresql
DATABASE_PORT=5432
DATABASE_HOST=postgres
DATABASE_DB=${POSTGRES_DB}
DATABASE_USER=${POSTGRES_USER}
DATABASE_PASSWORD=${POSTGRES_PASSWORD}
S3_ENDPOINT_URL=http://${LOCALSTACK_ENDPOINT}:${LOCALSTACK_PORT}
JAVA_HOME=/opt/jdk1.8.0_131 
export PATH=$PATH:$JAVA_HOME/bin

generate_database_config(){
  cat << XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property> 
<name>javax.jdo.option.ConnectionDriverName</name> 
<value>org.postgresql.Driver</value> 
</property> 
<property> 
<name>javax.jdo.option.ConnectionURL</name> 
<value>jdbc:postgresql://postgres:5432/metastore</value> 
</property> 
<property> 
<name>javax.jdo.option.ConnectionUserName</name> 
<value>admin</value> 
</property> 
<property> 
<name>javax.jdo.option.ConnectionPassword</name> 
<value>secret</value> 
</property>
</configuration>
XML
}

generate_hive_site_config(){
  database_config=$(generate_database_config)
  cat << XML > "$1"
<configuration>
$database_config
</configuration>
XML
}

start_dashboard() {
    docker run -d \
    --network=host \
    --name=metabase \
    -v ~/my-metabase-db:/metabase.db \
    -e MB_DB_FILE=/metabase.db -e MUID=$UID -e MGID=$GID \
    -p 3000:3000
    metabase/metabase
}

test_spark_thrift(){
  /opt/spark/bin/pyspark       --packages org.apache.hadoop:hadoop-aws:3.3.1       --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem       --conf spark.hadoop.fs.s3a.path.style.access=true       --conf spark.hadoop.fs.s3a.access.key=test       --conf spark.hadoop.fs.s3a.secret.key=test       --conf spark.hadoop.fs.s3a.endpoint=http://localhost:4566       --conf spark.hadoop.fs.s3a.connection.ssl.enabled=false       --conf hive.metastore.uris=thrift://localhost:10000 --conf spark.sql.hive.metastore.version=2.3.9 --conf spark.sql.warehouse.dir=s3a://local-test/data
  # data = spark.range(100)
  # data.write.format("parquet").saveAsTable("dummy")
}

# configure & run schematool
spark_dir=/opt/spark/conf
generate_hive_site_config $spark_dir/hive-site.xml

# configure spark scripts
path_thrift=/opt/spark/sbin/start-thriftserver.sh
packages="org.apache.hadoop:hadoop-aws:3.3.1"
alias start_metastore="bash $path_thrift \
--hiveconf hive.server2.thrift.port=10001 \
--conf spark.sql.hive.metastore.version=2.3.9 \
--packages $packages \
--conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
--conf spark.hadoop.fs.s3a.path.style.access=true \
--conf spark.hadoop.fs.s3a.access.key=test \
--conf spark.hadoop.fs.s3a.secret.key=test \
--conf spark.hadoop.fs.s3a.endpoint=http://localhost:4566 \
--conf spark.hadoop.fs.s3a.connection.ssl.enabled=false \
--conf spark.sql.warehouse.dir=s3a://local-test/data
"
alias end_metastore="bash /opt/spark/sbin/stop-thriftserver.sh"