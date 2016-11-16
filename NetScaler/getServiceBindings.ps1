try{
write-host "This script will be executed on $env:COMPUTERNAME"
Import-Module -Name Netscaler -ErrorAction Stop
$info = $true
$daysToExpire = $env:daysToExpire
$Nsips = $env:Nsips
$Username = $env:Username
$Password = $env:Password
$key = $env:keyword
if([String]::IsNullOrEmpty($key) -or $key.Trim().Length -le 3){Write-Host "Lütfen en az 4 karakter uzunluğunda keyword giriniz";Exit 1 }
foreach($Nsip in $Nsips.Split(","))
{
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
$Session =  Connect-Netscaler -Hostname $Nsip -Credential $Credential -PassThru
(Get-NSLBVirtualServer -Session $Session | Where-Object {$_.Name -match $key -or $_.ipv46 -match $key })|Select-Object ipv46,Name|ForEach-Object{write-host "Searching bindings for $_"; Get-NSLBVirtualServerBinding -Session $Session -Name $_.Name| Select-Object servicename,ipv46,port,curstate | ft -AutoSize}
}
}
catch
{
$_.Exception
Exit 1
}
