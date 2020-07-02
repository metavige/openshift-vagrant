#!/bin/bash

# Add nexus to hosts
LOCAL_NEXUS="nexus.docker.internal" && \
  grep -qF $LOCAL_NEXUS /etc/hosts || \
  echo "192.168.160.1 $LOCAL_NEXUS" >> /etc/hosts

REPO_LIST=$(cat <<END
  CentOS-Base.repo
  CentOS-fasttrack.repo
END
)

for repo in $REPO_LIST
do
    repo_file="/etc/yum.repos.d/$repo"
    # echo $repo
    sed -i 's/mirrorlist/#mirrorlist/g' "$repo_file"
    sed -i 's/^#baseurl=http:\/\/mirror.centos.org\/centos/baseurl=http:\/\/nexus.docker.internal\/repository\/yum-group/g' "$repo_file"
done
