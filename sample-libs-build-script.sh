#!/bin/bash

echo $HOME
BASE_DIR=$PWD
ROOT_PWD=$1
CLONE_REPO=$2
REPO_DIR="librepos"
INCLUDE_DIR="$HOME/development/axp/nextgen/3rdparty/include"
LIB_DIR="$HOME/development/axp/nextgen/3rdparty/lib"
mkdir -p "$HOME/development/axp/nextgen/3rdparty/include"
mkdir -p "$HOME/development/axp/nextgen/3rdparty/lib"
mkdir -p $REPO_DIR

libdeflate_git_tag="v1.9"
uWebSockets_git_tag="v20.9.0"
fmt_git_tag="8.1.1"
folly_git_tag="v2021.08.30.00"
abseil_git_tag="20211102.0"
protobuf_git_tag="v3.19.3"
grpc_git_tag="v1.44.0-pre1"
thrift_git_tag="v0.14.1"
prometheus_git_tag="v1.0.0"
otlp_git_tag="v0.12.0"
opentelemetry_git_tag="v1.0.0"

cloneLibRepo(){
	git -C librepos clone $1
}

checkoutTag(){
	git --git-dir=$BASE_DIR/$REPO_DIR/$1/.git --work-tree=$BASE_DIR/$REPO_DIR/$1 checkout $2 -b $2
}

executeMakeCommand(){
	make -C $BASE_DIR/$REPO_DIR/$1
}

executeMakeInstall(){
	echo $ROOT_PWD | sudo -S make install -C $BASE_DIR/$REPO_DIR/$1
}

cloneSubModules(){
	git -C $BASE_DIR/$REPO_DIR/$1 submodule update --init --recursive
} 

cloneCheckoutRepo(){
        cloneLibRepo $1
        checkoutTag $2 $3
        
        #clone submodule
        if [ $4 ]; then
        	cloneSubModules $2
        fi
}

copyFiles(){
	if [ $3 ]; then
        	echo $ROOT_PWD | sudo -S cp $1 $2
        else
        	cp $1 $2
        fi
} 

installPreLibs(){
	arr=("$@")
	for i in ${arr[@]}; do
  		echo $ROOT_PWD | sudo -S dnf install $i -y
	done
}

executeCMake(){
	cmake -S $BASE_DIR/$REPO_DIR/$1 -B $BASE_DIR/$REPO_DIR/$1
}

executeCMakeBuild(){
	cmake --build $BASE_DIR/$REPO_DIR/$1
}

buildInstallFollyPreLibs(){
	OLDPATH=$PWD
	cd $BASE_DIR/$REPO_DIR/$1
	echo $ROOT_PWD | sudo -S ./build/fbcode_builder/getdeps.py install-system-deps --recursive
	python3 ./build/fbcode_builder/getdeps.py --allow-system-packages build
	cd $OLDPATH
}

runBashFile(){
	OLDPATH=$PWD
	cd $BASE_DIR/$REPO_DIR/$1
	./$2 $3
	cd $OLDPATH
}

runLdConfig(){
	OLDPATH=$PWD
	cd $BASE_DIR/$REPO_DIR/$1
	echo $ROOT_PWD | sudo -s ldconfig
	cd $OLDPATH
}

#install pre libraries
preLibs=("python3" "cmake" "g++" "git-all" "zlib-devel" "auto-make" "openssl" "openssl-devel" "double-conversion-static" "glog-devel" "libunwind-devel" "libtool" "bison" "flex" "byacc" "libcurl" "curl" "libcurl-devel" "gtest-devel" "google-benchmark-devel" "cxxopts-devel")
installPreLibs "${preLibs[@]}"

##uWebsockets
if [ $CLONE_REPO ]; then
	cloneCheckoutRepo "https://github.com/uNetworking/uWebSockets.git" "uWebSockets" $uWebSockets_git_tag true
fi
executeMakeCommand "uWebSockets" 
executeMakeInstall "uWebSockets"
copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/uSockets/uSockets.a $LIB_DIR/libuSockets.a false
copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/src/* $INCLUDE_DIR false
copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/uSockets/src/libusockets.h $INCLUDE_DIR false
copyFiles $BASE_DIR/$REPO_DIR/uWebSockets/uSockets/src/libusockets.h /usr/local/include/uWebSockets true


echo $BASE_DIR
echo "----------------------------- dependencies installed successfully -------------------"
#this is final script
#sh build_shell_script.sh pkk123 true
