#!/bin/bash
sudo -i
yum install -y redhat-lsb-core wget rpmdevtools rpm-build pcre-devel openssl-devel createrepo yum-utils gcc
cd /root
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
rpm -i nginx-1.*
cd /root/rpmbuild
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xvf /root/rpmbuild/openssl-1.1.1w.tar.gz
rm /root/rpmbuild/openssl-1.1.1w.tar.gz
sed -i 's/--with-debug/--with-openssl=\/root\/rpmbuild\/openssl-1.1.1w/g' /root/rpmbuild/SPECS/nginx.spec
yum-builddep /root/rpmbuild/SPECS/nginx.spec
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
file=`ls -l /root/rpmbuild/RPMS/x86_64/ | grep nginx-1.20`
if ! [[ "$file" ]] 
then 
exit 
fi
namefile=`echo $file | awk '{print $9}'`
yum localinstall -y /root/rpmbuild/RPMS/x86_64/$namefile
systemctl start nginx
systemctl enable nginx

# Создание репо
rm /usr/share/nginx/html/*
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/$namefile /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
createrepo /usr/share/nginx/html/repo/
sed -i '/index  index.html index.htm;/s/$/ \n\tautoindex on;/' /etc/nginx/conf.d/default.conf
nginx -s reload
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
yum install percona-orchestrator.x86_64 -y
yum clean all
createrepo --update /usr/share/nginx/html/repo/
echo FINISH
