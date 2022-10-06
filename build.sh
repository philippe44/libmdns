#!/bin/bash

list="x86_64-linux-gnu-gcc x86-linux-gnu-gcc arm-linux-gnueabi-gcc aarch64-linux-gnu-gcc sparc64-linux-gnu-gcc mips-linux-gnu-gcc powerpc-linux-gnu-gcc"
declare -A alias=( [x86-linux-gnu-gcc]=i686-linux-gnu-gcc )
declare -A cflags=( [sparc64-linux-gnu-gcc]="-mcpu=v7" [mips-linux-gnu-gcc]="-march=mips32" [powerpc-linux-gnu-gcc]="-m32")
declare -a compilers

IFS= read -ra candidates <<< "$list"

# do we have "clean" somewhere in parameters (assuming no compiler has "clean" in it...
if [[ $@[*]} =~ clean ]]; then
	clean="clean"
fi	

# first select platforms/compilers
for cc in ${candidates[@]}
do
	# check compiler first
	if ! command -v ${alias[$cc]:-$cc} &> /dev/null; then
		continue
	fi
	
	if [[ $# == 0 || ($# == 1 && -n $clean) ]]; then
		compilers+=($cc)
		continue
	fi

	for arg in $@
	do
		if [[ $cc =~ $arg ]]; then 
			compilers+=($cc)
		fi
	done
done

declare -a items=( mdnssd tinysvcmdns )
declare -a tinysvcmdns=( tinysvcmdns.h )
declare -a mdnssd=( mdnssd.h )

# then iterate selected platforms/compilers
for item in ${items[@]}
do
	for cc in ${compilers[@]}
	do
		IFS=- read -r platform host dummy <<< $cc
	
		export CFLAGS=${cflags[$cc]}
	
		pwd=$(pwd)
		cd $item
		make CC=${alias[$cc]:-$cc} PLATFORM=$platform $clean
		cd $pwd
		if [[ -n $clean ]]; then
			continue
		fi
	
		 mkdir -p targets/$host/$platform
		 cp $item/lib/$host/$platform/lib$item.a $_		
		 ar -rc --thin $_/libmdns.a $_/lib$item.a		
	done	
	
	if [[ -z $clean ]]; then
		declare -n headers=$item
		mkdir -p targets/include/$item	
		for header in ${headers[@]}
		do
			cp $item/$header $_
		done	
	fi	
done

