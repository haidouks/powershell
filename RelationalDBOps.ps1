function select-sqlOracle
{
    [CmdletBinding()]
    Param(
    [Parameter(Position=0,Mandatory=$true)]
    [string]$connStr,
    [Parameter(Position=1,Mandatory=$true)]
    [string]$query
    )
    try
    {
        Add-Type -Path "C:\oracle\ODP.NET_Managed121012\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
        $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connStr)
        $cmd=$con.CreateCommand()
        $cmd.CommandText=$query
        $con.Open()
        $da=New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($cmd);
        Write-Output $cmd
        $resultSet = New-Object System.Data.DataTable
        [void]$da.Fill($resultSet)
        return $resultSet     
    }
    catch
    {
        $ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace + " Query:"+$query
        write-Error $ExceptionMessage
 }
    finally
    {
        $con.Close()
        $con.Dispose()
    }
}
