# Makefile to manage build scripts
# vim: ts=4

export SHELL := /bin/bash
export PATH  := ./bin:$(PATH)

# this will select the root dir of the makefile as build root
export BUILD_ROOT:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all config build clean clean_env clean_box clean_cloud cloud_version \
        distfiles init startup test parent_version upload vagrant_cloud_token \
        version help readme clean_temp install download

## show help
help:
	@printf "Usage: \033[1mmake <target>\033[0m \n\n"
	@printf "The following targets are available: \n"
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
	@printf "\nEnvironment settings:\nBUILD_ROOT: \033[1m$$BUILD_ROOT\033[0m\n"
	@printf "\nPlease consult \033[1mmake readme\033[0m for additional notes.\n"

## show readme file
readme:
	@pandoc -f markdown -t asciidoc "./README.md"

## clean environment and build a new box
all: clean_env build

## show current configuration
config:
	@config.sh

## build a raw box
build:
	@build.sh

## install as local vagrant box
install:
	@install.sh

## remove any build and temporary created files
clean:
	@clean.sh

## remove only temporary created files
clean_temp:
	@clean_temp.sh

## cleanup whole environment (cleanup virtual machines, vagrant and clean build)
clean_env:
	@clean_env.sh

## cleanup vagrant environment
clean_box:
	@clean_box.sh

## tidy cloud boxes, delete old ones
clean_cloud:
	@clean_cloud.sh

## show all cloud box versions
cloud_version:
	@cloud_version.sh

## download and verify distfiles (from distfiles.list)
distfiles:
	@distfiles.sh

## initialize a new box from build
init:
	@init.sh

## startup an initialized box
startup:
	@startup.sh

## quick test a built box for bootability
test:
	@test.sh

## print parent version from vagrant cloud
parent_version:
	@parent_version.sh

## download box from vagrant cloud
download:
	@download.sh

## upload a built box to vagrant cloud
upload:
	@upload.sh

## load token or request a new one
vagrant_cloud_token:
	@vagrant_cloud_token.sh

## determine and print box version
version:
	@version.sh
