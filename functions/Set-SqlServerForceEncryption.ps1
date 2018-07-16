function Set-SqlServerForceEncryption {
<#
		.Synopsis
        Configures SSL connection encryption for the specified
        SQL Server instance.

		.Description
        Enables or disables SSL connection encryption for a specified
        SQL Server instance. When enabling SSL connection encryption,
        it assigns the certificate to be used for the connection
        handshake.

		.Parameter InstanceName
        The name of the instance being modified. If omitted, the 
        default instance is targeted.

		.Parameter Disable
        Indicates that SSL connection encryption should be disabled 
        on the target instance.

		.Parameter Certificate
        The certificate being assigned to the instance. This certificate
        should be stored in the machine's certificate store.

        .Parameter RebootAfterChange
        Indicates the service should be restarted. The change will not
        take effect until the service has been restarted.

		.Example
		Set-SqlServerForceEncryption -Disable

        Make SSL connection encryption optional on the default instance.

        .Example
        Set-SqlServerForceEncryption

        Make SSL connection encryption mandatory on the default instance.

		.Example
        Set-SqlServerForceEncryption -InstanceName 'foo\bar' -RebootAfterChange

        Make SSL connection encryption mandatory on the 'foo\bar' instance, and
        reboots the instance after the change has been made.
 	#>
     [CmdletBinding()]
     Param (
         [Parameter(Mandatory=$false, Position=1)][string] $InstanceName = 'MSSQLSERVER'
       , [Parameter(Mandatory=$false, Position=2)][switch] $Disable = $false
       , [Parameter(Mandatory=$false, Position=4)][switch] $RebootAfterChange = $false
     ) 

    $regpath_sqlserver_root = Get-SqlServerRegistryRoot
    $sqlserver_default_instance_id = Get-SqlServerID -InstanceName $InstanceName
     
    ## Force encryption parameter is stored in the instance's
    ## registry HIVE. Retrieving location here.
    $regpath_sqlserver_network = Join-Path -Path $regpath_sqlserver_root `
         -ChildPath "${sqlserver_default_instance_id}\MSSQLServer\SuperSocketNetLib"
     
    ## Set the value to 1 to enabe  force encryption and 0 to 
    ## disable it
    if ( $Disable ) {
        $value = 0
    } else {
        $value = 1
    }

    Set-ItemProperty -Path $regpath_sqlserver_network `
        -Name "ForceEncryption" `
        -Value $value

    ## The change will not take affect until the service is restarted.
    if ($RebootAfterChange) {
        $service_name = $InstanceName.Replace('\', '$')
        Restart-Service -Name $service_name -Force
    }
}