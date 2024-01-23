# ДЗ: Размещаем свой RPM в своем репозитории
-----------------------------------------------------------------------
### Домашнее задание

    Размещаем свой RPM в своем репозитории
    Цель: Часто в задачи администратора входит не только установка пакетов, но и сборка и поддержка собственного репозитория. Этим и займемся в ДЗ.
    1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
    2) создать свой репо и разместить там свой RPM
    реализовать это все либо в Vagrant, либо развернуть у себя через nginx и дать ссылку на репо 

    

##### Стенд со всеми этими операциями собирается в автоматическом режиме - [файл вагрант] и [сам скрипт].

1. Создание своего RPM
- Первым делом устанавливаем пакеты: ```yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc```
- Скачиваем src.rpm - ```wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm```
- При использовании этой команды с параметром -i, распаковываются src и spec файл: ```rpm -i nginx-1.*```
- Также нужно скачать и разархивировать последний исходники для openssl - он потребуется при сборке для этого переходим в каталог /root/rpmbuild
```
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xvf openssl-1.1.1w.tar.gz
```
- Переходим в каталог rpmbuild:
```
drwxr-xr-x. 3 root root   26 Aug 27 13:49 BUILD
drwxr-xr-x. 2 root root    6 Aug 27 13:51 BUILDROOT
drwxr-xr-x. 3 root root   20 Aug 27 13:51 RPMS
drwxr-xr-x. 2 root root 4096 Aug 27 13:46 SOURCES
drwxr-xr-x. 2 root root   24 Aug 27 13:46 SPECS
drwxr-xr-x. 2 root root    6 Aug 27 13:47 SRPMS
```
В папке SPECS лежит spec-файл. Файл, который описывает что и как собирать.
- Открываем файл ```vi SPECS/nginx.spec``` и добавляем в секцию %build необходимый нам модуль OpenSSL:
```
%build
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-openssl=/root/rpmbuild/openssl-1.1.1w
make %{?_smp_mflags}
%{__mv} %{bdir}/objs/nginx \
    %{bdir}/objs/nginx-debug
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}"
make %{?_smp_mflags}
```
- Устанавливаем зависимости - ```yum-builddep SPECS/nginx.spec```
- Собираем - ```rpmbuild -bb SPECS/nginx.spec```
- Видим два собранных пакета:
```
[root@lvm repo]# ls -l  /root/rpmbuild/RPMS/x86_64/
total 2796
-rw-r--r--. 1 root root 2060932 Jan 23 14:43 nginx-1.20.2-1.el8.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2495792 Jan 23 14:43 nginx-debuginfo-1.20.2-1.el8.ngx.x86_64.rpm
```
- Устанавливаем rpm пакет: ```yum localinstall -y RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm```
- Запускаем nginx - ```systemctl start nginx``` и можем посмотреть с какими параметрами nginx был скомпилирован ```nginx -V```

Также стоит отметить, что nginx можно собрать через ```./configure && make && make install```. [Ссылка на мануал].

2. Создаем свой репозиторий
- Создаем папку в / нашего nginx - ```mkdir /usr/share/nginx/html/repo```
- Копируем наш скомпилированный пакет nginx в папку с будущим репозиторием - ```cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/```
- Скачиваем дополнительно пакет - ```wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm```
- Создаем репозиторий - ```createrepo /usr/share/nginx/html/repo/``` и ```createrepo --update /usr/share/nginx/html/repo/```
- В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:
```
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on; Добавили эту директиву
}
```
- Проверяем синтаксис ```nginx -t``` и ```nginx -s reload```
- Теперь можем просмотреть наши пакеты через HTTP - ```lynx http://localhost/repo/``` или ```curl -a http://localhost/repo/```
- Теперь чтобы протестировать репозиторий - создаем файл ``` /etc/yum.repos.d/otus.repo``` и вписываем в него следующее:
```
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
```
- Можем посмотреть подключенный репозиторий - ```yum repolist enabled | grep otus``` и ```yum list | grep otus``` или ```yum list --showduplicates | grep otus```
```
[root@lvm repo]# yum list --showduplicates | grep otus
otus-linux                                       52 kB/s | 3.0 kB     00:00    
otus-linux                                      109 kB/s | 2.8 kB     00:00    
percona-orchestrator.x86_64                     2:3.2.6-2.el8         @otus        
percona-orchestrator.x86_64                     2:3.2.6-2.el8         otus         
[root@lvm repo]# yum list | grep otus
ppercona-release.noarch                      0.1-6                      @otus
```
Важно: в случае когда мы удаляем или добавляем пакеты в наш репозиторий, нам необходимо выполнить ```createrepo <наш репозиторий>``` и ```createrepo --update <наш репозиторий>```, 
после чего на всякий случай можем выполнить ```yum clean all``` и теперь ```yum list --showduplicates | grep otus```

[Ссылка на мануал]:https://www.howtoforge.com/how-to-build-nginx-from-source-on-centos-7/
