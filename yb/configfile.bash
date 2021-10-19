# Suppose these are the IP addresses of your 6 machines
# (say 2 in each AZ).
export AZ1_NODES="10.0.0.66"
export AZ2_NODES="10.0.1.155"
export AZ3_NODES="10.0.1.108"

# Version of YugabyteDB you plan to install.
#export YB_VERSION=2.3.3.0
export YB_VERSION=2.9.0.0

# Comma separated list of directories available for YB on each node
# In this example, it is just 1. But if you have two then the RHS
# will be something like /mnt/d0,/mnt/d1.
export DATA_DIRS=/mnt/d0

# PEM file used to access the VM/instances over SSH.
# If you are not using pem file based way of connecting to machines,
# you’ll need to replace the “-i $PEM” ssh option in later
# commands in the document appropriately.
export PEM=~/.ssh/yugabyte.pem

# We’ll assume this user has sudo access to mount drives that will
# be used as data directories for YugabyteDB, install xfs (or ext4
# or some reasonable file system), update system ulimits etc.
#
# If those steps are done differently and your image already has
# suitable limits and data directories for YugabyteDB to use then
# you may not need to worry about those steps.
export ADMIN_USER=centos

# We need three masters if Replication Factor (RF=3)
# Take one node or the first node from each AZ to run yb-master.
# (For single AZ deployments just take any three nodes as
# masters.)
#
# You don’t need to CHANGE these unless you want to customize.
export MASTER1=`echo $AZ1_NODES | cut -f1 -d" "`
export MASTER2=`echo $AZ2_NODES | cut -f1 -d" "`
export MASTER3=`echo $AZ3_NODES | cut -f1 -d" "`


# Other Environment vars that are simply derived from above ones.
export MASTER_NODES="$MASTER1 $MASTER2 $MASTER3"
export MASTER_RPC_ADDRS="$MASTER1:7100,$MASTER2:7100,$MASTER3:7100"

# yb-tserver will run on all nodes
# You don’t need to change these
export ALL_NODES="$AZ1_NODES $AZ2_NODES $AZ3_NODES"
export TSERVERS=$ALL_NODES

# The binary that you will use
export TAR_FILE=yugabyte-${YB_VERSION}-linux.tar.gz

export tsbin="/home/$ADMIN_USER/tserver/bin/"
export PATH=$PATH:$tsbin; 
