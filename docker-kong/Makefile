# Makefile
# Copyright (C) 2019 huangyongping <huangyongping@topsec.com.cn>
# Distributed under terms of the GPL license.

REPO=https://github.com/Kong/kong.git
TAG=1.0.3

IMAGE=topsec_kong:${TAG}
BASE_IMAGE=kong_base:${TAG}

.PHONY: base prod push

base:
	docker build -f ./Dockerfile.base -t ${BASE_IMAGE}  .

image:
	docker build -f ./Dockerfile -t ${IMAGE}  .

push:
	docker push ${IMAGE}
