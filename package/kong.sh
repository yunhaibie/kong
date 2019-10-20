#!/bin/bash

source_dir=$(cd `dirname $0`; pwd)

compose_file_temp=${source_dir}/docker-compose.yml

function usage(){
    echo "kong set up"
    echo "Usage: kong.sh install|uninstall|start|stop|status"
    info_echo "  kong.sh install"
}

function info_echo(){
    echo -e "\033[40;32m$1\033[0m"
}
#info_echo "黑底绿字"
function error_echo(){
    echo -e "\033[40;31m$1\033[0m"
}
#error_echo "错误信息"

function disable_selinux(){
    info_echo "Disable selinux"
    setenforce 0 >/dev/null 2>&1
    sed -i "s/SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config >/dev/null 2>&1
}

function check_docker_env(){
    # check_docker
    which docker >/dev/null 2>&1
    if [ $? ]; then
       # docker is no exists, install docker
       info_echo "Install docker rpm package"
       mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bk
       cd ${source_dir}/rpms
       yum install -y *.rpm
       mv /etc/yum.repos.d/CentOS-Base.repo.bk /etc/yum.repos.d/CentOS-Base.repo
       cd -
    fi
    # start docker
    info_echo "Start docker"
    systemctl enable docker >/dev/null 2>&1
    systemctl start docker

    # docker-compose is no exist, install it!
    which docker-compose >/dev/null 2>&1
    if [ $? ]; then
        info_echo "Install docker-compose"
        cp -rf ${source_dir}/tools/docker-compose /usr/local/bin/
        chmod +x /usr/local/bin/docker-compose
    fi
	# add docker monitor tools
	cp -rf ${source_dir}/tools/ctop /usr/local/bin
	chmod +x /usr/local/bin/ctop
}

function install(){
    info_echo "Checking kong runtime environment..."
    disable_selinux
    check_docker_env
    # loading docker images
    images=`echo $(ls ${source_dir}/images)`
    for image in ${images}
    do
	docker load < ${source_dir}/images/${image}
    done
    info_echo "Install vSecCenter images ok!"
    docker-compose up -d
    info_echo "Install success!"
    info_echo "Login kong-dashboard by http://IP:8080 "
}

function uninstall(){
    docker-compose down
    info_echo "uninstall success!"
}

function start(){
    docker-compose start
    info_echo "start success!"
}

function stop(){
    docker-compose stop
    info_echo "stop success!"
}

function restart(){
    docker-compose restart
    info_echo "restart success!"
}

function status(){
    docker-compose ps
}

case $1 in
   install)
     install
     exit 0
   ;;
   uninstall)
     uninstall
     exit 0
   ;;
   start)
     start
     exit 0
   ;;
   stop)
     stop
     exit 0
   ;;
   restart)
     restart
     exit 0
   ;;
   status)
     status
     exit 0
   ;;
   *)
     usage
     exit 1
   ;;
esac
