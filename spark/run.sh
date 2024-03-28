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
SPARK_VERSION=3.4.2
SPARK_DIR="/spark/spark-${SPARK_VERSION}-bin-hadoop3"

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
$database_config
XML
}

generate_hive_site_config ${SPARK_DIR}/conf/hive-site.xml