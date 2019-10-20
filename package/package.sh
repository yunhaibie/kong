#!/bin/bash

action=${1:-pack}
ver=${2:-1.0.1}

target_dir=/root/kong_pack

pack_dir=$(cd `dirname $0`; pwd)
cd ..
source_dir=$(cd `dirname $0`; pwd)
cd -

database_image=postgres:9.6

compose_file_temp=${pack_dir}/docker-compose.yml.template
compose_file=${target_dir}/docker-compose.yml

function info_echo(){
    echo -e "\033[40;32m$1\033[0m"
}
#info_echo "黑底绿字"
function error_echo(){
    echo -e "\033[40;31m$1\033[0m"
}
#error_echo "错误信息"

function usage(){
    echo "Kong packaging tool"
    echo "package.sh pack version"
}

function save_kong-database(){
    info_echo "save kong-database images start"
    docker save -o ${target_dir}/images/database.tar ${database_image}
    info_echo "save kong-database images end"
}

function save_kong(){
    info_echo "save kong images start"
    cd ${source_dir}/docker-kong
    make image TAG=${ver}
    docker save -o ${target_dir}/images/kong.tar topsec_kong:${ver}
    cd -
    info_echo "save kong images end"
}

function save_kong-dashboard(){
   info_echo "save kong-dashboard images start"
   docker save -o ${target_dir}/images/kong-dashboard.tar pgbi/kong-dashboard:latest
   info_echo "save kong-dashboard images end"
}

function copy_config_file(){
   info_echo "Copy all package files"
   [ -d ${target_dir} ] || mkdir -p ${target_dir}
   mkdir -p ${target_dir}/images
   mkdir -p ${target_dir}/rpms
   mkdir -p ${target_dir}/tools
   cp -r ${pack_dir}/rpms/*  ${target_dir}/rpms
   cp -r ${pack_dir}/tools/*  ${target_dir}/tools

   sed "s/KONG_VERSION/${ver}/g" ${compose_file_temp} > ${compose_file}  
   cp -r ${pack_dir}/kong.sh ${target_dir}
   info_echo "Copy all package files done!"
}

function package_all_file(){
   info_echo "Packaging all files"
   cd ${target_dir}
   tar zcf kong-${ver}.tgz *
   mv kong-${ver}.tgz ${pack_dir}
   cd -
   info_echo "Packaging all files done!"
}

case ${action} in
   pack)
     copy_config_file
     save_kong-database
     save_kong
     save_kong-dashboard
     package_all_file
   ;;
   -h|--help)
     usage
     exit 0
   ;;
   *)
     usage
     exit 1
   ;;
esac
