setlocal

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

if /I [%1] == [rebuild] (
	set option="-t:Rebuild"
)

msbuild libmdns.sln /property:Configuration=Debug %option%
msbuild libmdns.sln /property:Configuration=Release %option%

set target=targets\win32\x86

if exist %target% (
	del %target%\*.lib
)

robocopy lib\win32\x86 %target% lib*.lib lib*.pdb /NDL /NJH /NJS /nc /ns /np
robocopy mdnssvc targets\include\mdnssvc mdnssvc.h /NDL /NJH /NJS /nc /ns /np
robocopy mdnssd targets\include\mdnssd mdnssd.h /NDL /NJH /NJS /nc /ns /np
lib.exe /OUT:%target%/libmdns.lib %target%/libmdnssvc-Release.lib %target%/libmdnssd-Release.lib
lib.exe /OUT:%target%/libmdns-Debug.lib %target%/libmdnssvc-Debug.lib %target%/libmdnssd-Debug.lib

endlocal

