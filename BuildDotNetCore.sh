#! /bin/bash

#This builds for x86 Linux on an amd64
#Build on x86 Linux is not supported

OutputDir="dotnetcore"
Branch="v2.1-preview1" #master #v2.0.6 #v2.0.5
Version="2.1.0"

BuildAll()
{
	#Build everything
	BuildClr
	BuildCoreFx
	BuildOutput
}

BuildClr()
{
	#Build .net core clr
	#https://github.com/dotnet/coreclr/issues/13192
	#https://github.com/dotnet/coreclr/issues/9265

	echo "Starting CLR build"

	sudo apt-get install git
	git clone -b ${Branch} https://github.com/dotnet/coreclr.git

	#Open build.sh and remove debian.9-x64 from isMSBuildOnNETCoreSupported()
	echo "Open build.sh and remove debian.9-x64 from UNSUPPORTED_RIDS in isMSBuildOnNETCoreSupported()"
	echo "Press enter when done"
	read Uninstalled

	sudo apt-get install libunwind8
	sudo apt-get install debootstrap
	sudo apt-get install qemu-user-static
	cd coreclr
	sudo ./cross/build-rootfs.sh x86
	sudo apt-get install cmake
	sudo apt-get install clang-3.8 lldb-3.8

	./build.sh cross x86 release skipnuget skiptests cmakeargs "-DSKIP_LLDBPLUGIN=true" clang3.8

	cd ..
}

BuildCoreFx()
{
	#Build .Net core FX
	#https://github.com/dotnet/corefx/issues/25002
	#Must build clr first
	
	#If building 2.0.5
	#Edited corefx/external/ilasm/ilasm.depproj
	#Changed <NugetRuntimeIdentifier>$(RuntimeOS)-x64</NugetRuntimeIdentifier>
	#To <NugetRuntimeIdentifier>ubuntu.16.04-x64</NugetRuntimeIdentifier>
	#And /corefx/external/runtime/runtime.depproj
	
	echo "Starting CorFX build"

	sudo apt-get install git clang-3.9 cmake make libc6-dev libssl-dev libkrb5-dev libcurl4-openssl-dev zlib1g-dev
	git clone -b ${Branch} https://github.com/dotnet/corefx.git
	cd corefx
	sudo ./cross/build-rootfs.sh x86
	./build-native.sh -release -buildArch=x86 -- cross clang3.8
	./build-managed.sh -release -BuildTests=false
	cd ..
}

BuildOutput()
{
	#Build an output folder
	echo "Gathering output files"

	if [ -d ${OutputDir} ]
	then
		rm -r ${OutputDir}
	fi
	
	OutputDir="${OutputDir}/usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}"
	mkdir -p ${OutputDir}

	#dotnet-host
	cp corefx/LICENSE.TXT dotnetcore/usr/share/dotnet
	cp corefx/THIRD-PARTY-NOTICES.TXT dotnetcore/usr/share/dotnet

	#dotnet-hostfxr-2.0.5
	#cp corefx/bin/Unix.AnyCPU.Debug/runtime/netcoreapp/libhostfxr.so dotnetcore/usr/share/dotnet/host/fxr/2.0.5/libhostfxr.so

	#dotnet-runtime-2.0.5
	cp corefx/Tools/dotnetcli/shared/Microsoft.NETCore.App/2.0.3/Microsoft.NETCore.App.deps.json ${OutputDir}
	
	find corefx/bin/runtime/netcoreapp-Linux-Release-x64 -iname \*.dll -exec cp {} ${OutputDir} \;
	find corefx/bin/runtime/netcoreapp-Linux-Release-x64 -iname \*.pdb -exec cp {} ${OutputDir} \;

	cp -r corefx/bin/Linux.x86.Release/native/. ${OutputDir}
	
	cp -r coreclr/bin/Product/Linux.x86.Release/. ${OutputDir}
}

Install ()
{
	#Run this on the target x68 maching

	echo "Have any previous versions been uninstalled first? (y/n)"
	Uninstalled=""
	read Uninstalled
	if Uninstalled = "n"
	then
		echo "Use uninstall with the origional .sh file before installing."
		exit 1
	fi

	#Install .net core dependancies
	#Required by dotnet-host
	sudo apt-get install libc6 libgcc1 libstdc++6
	#Required by dotnet-runtime
	sudo apt-get install libcurl3 libgssapi-krb5-2 liblttng-ust0 libunwind8 libuuid1 zlib1g libssl1.0.2 libicu57

	sudo cp -r dotnetcore/usr/. /usr
	sudo ln -sr /usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}/corerun /usr/share/dotnet/dotnet
	sudo ln -sr /usr/share/dotnet/dotnet /usr/bin/dotnet

	sudo chmod 755 /usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}/corerun
	sudo chmod 755 /usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}/coreconsole
	sudo chmod 755 /usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}/*.so

	echo "Install done."
	echo "Keep this file to uninstall or upgrade."
}

Uninstall()
{
	sudo rm /usr/bin/dotnet
	sudo rm /usr/share/dotnet/dotnet
	sudo rm -r /usr/share/dotnet/shared/Microsoft.NETCore.App/${Version}
}

case "$1" in
	build)
		BuildAll
		;;
	buildclr)
		BuildClr
		;;
	buildfx)
		BuildCoreFx
		;;
	buildoutput)
		BuildOutput
		;;
	install)
		Install
		;;
	uninstall)
		Uninstall
		;;
	*)
		echo ""
		echo "This builds an x68 .net core ${Branch}. The build steps should be run on a supported architecture like amd64."
		echo "  build            Build core clr, core fx, and output."
		echo "  buildclr         Build core clr."
		echo "  buildfx          Build core fx. Must build core clr first."
		echo "  buildoutput      Gather output files. Must build core clr and core fx first."
		echo "  install          Copy the output files into /usr, set permissions, and create links. Run this on the x86 machine with the output folder."
		echo "  uninstall        Delete installed files"
		;;
esac

exit 0
