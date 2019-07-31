# xLib6000 v3
## Mac implementation of the FlexRadio (TM) series 6000 software defined radios API (FlexLib)

### Built on:
*  macOS 10.14.6 (Deployment Target of macOS 10.11)
*  Xcode 10.3(10G8)
*  Swift 5.0

[![badge-language]][swift.org]
[![badge-license]][license]

*Works with all Radios with Version 2.5.1 or more ( i.e. >=2.5.1.x and 3.x.x )

## Usage




THIS IS MY INITIAL WORK ON v3 COMPATIBILITY, IT IS NOT A COMPLETE, WORKING v3 IMPLEMENTATION





This framework provides most of the capability of FlexLib but does not provide an identical  interface due to the  
differences between the Windows and macOS environments and system services.

The "xLib6000 Overview.pdf" file in the Documentation folder contains an overview of the structure of this framework  
and an explanation of the Tcp and Udp data flows.  

If you want to learn more about the 6000 series API, please take a look at the xAPITester project. It uses this framework.

* https://github.com/DougPA/xAPITester

For an example of a SmartSDR-like client for the Mac, please take a look at the xSDR6000 project. It uses this framework.

* https://github.com/DougPA/xSDR6000

If you require a Mac version of DAX and/or CAT, please see.

* https://dl3lsm.blogspot.com


## Builds

A compiled RELEASE build executable is contained in the GitHub Release if you would rather not build from sources.  

If you require a DEBUG build you will have to build from sources.   


## Comments / Questions

douglas.adams@me.com


## Credits

Version 7.6.3 of CocoaAsyncSocket is embedded in this project as source code. It can be found on GitHub at:  

* https://github.com/robbiehanson/CocoaAsyncSocket


## Known Issues

Please see ChangeLog.txt for a running list of changes and KnownIssues.md for a list of the known issues.

Please reports any bugs you observe to douglas.adams@me.com
