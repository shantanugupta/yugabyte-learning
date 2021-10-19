echo "----------------Load environment variables----------------"
. ./yb/configfile.bash

echo "----------------Prepare data drives--------------------"
for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip lsblk; \
done

for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip sudo umount /mnt/d0;
   ssh -i $PEM $ADMIN_USER@$ip sudo /sbin/mkfs.xfs /dev/nvme1n1 -f; \
done

for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip sudo /sbin/blkid -o value -s TYPE -c /dev/null /dev/nvme1n1; \
done

echo "----------------Configure Drives--------------------"
for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip \
      sudo "echo '/dev/nvme1n1 /mnt/d0 xfs defaults,noatime,nofail,allocsize=4m 0 2' | sudo tee -a /etc/fstab"; \
done

for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip cat /etc/fstab | grep xfs; \
done

echo "----------------Mount Drives--------------------"
for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip sudo mkdir -p /mnt/d0; \
    ssh -i $PEM $ADMIN_USER@$ip sudo mount /mnt/d0; \
    ssh -i $PEM $ADMIN_USER@$ip sudo chmod 777 /mnt/d0; \
done

for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip df -kh | grep mnt; \
done

echo "----------------Verify system configuration--------------------"

echo "---Install various packages like ntp, iostats, netstat etc---"
for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip sudo yum install -y epel-release ntp; \
done

for ip in $ALL_NODES; do \
     echo =======$ip=======; \
     ssh -i $PEM $ADMIN_USER@$ip sudo yum install -y perf sysstat net-tools links; \
done

echo "----------------Set ulimits--------------------"
for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip sudo "echo '*       -       core    unlimited' | sudo tee -a /etc/security/limits.conf"; \
   ssh -i $PEM $ADMIN_USER@$ip sudo "echo '*       -       nofile  1048576' | sudo tee -a /etc/security/limits.conf"; \
   ssh -i $PEM $ADMIN_USER@$ip sudo "echo '*       -       nproc   12000' | sudo tee -a /etc/security/limits.conf"; \
done

for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip sudo "echo '*       -       nproc   12000' | sudo tee -a /etc/security/limits.d/20-nproc.conf"; \
done

for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip ulimit -n -u -c; \
done


echo "---------------- Install YugabyteDB --------------------"
for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip mkdir -p ~/yb-software; \
    ssh -i $PEM $ADMIN_USER@$ip mkdir -p ~/yb-conf; \
done

for ip in $ALL_NODES; do \
   echo =======$ip=======; \
   ssh -i $PEM $ADMIN_USER@$ip \
      "cd ~/yb-software; \
       curl -k -o yugabyte-${YB_VERSION}-linux.tar.gz \
         https://downloads.yugabyte.com/yugabyte-${YB_VERSION}-linux.tar.gz"; \
   ssh -i $PEM $ADMIN_USER@$ip \
      "cd ~/yb-software; \
       tar xvfz yugabyte-${YB_VERSION}-linux.tar.gz"; \
   ssh -i $PEM $ADMIN_USER@$ip \
       "cd ~/yb-software/yugabyte-${YB_VERSION}; \
        ./bin/post_install.sh"; \
done

echo "---------------- Create ~/master & ~/tserver directories as symlinks -----------------"
for ip in $MASTER_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip \
      "ln -s ~/yb-software/yugabyte-${YB_VERSION} ~/master"; \
done

for ip in $ALL_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip \
      "ln -s ~/yb-software/yugabyte-${YB_VERSION} ~/tserver"; \
done

echo "---------------- Create YB-Master1 configuration file -----------------"
(MASTER=$MASTER1; CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1a; CONFIG_FILE=~/yb-conf/master.conf ;\
  ssh -i $PEM $ADMIN_USER@$MASTER "
    echo --master_addresses=$MASTER_RPC_ADDRS    > $CONFIG_FILE
    echo --fs_data_dirs=$DATA_DIRS              >> $CONFIG_FILE
    echo --rpc_bind_addresses=$MASTER:7100      >> $CONFIG_FILE
    echo --webserver_interface=$MASTER          >> $CONFIG_FILE
    echo --placement_cloud=$CLOUD               >> $CONFIG_FILE
    echo --placement_region=$REGION             >> $CONFIG_FILE
    echo --placement_zone=$AZ                   >> $CONFIG_FILE
"
);

echo "---------------- Create YB-Master2 configuration file -----------------"
(MASTER=$MASTER2; CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1b; CONFIG_FILE=~/yb-conf/master.conf ;\
  ssh -i $PEM $ADMIN_USER@$MASTER "
    echo --master_addresses=$MASTER_RPC_ADDRS    > $CONFIG_FILE
    echo --fs_data_dirs=$DATA_DIRS              >> $CONFIG_FILE
    echo --rpc_bind_addresses=$MASTER:7100      >> $CONFIG_FILE
    echo --webserver_interface=$MASTER          >> $CONFIG_FILE
    echo --placement_cloud=$CLOUD               >> $CONFIG_FILE
    echo --placement_region=$REGION             >> $CONFIG_FILE
    echo --placement_zone=$AZ                   >> $CONFIG_FILE
"
);
echo "---------------- Create YB-Master3 configuration file -----------------"
(MASTER=$MASTER3; CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1b; CONFIG_FILE=~/yb-conf/master.conf ;\
  ssh -i $PEM $ADMIN_USER@$MASTER "
    echo --master_addresses=$MASTER_RPC_ADDRS    > $CONFIG_FILE
    echo --fs_data_dirs=$DATA_DIRS              >> $CONFIG_FILE
    echo --rpc_bind_addresses=$MASTER:7100      >> $CONFIG_FILE
    echo --webserver_interface=$MASTER          >> $CONFIG_FILE
    echo --placement_cloud=$CLOUD               >> $CONFIG_FILE
    echo --placement_region=$REGION             >> $CONFIG_FILE
    echo --placement_zone=$AZ                   >> $CONFIG_FILE
"
);

echo "---------------- Verify Master configuration files -----------------"
for ip in $MASTER_NODES; do \
  echo =======$ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip cat ~/yb-conf/master.conf; \
done

(CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1a; CONFIG_FILE=~/yb-conf/tserver.conf; \
 for ip in $AZ1_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip "
      echo --tserver_master_addrs=$MASTER_RPC_ADDRS            > $CONFIG_FILE
      echo --fs_data_dirs=$DATA_DIRS                          >> $CONFIG_FILE
      echo --rpc_bind_addresses=$ip:9100                      >> $CONFIG_FILE
      echo --cql_proxy_bind_address=$ip:9042                  >> $CONFIG_FILE
      echo --redis_proxy_bind_address=$ip:6379                >> $CONFIG_FILE
      echo --webserver_interface=$ip                          >> $CONFIG_FILE
      echo --placement_cloud=$CLOUD                           >> $CONFIG_FILE
      echo --placement_region=$REGION                         >> $CONFIG_FILE
      echo --placement_zone=$AZ                               >> $CONFIG_FILE
      echo --pgsql_proxy_bind_address=$ip:5433                >> $CONFIG_FILE
    "
 done
);

(CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1b; CONFIG_FILE=~/yb-conf/tserver.conf; \
 for ip in $AZ2_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip "
      echo --tserver_master_addrs=$MASTER_RPC_ADDRS            > $CONFIG_FILE
      echo --fs_data_dirs=$DATA_DIRS                          >> $CONFIG_FILE
      echo --rpc_bind_addresses=$ip:9100                      >> $CONFIG_FILE
      echo --cql_proxy_bind_address=$ip:9042                  >> $CONFIG_FILE
      echo --redis_proxy_bind_address=$ip:6379                >> $CONFIG_FILE
      echo --webserver_interface=$ip                          >> $CONFIG_FILE
      echo --placement_cloud=$CLOUD                           >> $CONFIG_FILE
      echo --placement_region=$REGION                         >> $CONFIG_FILE
      echo --placement_zone=$AZ                               >> $CONFIG_FILE
      echo --pgsql_proxy_bind_address=$ip:5433                >> $CONFIG_FILE
    "
 done
);

(CLOUD=aws; REGION=ap-south-1; AZ=ap-south-1b; CONFIG_FILE=~/yb-conf/tserver.conf; \
 for ip in $AZ3_NODES; do \
    echo =======$ip=======; \
    ssh -i $PEM $ADMIN_USER@$ip "
      echo --tserver_master_addrs=$MASTER_RPC_ADDRS            > $CONFIG_FILE
      echo --fs_data_dirs=$DATA_DIRS                          >> $CONFIG_FILE
      echo --rpc_bind_addresses=$ip:9100                      >> $CONFIG_FILE
      echo --cql_proxy_bind_address=$ip:9042                  >> $CONFIG_FILE
      echo --redis_proxy_bind_address=$ip:6379                >> $CONFIG_FILE
      echo --webserver_interface=$ip                          >> $CONFIG_FILE
      echo --placement_cloud=$CLOUD                           >> $CONFIG_FILE
      echo --placement_region=$REGION                         >> $CONFIG_FILE
      echo --placement_zone=$AZ                               >> $CONFIG_FILE
      echo --pgsql_proxy_bind_address=$ip:5433                >> $CONFIG_FILE
    "
 done
);

echo "---------------- Verify TSERVER configuration files -----------------"
for ip in $ALL_NODES; do \
  echo =======$ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip cat ~/yb-conf/tserver.conf; \
done

echo "---------------- Start masters and verify -----------------"
chmod 777 ./yb/start_master.bash
./yb/start_master.bash

echo "---------------- Start tservers and verify -----------------"
chmod 777 ./yb/start_tserver.bash
./yb/start_tserver.bash

echo "---------------- Configure AZ- and region-aware placement -----------------"

ssh -i $PEM $ADMIN_USER@$MASTER1 \
   ~/master/bin/yb-admin --master_addresses $MASTER_RPC_ADDRS \
    modify_placement_info  \
    aws.ap-south-1.ap-south-1a,aws.ap-south-1.ap-south-1b 3

echo "---------------- Set zone preference -----------------"

ssh -i $PEM $ADMIN_USER@$MASTER1 \
   ~/master/bin/yb-admin --master_addresses $MASTER_RPC_ADDRS \
    set_preferred_zones  \
    aws.ap-south-1.ap-south-1b

echo "---------------- Test PostgreSQL-compatible YSQL API -----------------"
chmod 777 ./yb/test-pgsql.bash
./yb/test-pgsql.bash

echo "---------------- Test Cassandra-compatible YCQL API -----------------"
chmod 777 ./yb/test-cassandra.bash
./yb/test-cassandra.bash

echo "---------------- Running sample workload -----------------"
export CIP_ADDR=10.0.0.66:9042

jar=./yb-sample-apps.jar
CassandraKeyValueLog="/home/centos/yb/metrics/CassandraKeyValue-$(date "+%Y%m%d-%H%m").txt"
java -jar $jar --workload CassandraKeyValue --nodes 10.0.0.66:9042 >> $CassandraKeyValueLog & 

CassandraBatchTimeseriesLog="/home/centos/yb/metrics/CassandraBatchTimeseries-$(date "+%Y%m%d-%H%m").txt"
java -jar $jar --workload CassandraBatchTimeseries --nodes 10.0.0.66:9042 >> $CassandraBatchTimeseriesLog &

SqlInsertsLog="/home/centos/yb/metrics/SqlInserts-$(date "+%Y%m%d-%H%m").txt"
java -jar $jar --workload SqlInserts --nodes 10.0.0.66:9042 >> $SqlInsertsLog &

wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz
tar xvfz prometheus-*
cd prometheus-*
./prometheus-*/prometheus --config.file=/home/centos/yb/yugabytedb.yml &

#link 3.6.95.250:9090
#http://3.6.95.250:9090/graph
#http://3.6.95.250:9090/metrics

for f in Cassandra*.txt; do
    parsed="Parsed-$f.log";
    search="com.yugabyte.sample.common.metrics.MetricsTracker"
    echo "R-ops/s R-ms/ops total-R-ops W-ops/s W-ms/ops total-W-ops Uptime-ms maxWrittenKey maxGeneratedKey"> $parsed
    grep $search $f | cut -f8,10,12,19,21,23,30,34,37 -d " " | tr  -d "(" >> $parsed
done

for f in cpu_usage*.txt; do
    parsed="Parsed-$f.log";
    search="all"
    echo "datetime,CPU,%user,%nice,%system,%iowait,%steal,%idle" > $parsed
    grep $search $f | tr -s " " "," | cut -f1-8 -d "," >> $parsed
done