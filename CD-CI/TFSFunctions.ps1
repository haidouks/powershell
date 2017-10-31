function New-WorkItem ($collectionUrl,$teamProjectName,$title,$itemType,$AreaPath)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "Continue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "WorkItem Title : $title. Type of this parameter is $($title.Gettype())"
write-verbose -Message "WorkItem Type $itemType. Type of this parameter is $($itemType.Gettype())"
write-verbose -Message "Team Project Name: $teamProjectName . Type of this parameter is $($teamProjectName.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue"
$BodyContent = new-object System.Collections.ArrayList
$element1 = @{
"path"=  "/fields/System.Title"
    "op"=  "add"
    "value"=  $title
}
$element2 = @{
"path"=  "/fields/System.AreaPath"
    "op"=  "add"
    "value"=  $AreaPath
}
$BodyContent.add($element1)
$BodyContent.add($element2)
write-verbose -Message "Body:`n$($BodyContent|Out-Host)" -Verbose
$body = $BodyContent | ConvertTo-Json
write-verbose -Message "Body in json:`n$($body|Out-Host)" -Verbose
$body
$url = "$collectionUrl/$teamProjectName/_apis/wit/workitems/"+'$'+"$($itemType)?api-version=1.0"
write-verbose -Message "Creating Url for $itemtype : $url"
Invoke-RestMethod -uri $url -Method Patch -ContentType "application/json-patch+json" -body ([System.Text.Encoding]::UTF8.GetBytes($body)) -UseDefaultCredentials -errorAction SilentlyContinue
Set-StrictMode -off
}

function Set-TFSAreaPermissions($collectionUrl,$teamName,$teamProjectName,$iterationPath,$areaPath,$actions = "MANAGE_TEST_SUITES","MANAGE_TEST_PLANS","GENERIC_READ","WORK_ITEM_WRITE","WORK_ITEM_READ")
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "silentlyContinue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "Area Path: $areaPath. Type of this parameter is $($areaPath.Gettype())"
write-verbose -Message "Team Name: $teamName. Type of this parameter is $($teamName.Gettype())"
write-verbose -Message "Team Project Name: $teamProjectName . Type of this parameter is $($teamProjectName.Gettype())"
write-verbose -Message "Actions: $actions. Type of this parameter is $($actions.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue" -force
$team = "[$teamProjectName]\$teamName"
write-verbose -Message "Setting new team name: $team"
Set-AreaPermissions -CollectionUrl $collectionUrl -TeamProjectName $teamProjectName -Members $team  $iterationPath -AreaPath $areaPath -actions $actions
Set-StrictMode -off
}

function Set-TFSAreaNIteration($collectionUrl,$teamName,$teamProjectName,$iterationPath,$areaPath)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "continue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "Iteration Path : $iterationPath . Type of this parameter is $($iterationPath.Gettype())"
write-verbose -Message "Area Path: $areaPath. Type of this parameter is $($areaPath.Gettype())"
write-verbose -Message "Team Name: $teamName. Type of this parameter is $($teamName.Gettype())"
write-verbose -Message "Team Project Name: $teamProjectName . Type of this parameter is $($teamProjectName.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue"
$team = Get-Team -CollectionUrl $collectionUrl -TeamProjectName $teamProjectName -TeamName $teamName 
write-verbose -Message "Team Details:`n$($team | fl * |out-string)"
Set-TeamDefaultAreaAndIteration -CollectionUrl $collectionUrl -Team $team -IterationPath $iterationPath -AreaPath $areaPath| fl * -force
Set-StrictMode -off
}


function New-TFSTeam($collectionUrl,$projectName,$teamName,$description)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "silenltycontinue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "description : $description . Type of this parameter is $($description.Gettype())"
write-verbose -Message "project name : $projectName. Type of this parameter is $($projectName.Gettype())"
write-verbose -Message "teamName: $teamName. Type of this parameter is $($teamName.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue"
New-Team -CollectionUrl $collectionUrl -TeamProjectName $projectName -TeamName $teamname -Description $description | fl * -force
Set-StrictMode -off
}

function New-TFSArea($collectionUrl,$projectName,$location,$areaName)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Silentlycontinue"
$VerbosePreference =  "Silentlycontinue"

if([string]::isnullorempty($location))
{
$location = ""
}
else
{
$location = "\$location"
}
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "location : $location ."
write-verbose -Message "areaName : $areaName ."
write-verbose -Message "projectName: $projectName . Type of this parameter is $($projectName.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue" -force
$subLocations = $location.split("\")
$i = 0
while($i -lt $subLocations.Count)
{
if($i -eq 1)
{
write-verbose -Message "Checking area for ParentPath : '' and Area : '$($subLocations[1])'"
New-Area -CollectionUrl $collectionUrl -TeamProjectName $projectName -AreaName $subLocations[1] -ParentPath "" -ErrorAction SilentlyContinue
}
elseif($i -gt 1)
{
$tempParent = $($subLocations.Split("\")[0..$($i-1)] -join "\").Trim()
write-verbose -Message "Checking area for ParentPath : '$($tempParent)' and Area : '$($subLocations[$i])'"
New-Area -CollectionUrl $collectionUrl -TeamProjectName $projectName -AreaName $subLocations[$i] -ParentPath $tempParent -ErrorAction SilentlyContinue
}
$i++
}
$ErrorActionPreference = "Continue"
New-Area -CollectionUrl $collectionUrl -TeamProjectName $projectName -AreaName $areaName -ParentPath $location
Set-StrictMode -off
}

function New-TFSMember($collectionUrl,$ProjectName,$TeamName,$members)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "continue"
$group = "[$ProjectName]\$TeamName"
$members= $members.split(",")
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "group : $group . Type of this parameter is $($group.Gettype())"
write-verbose -Message "members: $members. Type of this parameter is $($members.Gettype())"
Import-Module "TFSPowershell"
Add-MembersToTfsGroup -CollectionUrl $collectionUrl -Group $group -Members $members
Set-StrictMode -off
}

Function Add-TFSTeamAdmin($collectionUrl,$projectName,$teamName,$poID)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "silenltycontinue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "project name : $projectName. Type of this parameter is $($projectName.Gettype())"
write-verbose -Message "teamName: $teamName. Type of this parameter is $($teamName.Gettype())"
write-verbose -Message "poID: $poID. Type of this parameter is $($poID.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue"
Get-ChildItem -Path "WORKSPACE\TFS\dlls" -Include "*.dll" -Recurse| foreach {
Write-Verbose -Message " Loadling dll : $_.FullName"
[Reflection.Assembly]::LoadFile($_.FullName)
}
[TfsApiForPowershell.TeamAdministrator]::AddTeamAdminToTeam($teamName, $projectName,$poID, $collectionUrl )
Set-StrictMode -off
}

Function Create-TFSSecGroup($collectionUrl,$projectName,$groupName)
{
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference =  "silenltycontinue"
write-verbose -Message "collection url : $collectionUrl. Type of this parameter is $($collectionUrl.Gettype())"
write-verbose -Message "project name : $projectName. Type of this parameter is $($projectName.Gettype())"
write-verbose -Message "GroupName: $groupName. Type of this parameter is $($groupName.Gettype())"
Import-Module "TFSPowershell" -WarningAction "silentlycontinue"
[string]$pathToTfsSecurityExe = "$(${Env:ProgramFiles(x86)})\Microsoft Visual Studio 14.0\common7\ide\TfsSecurity.exe";
$classificationUri = (Get-TeamProject -CollectionUrl $collectionUrl -TeamProjectName $projectname).Uri
& $pathToTfsSecurityExe /gc $classificationUri $groupName /collection:$collectionUrl
Set-StrictMode -off
}
