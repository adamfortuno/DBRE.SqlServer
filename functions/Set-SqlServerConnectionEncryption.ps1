function Set-SqlServerConnectionEncryption {
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
		Set-SqlServerConnectionEncryption -Disable

        Disable SSL connection encryption on the default instance.

        .Example
        Set-SqlServerConnectionEncryption -Certificate $certificate
        
        Enables SSL connection encryption and assigns the specifed 
        certificate to the default instance.

		.Example
        Set-SqlServerConnectionEncryption -InstanceName 'dev-qc-dbn01\pv1' -Certificate $certificate
        
        Enabled SSL connection encryption and assigns the specified 
        certificate to the 'dev-qc-dbn01\pv1' instance.

		.Example
        Set-SqlServerConnectionEncryption -InstanceName 'dbapoc-qc-dbn01\pv1' -Disable

        Disables SSL encryption on the 'dev1-qc-dbn01\pv1' instance.
 	#>
     [CmdletBinding()]
     Param (
         [Parameter(Mandatory=$false, Position=1)][string] $InstanceName = 'MSSQLSERVER'
       , [Parameter(ParameterSetName='disable', Mandatory=$true, Position=2)][switch] $Disable = $false
       , [Parameter(ParameterSetName='enable', Mandatory=$true, Position=3)][Security.Cryptography.X509Certificates.X509Certificate2] $Certificate
       , [Parameter(Mandatory=$false, Position=4)][switch] $RebootAfterChange = $false
     ) 

    $regpath_sqlserver_root = Get-SqlServerRegistryRoot
    $sqlserver_default_instance_id = Get-SqlServerID -InstanceName $InstanceName
     
    ## Assigned SSL certificate is stored in the instance's registry HIVE.
    ## Retrieving location here.
    $regpath_sqlserver_network = Join-Path -Path $regpath_sqlserver_root `
         -ChildPath "${sqlserver_default_instance_id}\MSSQLServer\SuperSocketNetLib"
     
    ## To enable SSL encryption, you just need to assign a valid certificate
    ## thumbprint the SQL Server instance. Selecting value.
    if ( $Disable ) {
        $value = ''
    } else {
        $value = $certificate.thumbprint
    }

    Set-ItemProperty -Path $regpath_sqlserver_network `
        -Name "Certificate" `
        -Value $value

    ## The change will not take effect until the service is restarted.
    if ($RebootAfterChange) {
        $service_name = $InstanceName.Replace('\', '$')
        Restart-Service -Name $service_name -Force
    }
}