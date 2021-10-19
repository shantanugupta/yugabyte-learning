for ip in $ALL_NODES; do \
  echo =======$ip=======; \
  ssh -i $PEM $ADMIN_USER@$ip pkill yb-master; \
  ssh -i $PEM $ADMIN_USER@$ip pkill yb-tserver; \
  # This assumes /mnt/d0 was the only data dir used on each node. \
  ssh -i $PEM $ADMIN_USER@$ip rm -rf /mnt/d0/yb-data/*; \
done
