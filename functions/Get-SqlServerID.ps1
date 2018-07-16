function Get-SqlServerID {
    <#
		.Synopsis
        Returns the installation ID for a specified instance of SQL
        SQL Server.

		.Description
        Returns the installation ID for a specified instance of SQL
        SQL Server. The installation ID is assigned to the installation's
        installation-folder an registry-hive.

		.Parameter InstanceName
        The name of the instance who's identifier we want to retrieve.

        .Example
        Get-SqlServerID
        
        Retrieves the identifier for the machine's default instance.

		.Example
        Get-SqlServerID -InstanceName 'dev-qc-dbn01\pv1'
        
        Retrieves the identifier for the specified named instance.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, Position=1)][string] $InstanceName = 'MSSQLSERVER'
    ) 

    $regpath_sqlserver_root = Get-SqlServerRegistryRoot

    ## Configure SQL Server to use certificate for connections
    $regpath_sqlserver_instances = Join-Path -Path $regpath_sqlserver_root `
        -ChildPath 'Instance Names\SQL'
    
    $regkey_sqlserver_instances = Get-Item -Path $regpath_sqlserver_instances
    
    $sqlserver_instance_name = $regkey_sqlserver_instances.GetValue($InstanceName)
        
    if ( [string]::IsNullOrEmpty($sqlserver_instance_name) ) {
        throw 'Unable to find identifier for specified SQL Server instance.'
    }

    return $sqlserver_instance_name
}