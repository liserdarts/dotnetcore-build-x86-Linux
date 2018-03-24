# dotnetcore-build-x86-Linux
.NEt Core does not have official support for x86 processors on Linux. However the developers have been working hard making it a reality and it's 99% ready. If you're willing to take the increased risk of finding a bug you may want to try anyway. But without an official download you'll need to build you're own copy of .Net Core. This repository contains what I found successful when building .NET Core for x86 Linux. It's here to help anybody attempting to do the same.

## General instructions
You'll need a supported Linux machine with a supoprted processor. I used Debian 9 running with an amd64 processor. Check out the [coreclr build documentation](https://github.com/dotnet/coreclr/tree/master/Documentation/building) for more inforamtion on what is supported.

### Building
`BuildDotNetCore.sh` contains all the commands you should need. Make a local copy of it on the machine you will be using to build. Then just run it like this.

```BASH
  chmod 755 BuildDotNetCore.sh
  sudo ./BuildDotNetCore.sh buildclr
  sudo ./BuildDotNetCore.sh buildfx
  sudo ./BuildDotNetCore.sh buildoutput
```

If you are feeling lucky you can run all 3 steps with one line. But if this is you're first time I would recomend just doing the 3 seperate. That way if something goes wrong you'll know where to resume from.

```BASH
  sudo ./BuildDotNetCore.sh build
```

Be prepared to leave it running for a while. This isn't a quick process. This will create a folder named  `dotnetcore`.

### Running
Copy the `dotnetcore` folder and BuildDotNetCore.sh to your x86/Linux machine. You can then start your app with something like this.

```BASH
  dotnetcore/corerun /path/to/foo.dll
```

You can also create a more traditional scenario by copying the .NET core files to /usr/share/dotnet. `BuildDotNetCore.sh` can do this for you also.

```BASH
  sudo ./BuildDotNetCore.sh install
  dotnet /path/to/foo.dll
```

The files can be removed just as easily

```BASH
  sudo ./BuildDotNetCore.sh uninstall
```

## Caveats

### Offical support
.Net Core still does not 100% support x86 on Linux. I've been using it without much issue, but I did run into one problem closing named pipes. This wasn't a deal breaker for me. Just be aware you have an increased risk of finding a bug. So this probably isn't suitable for a business enviroment.

If you think you have found a bug you should report it to either [coreclr](https://github.com/dotnet/coreclr/issues) or [corefx](https://github.com/dotnet/corefx/issues). Don't report it here. Microsoft is working on supporting this scenario and will appricate your help.

### Me
I'm just one guy trying to help others by sharing what I've learned. I don't have the time or knowledge to provide much low level assistance. I have plenty of experiance as a developer but am rather green when it comes to Linux and C++. I may have made a mistake that becomes apparent in your situation. I'll attempt to help out if you report the problem. If you see something that could be improved let me know.

### Version
I made `BuildDotNetCore.sh` get and build the v2.1-preview1 branch. The offical .Net Core 2.1 should be comming out in a few months after I write this. You can easily change the branch in the first few lines of `BuildDotNetCore.sh`. I've also successfully build the master, v2.0.6, and v2.0.5 branches.
