FROM golang:latest

WORKDIR /go/src/app

RUN git clone --depth=1 --single-branch -b v0.12-dev https://github.com/hashicorp/terraform.git $GOPATH/src/github.com/hashicorp/terraform
#RUN cd $GOPATH/src/github.com/hashicorp/terraform && git checkout v0.12-dev && XC_OS=linux XC_ARCH=amd64 make bin
