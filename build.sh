#!/bin/bash

list="x86_64-linux-gnu-gcc x86-linux-gnu-gcc arm-linux-gnueabi-gcc aarch64-linux-gnu-gcc \
      sparc64-linux-gnu-gcc mips-linux-gnu-gcc powerpc-linux-gnu-gcc x86_64-macos-darwin-gcc \
	  x86_64-freebsd-gnu-gcc x86_64-solaris-gnu-gcc"

declare -A alias=( [x86-linux-gnu-gcc]=i686-stretch-linux-gnu-gcc \
				   [x86_64-linux-gnu-gcc]=x86_64-stretch-linux-gnu-gcc \
				   [arm-linux-gnueabi-gcc]=armv7-stretch-linux-gnueabi-gcc \
				   [aarch64-linux-gnu-gcc]=aarch64-stretch-linux-gnu-gcc \
				   [sparc64-linux-gnu-gcc]=sparc64-stretch-linux-gnu-gcc \
				   [mips-linux-gnu-gcc]=mips64el-stretch-linux-gnu-gcc \
				   [powerpc-linux-gnu-gcc]=powerpc64-stretch-linux-gnu-gcc \
				   [x86_64-macos-darwin-gcc]=x86_64-apple-darwin19-gcc \
				   [x86_64-freebsd-gnu-gcc]=x86_64-cross-freebsd12.3-gcc \
				   [x86_64-solaris-gnu-gcc]=x86_64-cross-solaris2.x-gcc )

declare -A cflags=( [sparc64-linux-gnu-gcc]="-mcpu=v7" \
                    [mips-linux-gnu-gcc]="-march=mips32" \
                    [powerpc-linux-gnu-gcc]="-m32" )
					
declare -a compilers

IFS= read -ra candidates <<< "$list"

# do we have "clean" somewhere in parameters (assuming no compiler has "clean" in it...
if [[ $@[*]} =~ clean ]]; then
	clean="clean"
fi	

# first select platforms/compilers
for cc in ${candidates[@]}; do
	# check compiler first
	if ! command -v ${alias[$cc]:-$cc} &> /dev/null; then
		if command -v $cc &> /dev/null; then
			unset alias[$cc]
		else	
			continue
		fi	
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

if [[ -n $clean ]]; then
	action="cleanlib"
else
	action="lib"	
fi

declare -a items=( mdnssd mdnssvc )
declare -a mdnssvc=( mdnssvc.h )
declare -a mdnssd=( mdnssd.h )

# then iterate selected platforms/compilers
for cc in ${compilers[@]}
do
	IFS=- read -r platform host dummy <<< $cc
	
	export CFLAGS=${cflags[$cc]}
	CC=${alias[$cc]:-$cc}
	
	target=targets/$host/$platform	
	mkdir -p $target
	rm -f $_/libmdns.a
	pwd=$(pwd)
	
	for item in ${items[@]}
	do
		cd $item
		make AR=${CC%-*}-ar CC=$CC PLATFORM=$platform HOST=$host $action -j8
		cd $pwd

		if [[ -z $clean ]]; then
			# copy libraries & create thin version
			cp $item/lib/$host/$platform/lib$item.a $target		
			
			# copy headers
			declare -n headers=$item
			mkdir -p targets/include/$item	
			for header in ${headers[@]}
			do
				cp -u $item/$header $_
			done
		else 	
			rm -f $target/lib$item.a
		fi	
	done	

	# now concatenate libs (create thin version when possible)
	if [[ -z $clean ]]; then
		if [[ $host =~ macos ]]; then
			${CC%-*}-libtool -static -o $target/libmdns.a $target/lib*.a				
		else 	
			ar -rc --thin $target/libmdns.a $target/lib*.a		
		fi	
	fi	

done
