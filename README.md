
# Yugabyte cluster deployment on AWS

Best way to setup yugabyte db is to follow along instructions given at official documentation of yugabyte [here](https://docs.yugabyte.com/latest/deploy/public-clouds/aws/manual-deployment/#running-sample-workload). Below steps make it things simplified for runnging scripts from Mac. I have setup a cluster in AWS VPC with 3 nodes. Once I am done with yugabyte database installation, I created below script to run yugabyte and do different type of POCs. I will drop all of the resources so ip addresses used will not be relevant after I publish this code.

## Infrastructure used in aws:
   1. 3 x t3a.medium (2cpu, 4GB ram, 100GB SSD gp2) - For running YB-Master and YB-TServer
   2.	1 x t2.micro ( 1cpu, 1GB ram, 8GB SSD gp2) – For running load generation application


**This deployment has been broken into following files**

1.	[configfile.bash](/yb/) – All the environment variables were exported into this file including variables listed in official documentation.
2.	[setup_machine.bash](setup_machine.bash) – This file was used to load [configfile.bash]() and run through manual deployment steps listed in official documentation. Following tasks were performed to setup yugabyte universe
a.	Load environment variables
b.	Prepare/Configure/Mount data drives
c.	Install required & optional packages e.g., ntp
d.	Set uLimits
e.	Install Yugabyte DB
f.	Setup softlinks
g.	Configure master, tserver
h.	Start YB-Master using [start_master.bash](/yb/start_master.bash)
i.	Start YB-TServer using [start_tserver.bash](/yb/start_tserver.bash)
j.	Configure region aware placement - Optional (Did a mistake in configuring causing timeout when creating table)
k.	Set zone preference (Optional) – I did it since I created two nodes in AZ-2 and one in AZ-1
l.	Test `ybsql` using [test-pgsql.bash](/yb/test-pgsql.bash)
m.	Test `ybcsql` using [test-cassandra.bash](/yb/test-cassandra.bash)
n.	Configured prometheus using [yugabytedb.yml](/yb/yugabytedb.yml)
3.	[setup.bash](setup.bash) – This was used as a utility file to copy files between different nodes. Setting up cronjob. Installation of optional packages for debugging or testing.
4.	[start_master.bash](/yb/start_master.bash) – Script to start YB-Master on all of the nodes in a cluster
5.	[start_tserver.bash](/yb/start_tserver.bash) – Script to start YB-TServer on all of the nodes in a cluster
6.	[stopNdel.bash](/yb/stopNdel.bash) – Script to stop YB-Master and YB-TServer services on all the nodes in a cluster and delete data directory containing data.
7.	[yugabytedb.yml](/yb/yugabytedb.yml) – Prometheus configuration related settings
8.	[test-cassandra.bash](/yb/test-cassandra.bash) – Cassandra scripts to run on `ybcql` shell to test basic querying operations
9.	[test-pgsql.bash](/yb/est-pgsql.bash) – SQL script to run on `ybsql` shell to test and load Northwind database on the cluster. This file uses [northwind-ddl](/yb/northwind_ddl.sql) & [northwind-dml](/yb/northwind_data.sql) files for loading northwind database.

Upon running the load on Yugabyte cluster, [metrics](/metrics/) were collected which are published and uploaded with the repo itself.

**Logs for the execution are available at**
1. CPU utilization logs - [3.109.50.121](/metrics/3.109.50.121)
2. CPU utilization logs - [3.6.191.27](/metrics/3.6.191.27)
3. CPU utilization logs - [3.6.95.250](/metrics/3.6.95.250)
4. CPU utilization logs - [3.7.148.173](/metrics/3.7.148.173)
5. Parsed [CassandraKeyValue](/metrics/CassandraKeyValue-20211018-1710.log) logs
6. Parsed [CassandraBatchTimeseries](/metrics/CassandraBatchTimeseries-20211018-1810.log) logs
7. Original [CassandraKeyValue](/metrics/3.6.191.27/CassandraKeyValue-20211018-1710.txt) logs
8. Original [CassandraBatchTimeseries](/metrics/3.6.191.27/CassandraBatchTimeseries-20211018-1810.txt) logs


### **Detailed steps to setup yugabyte Db** (documentation in-progress)

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