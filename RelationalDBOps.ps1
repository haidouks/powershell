function select-Oracle
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

function Select-MSSQL {
    param(
        [string] $connectionString = $(throw "Please specify a connection string."),
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables

}
function select-MySql
{
    [CmdletBinding()]
    Param(
    [Parameter(Position=0,Mandatory=$true)]
    [string]$connStr,
    [Parameter(Position=1,Mandatory=$true)]
    [string]$query)
    $ConnectionString = $connStr
Try {
  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  $Connection.ConnectionString = $ConnectionString
  $Connection.Open()
  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
  $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
  $DataSet = New-Object System.Data.DataSet
  $RecordCount = $dataAdapter.Fill($dataSet, "data")
  $DataSet.Tables[0]
  }
Catch {
    $ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace + " Query:"+$query
    write-Error $ExceptionMessage
 }
Finally {
  $Connection.Close()
  $Connection.Dispose()
  $DataSet.Dispose()
  $DataAdapter.Dispose()
  }
}
