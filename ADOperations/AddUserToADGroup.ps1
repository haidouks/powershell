#set jenkins parameters
$emailAdd=$env:emailAdd
$groups=$env:groups


$info=[System.Convert]::ToBoolean($env:details)
$user=$env:BUILD_USER
$sendMail=[System.Convert]::ToBoolean($env:sendMail)

Write-Verbose "----------------------PARAMETERS----------------------" -verbose:$info
Write-Verbose "groups:$groups"-verbose:$info
Write-Verbose "emailAdd:$emailAdd"-verbose:$info
Write-Verbose "----------------------PARAMETERS----------------------" -verbose:$info

import-module ActiveDirectory -Cmdlet Add-ADGroupMember
try
{
    foreach($email in $emailAdd.Split(','))
    {
        Write-Verbose "Starting operations for user:$username" -verbose:$info 
        $username=$email.Split('@')[0]
        foreach($group in $groups.Split(","))
        {
            if($group -ne "false" -and -not [String]::IsNullOrEmpty($group))
            {
               Write-Verbose "Adding user:$username to group:$group" -verbose:$info
               Add-ADGroupMember $group $username
            }
            else
            {
               Write-Warning -Message "No group($group) precised!" -Verbose:$true
            }
        }
    }
    Write-Verbose "Finished adding all users($emailAdd)" -verbose:$info
}
catch
{
    $errorMessage = "$($_.Exception.Message)`n$(($_|select -ExpandProperty invocationinfo).PositionMessage)"
    Write-Warning -Message "Catched an exception in Function:$($MyInvocation.MyCommand)`n$errorMessage"
    Exit 1
}
