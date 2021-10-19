for ip in $MASTER_NODES; do \
  echo =======Starting on $ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip \
    "~/master/bin/yb-master --flagfile ~/yb-conf/master.conf \
      >& /mnt/d0/yb-master.out &"; \
done

for ip in $MASTER_NODES; do  \
  echo =======Verifying on $ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip ps auxww | grep yb-master; \
done