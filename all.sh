#!/bin/bash
#
# Copyright 2017 Liu Hongyu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
OPENSHIFT_RELEASE="$1"
# bash -c 'echo "export TZ=Asia/Taipei" > /etc/profile.d/tz.sh'

# update nexus yum source
/vagrant/nexus.sh

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

useradd dockerusr -u 100000 -U
groupmod dockerusr -g 100000
echo "dockerusr:100000:65536" >> /etc/subuid
echo "dockerusr:100000:65536" >> /etc/subgid

yum -y install docker
usermod -aG dockerroot vagrant
usermod -aG dockerroot dockerusr
cat > /etc/docker/daemon.json <<EOF
{
    "group": "dockerroot",
    "userns-remap": "dockerusr:dockerusr",
    "registry-mirrors": ["http://nexus.docker.internal"]
}
EOF

systemctl enable docker
systemctl start docker

# Sourcing common functions
. /vagrant/common.sh

# ocp repos
REPO_LIST=$(cat <<END
    CentOS-OpenShift-Origin311.repo
    CentOS-ANSIBLE.repo
END
)

# Fix missing packages for openshift origin 3.11.0
# https://lists.openshift.redhat.com/openshift-archives/dev/2018-November/msg00005.html
if [ "$(version ${OPENSHIFT_RELEASE})" -eq "$(version 3.11)" ]; then
    yum install -y centos-release-openshift-origin311

    for repo in $REPO_LIST
    do
        repo_file="/etc/yum.repos.d/$repo"
        # replace repo
        sed -i 's/^mirrorlist/#mirrorlist/g' "$repo_file"
        sed -i 's/^#baseurl=http:\/\/mirror.centos.org\/\$contentdir/baseurl=http:\/\/nexus.docker.internal\/repository\/yum-group/g' "$repo_file"
        sed -i 's/^baseurl=http:\/\/mirror.centos.org\/centos/baseurl=http:\/\/nexus.docker.internal\/repository\/yum-group/g' "$repo_file"
    done
fi
