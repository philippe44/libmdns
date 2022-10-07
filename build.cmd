setlocal

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

msbuild libmdns.sln /property:Configuration=Debug %1
msbuild libmdns.sln /property:Configuration=Release %1

set target=targets\win32\x86

if exist %target% (
	del %target%\*.lib
)

robocopy lib\win32\x86 %target% lib*.lib lib*.pdb /NDL /NJH /NJS /nc /ns /np
robocopy tinysvcmdns targets\include\tinysvcmdns tinysvcmdns.h /NDL /NJH /NJS /nc /ns /np
robocopy mdnssd targets\include\mdnssd mdnssd.h /NDL /NJH /NJS /nc /ns /np
lib.exe /OUT:%target%/libmdns.lib %target%/libtinysvcmdns.lib %target%/libmdnssd.lib

endlocal

