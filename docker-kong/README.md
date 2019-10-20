# 使用Kong的源代码制作Kong镜像

直接通过Kong的源代码生成镜像，可以简化开发测试过程，避免繁琐的打包过程.

## 制作基础镜像

	make base

base镜像基于CentOS7，对应的Dockerfile是Dockerfile.base，在里面安装了kong依赖的openresty以及安装kong时用到的工具和依赖包。这里用的kong源码版本为1.0.3,基础镜像为kong_base:1.0.3
基础镜像制作：主要准备好kong源码编译所需环境，和参考不同的是基础镜像加入rockspec文件,这样制作出的基础镜像就可以拿到离线环境来制作kong源码镜像

## 制作Kong镜像

	make image

使用本目录中的Dockerfile，将Kong的源代码拷贝到base镜像中，在base镜像中完成安装。

## 使用方法
	1.创建kong-net网络
        docker network create kong-net 
    2.安装postgres数据库(还可以选择Apache Cassandra用来存储操作数据)
        docker run -d --name kong-database --network=kong-net -p 5432:5432 -e   "POSTGRES_USER=kong"  -e "POSTGRES_DB=kong" postgres:9.6
    3.初始化kong数据库
        *注意:kong  >=0.15.0以后数据库初始化命令:kong migrations bootstrap,之前版本命令:kong  migrations up*
        docker run --rm \
        --link kong-database:kong-database \
	--network kong-net \
        -e "KONG_DATABASE=postgres" \
        -e "KONG_PG_HOST=kong-database" \
        -e "KONG_PG_PASSWORD=your_pg_password" \
        -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
        topsec_kong:1.0.3  kong migrations bootstrap
        psql --host=127.0.0.1 --username=kong --password --dbname=kong 
    4.启动kong
		docker run -d --name kong \
		--link kong-database:kong-database \
		--network kong-net \
		-e "KONG_DATABASE=postgres" \
		-e "KONG_PG_HOST=kong-database" \
		-e "KONG_PG_PASSWORD=your_pg_password" \
		-e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
		-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
		-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
		-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
		-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
		-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
		-p 8000:8000 \
		-p 8443:8443 \
		-p 8001:8001 \
		-p 8444:8444 \
		topsec_kong:1.0.3
    5. 安装kong-dashboard 
		docker run --rm -p 8080:8080 --network=kong-net pgbi/kong-dashboard  start --kong-url  http://kong:8001
		这样就可以访问:http://IP:8080
