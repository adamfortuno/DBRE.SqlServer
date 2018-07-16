$test_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path

$module_script_name = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1", "")
$module_name = (Split-Path -Leaf $module_script_name).Replace(".psm1", "")

if ( Get-Module -Name $module_name ) {
    Remove-Module -Name $module_name
}

Import-Module "${test_script_path}" -Force -Scope Local
write-host $module_name

class fake_ManagedComputer_Service {
    [string]$name
    fake_ManagedComputer_Service ([string]$thing) { $this.name = $thing }
    [void] SetServiceAccount([string]$UserName, [string]$Password) { }
}

InModuleScope -ModuleName $module_name {

    ## Global Mocks; Stuff we REALLY don't want executing
    Mock 'Restart-Service' { }
    Mock 'Set-ItemProperty' { }

    $instance_name = '<searchInstanceName>'

    describe "Get-SqlServerID" {
        class fake_regkey_sql_invalid { [void] GetValue([string]$instanceName) { } }
        class fake_regkey_sql_valid { [string] GetValue([string]$instanceName) { return '<instanceName>' } }
        $instance_name = '<searchInstanceName>'

        context "when the specified instance does not exist" {

            Mock 'Get-Item' { New-Object 'fake_regkey_sql_invalid' }

            it "exception returned when searching for a non-existant default instance" {
                { Get-SqlServerID } `
                    | Should -throw 'Unable to find identifier for specified SQL Server instance.'
            }

            it "exception returned when searching for a non-existant named instance" {
                { Get-SqlServerID -InstanceName $instance_name } | `
                    should -throw 'Unable to find identifier for specified SQL Server instance.'
            }
        }

        context "when the specified instance does exist" {

            Mock 'Get-Item' { New-Object 'fake_regkey_sql_valid' }

            it "return SQL Server installation identifier when searching for a default instance" {
                $thing = New-Object 'fake_regkey_sql_valid'

                Get-SqlServerID | `
                    should -Be $thing.GetValue('<whatever>')
            }

            it "return SQL Server installation identifier when searching for a named instance" {
                $thing = New-Object 'fake_regkey_sql_valid'

                Get-SqlServerID -InstanceName $instance_name | `
                    should -Be $thing.GetValue('<whatever>')
            }
        }
    }


    describe "Get-SqlServerRegistryRoot" {
        context "when called" {
            it "SQL Server's registry hive path is returned" {
                Get-SqlServerRegistryRoot | Should Be 'HKLM:\Software\Microsoft\Microsoft SQL Server'
            }
        }
    }


    describe "Set-SqlServerConnectionEncryption" {
        $certificate = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2'

        context "when the specified instance does exist" {
           
            Mock 'Get-SqlServerID' { return 'MSSQLSERVER$SqlServerID' }

            it "enables SSL encryption on the default instance and assigns specified certificate with reboot" {
                Set-SqlServerConnectionEncryption -Certificate $certificate -RebootAfterChange
            }
            it "enables SSL encryption on the default instance and assigns specified certificate without reboot" {
                Set-SqlServerConnectionEncryption -Certificate $certificate
            }
            it "enables SSL encryption on the named instance and assigns the specified certificate with reboot" {
                Set-SqlServerConnectionEncryption -InstanceName $instance_name -Certificate $certificate -RebootAfterChange
            }
            it "enables SSL encryption on the named instance and assigns the specified certificate without reboot" {
                Set-SqlServerConnectionEncryption -InstanceName $instance_name -Certificate $certificate
            }
            it "disables SSL encryption on the default where it had been enabled with reboot" {
                Set-SqlServerConnectionEncryption -Disable -RebootAfterChange
            }
            it "disables SSL encryption on the default where it had been enabled without reboot" {
                Set-SqlServerConnectionEncryption -Disable
            }
            it "disables SSL encryption on the named instance where it had been enabled with reboot" {
                Set-SqlServerConnectionEncryption -InstanceName $instance_name -Disable -RebootAfterChange
            }
            it "disables SSL encryption on the named instance where it had been enabled without reboot" {
                Set-SqlServerConnectionEncryption -InstanceName $instance_name -Disable
            }
            it "disables SSL encryption on the default where it had not been enabled" {
                Set-SqlServerConnectionEncryption -Disable -RebootAfterChange
            }
            it "disables SSL encryption on the named instance where it had not been enabled" {
                Set-SqlServerConnectionEncryption -InstanceName $instance_name -Disable
            }
        }
    }


    describe "Set-SqlServerForceEncryption" {
        context "tba" {

            Mock 'Get-SqlServerID' { return 'MSSQLSERVER$SqlServerID' }

            it "force SSL encryption on the default instance with reboot" {
                Set-SqlServerForceEncryption -RebootAfterChange
            }
            it "force SSL encryption on the default instance without reboot" {
                Set-SqlServerForceEncryption
            }
            it "force SSL encryption on the named instance with reboot" {
                Set-SqlServerForceEncryption -InstanceName $instance_name -RebootAfterChange
            }
            it "force SSL encryption on the named instance without reboot" {
                Set-SqlServerForceEncryption -InstanceName $instance_name
            }
            it "disable forced SSL encryption on the named instance where it had been enabled with reboot" {
                Set-SqlServerForceEncryption -InstanceName $instance_name -Disable -RebootAfterChange
            }
            it "disable forced SSL encryption on the named instance where it had been enabled without reboot" {
                Set-SqlServerForceEncryption -InstanceName $instance_name -Disable
            }
            it "disable forced SSL encryption on the default instance where it had been enabled with reboot" {
                Set-SqlServerForceEncryption -Disable -RebootAfterChange
            }
            it "disable forced SSL encryption on the default instance where it had been enabled without reboot" {
                Set-SqlServerForceEncryption -Disable
            }
        }
    }


    describe "Set-SQLServiceCredential" {
        $service_account_name = '<serviceAccount>'
        $server_name = '<serverName>'
        $service_name = '<serviceName>'
        
        class fake_ManagedComputer {
            $Services
            fake_ManagedComputer([string]$service_name) {
                $this.Services = New-Object 'System.Collections.ArrayList'
                $this.Services.Add( $(New-Object 'fake_ManagedComputer_Service' -ArgumentList $service_name) )
            }
        }

        Mock 'Test-Connection' { return $true }
        Mock 'Get-Service' { New-Object 'System.ServiceProcess.ServiceController' }
        Mock 'New-Object' { New-Object 'fake_ManagedComputer' -ArgumentList $service_name } `
            -parameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' }

        context "when cannot connect to remove computer" {
            Mock 'Test-Connection' { return $false }

            it "should throw an exception when assigning a service account" {
                { Set-SQLServiceCredential -UserName $service_account_name `
                    -ServiceName $service_name `
                    -ComputerName $server_name } `
                | Should -Throw "Unable to find one or more of the specified servers."
            }

            it "should throw an exception when assigning 'LocalSystem' (service account is omitted)" {
                { Set-SQLServiceCredential `
                    -ServiceName $service_name `
                    -ComputerName $server_name } `
                | Should -Throw "Unable to find one or more of the specified servers."
            }
        }

        context "when the specified service cannot be found" {
            Mock 'Get-Service' { return $null }

            it "should throw an exception when assigning a service account" {
                { Set-SQLServiceCredential `
                    -UserName $service_account_name `
			        -ServiceName $service_name `
                    -ComputerName $server_name } `
                | should -throw "Unable to find the service"
            }

            it "should throw an exception when assigning 'LocalSystem' (service account is omitted)" {
                { Set-SQLServiceCredential `
                    -ServiceName $service_name `
                    -ComputerName $server_name } `
                | should -throw "Unable to find the service"
            }
        }

        context "when the server and service are found" {

            it "should update the service to the specified service account" {
                Set-SQLServiceCredential `
                    -UserName $service_account_name `
			        -ServiceName $service_name `
			        -ComputerName $server_name
            }

            it "should update the service's context to 'LocalSystem' when a service account is omitted" {
                Set-SQLServiceCredential `
                    -ServiceName $service_name `
                    -ComputerName $server_name
            }

            it "should update the local SQL Server instance when a computer name is omitted" {
                Set-SQLServiceCredential -ServiceName $service_name
                Assert-MockCalled Get-Service -Exactly 1 -ParameterFilter { $ComputerName -eq $env:computername } -Scope It
                Assert-MockCalled New-Object -Exactly 1 -ParameterFilter { $ArgumentList -eq $env:computername } -Scope It
            }
        }
    }
}