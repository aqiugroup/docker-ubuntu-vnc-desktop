.PHONY: build run

# Default values for variables
# REPO  ?= dorowu/ubuntu-desktop-lxde-vnc
REPO  ?= aqiuxx/vnc-ros-noetic-full2
REPO_TEST  ?= aqiuxx/vnc-ros-noetic-full
TAG   ?= latest
# you can choose other base image versions
# IMAGE ?= ubuntu:20.04
IMAGE ?= osrf/ros:noetic-desktop-full

# IMAGE ?= nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
# choose from supported flavors (see available ones in ./flavors/*.yml)
FLAVOR ?= lxde
# armhf or amd64
ARCH ?= amd64

# These files will be generated from teh Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

# Rebuild the container image
build: $(templates)
	docker build -t $(REPO):$(TAG) .

# Test run the container
# the local dir will be mounted under /src read-only
run:
	docker run --privileged --rm \
		-p 6080:80 -p 6081:443 \
		-v ${PWD}:/src:ro \
		-e USER=aqiuxx -e PASSWORD=1 \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-e RELATIVE_URL_ROOT=approot \
		-e OPENBOX_ARGS="--startup /usr/bin/galculator" \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		-v /Users/aqiu/Documents/1_study/10_workspace/00_AllMyXX/AllMySlam/Slam-Course/slam_in_autonomous_driving:/home/aqiuxx/slam/sad \
		--device /dev/snd \
		--name vnc-ros-noetic-full-test \
		$(REPO_TEST):$(TAG)

# Connect inside the running container for debugging
shell:
	docker exec -it vnc-ros-noetic-full-test bash

# Generate the SSL/TLS config for HTTPS
gen-ssl:
	mkdir -p ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/nginx.key -out ssl/nginx.crt

clean:
	rm -f $(templates)

extra-clean:
	docker rmi $(REPO):$(TAG)
	docker image prune -f

# Run jinja2cli to parse Jinja template applying rules defined in the flavors definitions
%: %.j2 flavors/$(FLAVOR).yml
	docker run -v $(shell pwd):/data vikingco/jinja2cli \
		-D flavor=$(FLAVOR) \
		-D image=$(IMAGE) \
		-D localbuild=$(LOCALBUILD) \
		-D arch=$(ARCH) \
		$< flavors/$(FLAVOR).yml > $@ || rm $@
