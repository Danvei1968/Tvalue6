This is the README file for automation package of WinSCP.

For use of WinSCP automation package see
https://winscp.net/eng/docs/library
https://winscp.net/eng/docs/library_install

To use the WinSCP assembly via COM interop, register it using:
%WINDIR%\Microsoft.NET\Framework\<version>\RegAsm.exe WinSCPnet.dll /codebase /tlb
where <version> is typically either v4.0.30319 or v2.0.50727.
https://winscp.net/eng/docs/library_install#registering

WinSCP homepage is https://winscp.net/

See the file 'license-dotnet.txt' for the license conditions.

C:\Windows\WinSxS\wow64_regasm_b03f5f7f11d50a3a_4.0.15805.0_none_9be7d950c1f8addd\RegAsm.exe C:\Add-ins\SCP\WinSCPnet.dll /codebase /tlb