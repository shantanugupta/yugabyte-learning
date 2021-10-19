for ip in $ALL_NODES; do \
  echo =======Starting on $ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip \
    "~/tserver/bin/yb-tserver --flagfile ~/yb-conf/tserver.conf \
      >& /mnt/d0/yb-tserver.out &"; \
done

for ip in $ALL_NODES; do  \
  echo =======Verifying on $ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip ps auxww | grep yb-tserver; \
done