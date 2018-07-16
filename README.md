# DBRE.SqlServer
## About
The purpose of this project is to assist users with configuring and administering SQL Server. This module exposes functions to configure a specified instance of SQL Server.

## Installation
To install this module, execute the following steps:

**NOTE**: Ensure you have SQL Server Management Objects installed on the host before proceeding.

1. Open a Powershell session with administrative permissions.
2. Clone the project to a local directory of your choosing.
3. Navigate to the repository folder and run the ```install.ps1``` file.

That's it. The module will be installed to the machine's module directory.

This module works on traditional Windows systems. It will not work on Windows Core or Linux. This module depends on the following modules:

* ```pki```

This module is dependent on the [Microsoft.SqlServer.SqlManagementObjects](https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects) library associated with SQL Server 2012 or greater. Beginning with SQL Server 2017 the library is distributed as the Microsoft.SqlServer.SqlManagementObjects NuGet package.

## Architecture

The module exposes three functions: Remove-SqlServerConnectionEncryption(), Set-SqlServerConnectionEncryption(), and Set-SQLServiceCredential().

This repository is composed of the following:

|test|test|
---|---
|.\function|Stores the definition for all public and private functions.
|.\DBRE.SqlServer.psd1|The module's manifest. Defines exported functions, modules version, and dependent modules.
|.\DBRE.SqlServer.psm1|Module file. Loads the public and private functions in this module and initializes any global data members.
|.\DBRE.SqlServer.psm1.Tests.ps1|Unit test script for this module.
|.\README.md|Read Me file for this project.
|.\install.ps1|Module installation script.
|.\manifest.txt|Module installation manifest. Tells the manifest what files and folders to copy on installation.

## Usage Examples

Configure the default instance on the local host to run as  the 'LocalSystem' account.

```Powershell
Set-SQLServiceCredential -ServiceName 'MSSQLSERVER'
```

Configure 'dev-qc-dbn01\pv1' to use a trusted certificate. In this case, the certificate has a thumbprint 6D8FFD05A11BC702214F9BAFBD7E1F9688E50DB6, and it can be found in the 'Cert:\LocalMachine\My' store ('Local Computer\Personal\Certificate' folder from the Certificates MMC snap-in). You are then configuring the instance to make SSL encryption mandatory.

```Powershell
$certificate = ls 'cert:\LocalMachine\My\6D8FFD05A11BC702214F9BAFBD7E1F9688E50DB6'

Set-SqlServerConnectionEncryption -InstanceName 'dev-qc-dbn01\pv1' -Certificate $certificate
Set-SqlServerForceEncryption -InstanceName 'dev-qc-dbn01\pv1' -RebootAfterChange
```

You are disabling mandatory encryption and removing a certificate from the local instance.

```Powershell
Set-SqlServerConnectionEncryption -Disable
Set-SqlServerForceEncryption -Disable -RebootAfterChange
```