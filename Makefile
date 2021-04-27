SHELL := /bin/bash

CURRENT_DIR := $(shell pwd)
URL := https://developers.google.com/authorized-buyers/rtb/downloads/

# https://developers.google.com/authorized-buyers/rtb/openrtb-guide
# https://github.com/google/openrtb/blob/master/openrtb-core/src/main/protobuf/openrtb.proto
# https://github.com/google/openrtb-doubleclick/blob/master/doubleclick-openrtb/src/main/protobuf/openrtb-adx.proto
OPENRTB_ADX_FILES := "openrtb.proto" "openrtb-adx.proto"

# https://developers.google.com/authorized-buyers/rtb/realtime-bidding-guide
# https://github.com/google/openrtb-doubleclick/blob/master/doubleclick-core/src/main/protobuf/network-bid.proto
NETWORK_BID_FILES := "realtime-bidding.proto"

GO_PACKAGES := \
	google.golang.org/protobuf/cmd/protoc-gen-go \
	google.golang.org/grpc/cmd/protoc-gen-go-grpc

export PATH := $(shell go env GOPATH)/bin:$(PATH)

init:
	rm -fr openrtbadx networkbid
	mkdir -p {openrtbadx,networkbid}
	for dir in "openrtbadx" "networkbid"; do \
		cd $(CURRENT_DIR)/$$dir; \
		go mod init github.com/mechiru/authorized-buyers-proto/$$dir; \
	done

fetch:
	for proto in $(OPENRTB_ADX_FILES); do \
		file=$$(echo $$proto | sed -e 's!.proto!-proto.txt!'); \
		curl "$(URL)$${file}" -o ./openrtbadx/$$proto; \
	done
	for proto in $(NETWORK_BID_FILES); do \
		file=$$(echo $$proto | sed -e 's!.proto!-proto.txt!'); \
		curl "$(URL)$${file}" -o ./networkbid/$$proto; \
	done

install-gentool:
	for pkg in $(GO_PACKAGES); do \
		cd /tmp && GO111MODULE=on go get -v $$pkg; \
	done

gencode:
	cd ./openrtbadx && sed -i "1s!^!syntax = \"proto2\";\noption go_package = \"./;openrtbadx\";\n!" $(OPENRTB_ADX_FILES)
	cd ./networkbid && sed -i "1s!^!syntax = \"proto2\";\noption go_package = \"./;networkbid\";\npackage com.google.protos.adx;\n!" $(NETWORK_BID_FILES)
	protoc -I ./openrtbadx --go_out=./openrtbadx --go-grpc_out=./openrtbadx $(OPENRTB_ADX_FILES)
	protoc -I ./networkbid --go_out=./networkbid --go-grpc_out=./networkbid $(NETWORK_BID_FILES)
	for dir in "openrtbadx" "networkbid"; do \
		cd $(CURRENT_DIR)/$$dir; \
		go mod tidy; \
	done
