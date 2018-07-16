function Set-SQLServiceCredential {
	<#
		.Synopsis
		Set the service account for a SQL Server service.

		.Description
		This commandlet sets the service account for a specified SQL
		Server service including but not limited to engine service, 
		agent service, integration service, etc.

		This commandlet will automatically restart the subject service.

		.Parameter UserName
		The username of the crential you will be assigning to the 
		service. The default value is 'LocalSystem'.

		.Parameter Password
		The username of the crential you will be assigning to the 
		service. When assigning an MSA or Local System account, this
		parameter can be omitted.

		.Parameter ServiceName
		The name of the subject service; service being configured.

		.Parameter ComputerName
		The name of the computer on-which the service resides.

		.Example
		Set-SQLServiceCredential -UserName 'cable\!dev1-test$' `
			-ServiceName 'MSSQLSERVER' `
			-ComputerName 'dev1-qc-dbn01'

		.Example
		Set-SQLServiceCredential -ServiceName 'MSSQLSERVER' -ComputerName 'dev1-qc-dbn01'

		Sets the service account for the default SQL Server service on
		'dev1-qc-dbn01' to 'LocalSystem'.
 	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false, Position=1)][string] $UserName = 'LocalSystem'
	  , [Parameter(Mandatory=$false, Position=2)][string] $Password = ''
	  , [Parameter(Mandatory=$true, Position=3)][string] $ServiceName
	  , [Parameter(Mandatory=$false, Position=4)][string] $ComputerName = $env:computername
	) 

	#Load the SqlWmiManagement assembly off of the DLL
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null

	Write-Verbose 'Confirm the machine exists...'
	if ( $(Test-Connection -Count 3 -Quiet -ComputerName $ComputerName) -eq $false ) {
		throw 'Unable to find one or more of the specified servers.'
	}

	Write-Verbose 'Confirm the service exists...'
	if ( [bool]$(Get-Service -Name $ServiceName -ComputerName $ComputerName -ErrorAction SilentlyContinue) -eq $false) {
		throw "Unable to find the service '${ServiceName}' on '${ComputerName}."
	}

	$server = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' `
		-ArgumentList $ComputerName 
	
	Write-Verbose 'Attempting to assign the account to the service...'
	$target_service = $server.Services | Where-Object { $_.name -eq $ServiceName }
	$target_service.SetServiceAccount($UserName, $Password)
}