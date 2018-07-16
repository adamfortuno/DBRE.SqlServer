function Get-SqlServerRegistryRoot {
    <#
		.Synopsis
        Gets the root path for SQL Server's registry hive.

		.Description
        Returns the root location in the registry for SQL
        Server's data. With-in this branch, you can find
        information for each instance (named and default)
        of SQL Server on a given machine.

        .Example
        Get-SqlServerRegistryRoot
        
        Retrieves the registry root for SQL Server.
    #>
    return [string]'HKLM:\Software\Microsoft\Microsoft SQL Server'
}