function Get-AllBuilds 
{
  Param(
    [string] $server   = "TeamCityServer",
    [string] $port     = "TeamCityPort",
    [string] $TCProjectName 
  )
    write-verbose -Message "Getting all builds for project :$TCProjectName" -Verbose
    $authInfo = "userName" + ":" + "password"
    $ApiCredentialsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($authInfo))
    $ApiCredentialsHeader = @{};
    $ApiCredentialsHeader.Add("Authorization", "Basic $ApiCredentialsBase64")
    $ApiCredentialsHeader
    $baseUrl   = "http://$server`:$port"
    $uri = "$baseUrl/app/rest/buildTypes/id:$TCProjectName/builds/"
    write-verbose -Message "Created uri for all builds of $TCProjectName :$uri" -Verbose
    return (Invoke-RestMethod -Uri $uri -Headers $ApiCredentialsHeader).builds.build
}
function Get-TCBuildbyVersion
{
    Param([string]$projectName,[string]$version)
    $releaseList = Get-AllBuilds -TCProjectName $projectName
    write-verbose -Message "getting build by version for project:$projectName and version:$version" -Verbose
    return $releaseList | Where-Object{$_.number -eq $version}
}
function Get-TCBuildChangesByBuildId
{
Param(
    [string] $server   = "TeamCityServer",
    [string] $port     = "TeamCityPort",
    [string] $id
  )
    $authInfo = "userName" + ":" + "password"
    $ApiCredentialsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($authInfo))
    $ApiCredentialsHeader = @{};
    $ApiCredentialsHeader.Add("Authorization", "Basic $ApiCredentialsBase64")
    $ApiCredentialsHeader
    $baseUrl   = "http://$server`:$port"
    $uri = "$baseUrl/app/rest/changes?locator=build`:(id`:$id)"
    Write-Verbose -Message "Created uri for change list`:$uri" -Verbose
    return (Invoke-RestMethod -Uri $uri -Headers $ApiCredentialsHeader).changes.change
}
function Get-TCBuildChangeDetailsForChangeId
{
    Param(
    [string] $server   = "TeamCityServer",
    [string] $port     = "TeamCityPort",
    [string] $id
  )
    $authInfo = "userName" + ":" + "password"
    $ApiCredentialsBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($authInfo))
    $ApiCredentialsHeader = @{};
    $ApiCredentialsHeader.Add("Authorization", "Basic $ApiCredentialsBase64")
    $ApiCredentialsHeader
    $baseUrl   = "http://$server`:$port"
    $uri = "$baseUrl/app/rest/changes/id`:$id"
    Write-Verbose -Message "Created uri for build id($id)`:$uri" -Verbose
    $utf8 = [System.Text.Encoding]::GetEncoding(65001) 
    $iso88591 = [System.Text.Encoding]::GetEncoding(28591) #ISO 8859-1 ,Latin-1
    $change = (Invoke-RestMethod -Uri $uri -Headers $ApiCredentialsHeader).change
    $wrong_comment = $utf8.GetBytes($change.comment)
    $right_comment = [System.Text.Encoding]::Convert($utf8,$iso88591,$wrong_comment) #Look carefully 
    $comment = $utf8.GetString($right_comment)
    
    $details = @{
        comment =  $comment
        user = $($change.username)
    }
    return $details

}
function Get-TCChangesForReleaseNumber
{
    Param(
	[string] $releaseNumber,
	[string] $teamCityProjectName
)
	$id = (Get-TCBuildbyVersion -projectName $teamCityProjectName -version $releaseNumber).id
	write-verbose -Message "Getting all changes for build id:$id" -Verbose
	$changes = (Get-TCBuildChangesByBuildId -id $id).id
	return $changes
}
function Send-TCNotifyChanges
{
    Param(
        [String]$releaseNumber,
        [String]$teamCityProjectName,
        [string]$to,
        [string]$env
    )
    $sendMail = $false
    $table = ""
    $tr = ""
    $notify = $to.Split(";")
    $changes = Get-TCChangesForReleaseNumber -releaseNumber $releaseNumber -teamCityProjectName $teamCityProjectName
    foreach($changeId in $changes)
    {
        write-verbose -Message "Getting change details for changeId:$changeId" -Verbose
        $change=$(Get-TCBuildChangeDetailsForChangeId -id $changeId)
        write-host "Change Id:$changeId"
        $change
        $tr += "<tr><td>$($change.user)</td><td>$($change.comment)</td></tr>"
        $sendMail = $true
    }

    if($sendMail)
    {
        $table = @"
        <table align="left" style="text-align: left">
        <tr align="left" style="text-align: left">
        <th align="left" style="text-align: left">Responsible</th>
        <th align="center" style="text-align: center">Change</th>
        </tr>
"@
        $table = $table + $tr + "</table>" 
        
        Send-MailMessage -Subject "$teamCityProjectName on $env !" -Body "Hi all,</br>$releaseNumber - $teamCityProjectName project is on $env! </br>The changes below are ready to test right now!</br></br>Best Regards</br>Cansin</br></br></br>$table</br></br>" -SmtpServer "smtp.cnsn.com" -To $notify -From "cnsn@cnsn.com" -Cc "cnsn@cnsn.com" -Encoding ([System.Text.Encoding]::UTF8) -BodyAsHtml
}
}
