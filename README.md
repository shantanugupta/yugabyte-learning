
Best way to setup yugabyte db is to follow along instructions given at official documentation of yugabyte [here](https://docs.yugabyte.com/latest/deploy/public-clouds/aws/manual-deployment/#running-sample-workload). Below steps make it things simplified for runnging scripts from Mac. I have setup a cluster in AWS VPC with 3 nodes. Once I am done with yugabyte database installation, I created below script to run yugabyte and do different type of POCs. I will drop all of the resources so ip addresses used will not be relevant after I publish this code.

Once you have setup all the nodes, attached storage disks, file system

# Steps to setup yugabyte Db

1. Go to directory where step.bash is present.
   ```
   cd /Users/shangupta/Documents/git/aws-cfm
   ```

2. Execute [setup.bash](setup.bash) to configure all environment variables required throughout the process
   ```
   ./setup.bash
   ```

3. Login to any one AZ machine from your local machine
   ```
   ssh -i $PEM centos@3.6.95.250
   ```

4. Go to yb directory where all the scripts are present
    ```
    cd ./yb
    ```
5. Start all master nodes by calling [start_master.bash](start_master.bash)
   ``` 
   echo "=====Start Master nodes====="
   ./start_master.bash
   ```
6. Start all tserver nodes by calling [start_tserver.bash](start_tserver.bash)
   ``` 
   echo "=====Start TServer nodes====="
   ./start_tserver.bash
   ```


#links http://$MASTER1:7000/



#curl -s http://$MASTER1:7000/cluster-config

Get into ysql shell

```
ysqlsh -h 10.0.1.155
```

Test SQL Scripts with [Northwind database](https://blog.yugabyte.com/how-to-the-northwind-postgresql-sample-database-running-on-a-distributed-sql-database/
)

```   
CREATE DATABASE northwind;
\l -- list all databases
\c northwid -- switch to default db as northwind
\i ~/yg/northwind_ddl.sql
\d -- verify all tables
\i ~/yg/northwind_ddl.sql
\i /yg/northwind_data.sql
SELECT * FROM customers LIMIT 2;
```

Run load generation one by one

```
java -jar yb-sample-apps.jar --workload CassandraKeyValue --nodes 10.0.0.66:9042
java -jar yb-sample-apps.jar --workload CassandraBatchTimeseries --nodes 10.0.0.66:9042
java -jar yb-sample-apps.jar --workload SqlInserts --nodes 10.0.0.66:9042
```

Capture metrics into a file
```
#grep com.yugabyte.sample.common.metrics.MetricsTracker a.txt | cut --fields 2-5  -d "|" | cut --fields 4,6,8  -d " "
```

Setup Prometheus for monitoring
```
wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz
tar xvfz prometheus-*
cd prometheus-*
./prometheus --config.file=../yugabytedb.yml
```