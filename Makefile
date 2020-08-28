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

PROTOC_VERSION := 3.13.0

GO_PACKAGES := google.golang.org/protobuf/cmd/protoc-gen-go \
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
	protoc_zip=protoc-$(PROTOC_VERSION)-linux-x86_64.zip; \
	curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/$$protoc_zip; \
	sudo unzip -o $$protoc_zip -d /usr/local bin/protoc; \
	sudo unzip -o $$protoc_zip -d /usr/local 'include/*'; \
	rm -f $$protoc_zip
	for pkg in $(GO_PACKAGES); do \
		cd /tmp && GO111MODULE=on go get -v $$pkg; \
	done
	sudo chmod +x /usr/local/bin/protoc

gencode:
	git apply add-syntax-and-go_package.patch
	protoc -I ./openrtbadx --go_out=./openrtbadx --go-grpc_out=./openrtbadx $(OPENRTB_ADX_FILES)
	protoc -I ./networkbid --go_out=./networkbid --go-grpc_out=./networkbid $(NETWORK_BID_FILES)
	for dir in "openrtbadx" "networkbid"; do \
		cd $(CURRENT_DIR)/$$dir; \
		go mod tidy; \
	done
