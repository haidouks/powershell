function New-MMToken
{
   <#
       .SYNOPSIS
       Creates token for MatterMost
       .DESCRIPTION
       This function returns token for MatterMost. For posting a message, first you need to create a token on MatterMost.
       .EXAMPLE
       New-MatterMostToken -url "http://matterdns:8065/api/v4/users/login" -MatterUser "user1" -MatterPass "password123"
       .PARAMETER url
       Specify the login url of MatterMost API
       .PARAMETER MatterUser
       Specify the user name for MatterMost
       .PARAMETER MatterPass
       Specify the password for MatterUser
   #>
   [CmdletBinding()]
   Param (
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost URL')]
           [ValidatePattern('https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.([-a-zA-Z0-9@:%_\+.~#?&//=]*)')]
       [string]$url,         
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost UserName')]
       [string]$MatterUser,
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost Password')]
       [string]$MatterPass     

       )
   Write-Verbose -Message "Creating json for user $MatterUser"
   $json = @{
           "login_id"="$MatterUser"
           "password"="$MatterPass"
       } | ConvertTo-Json
   Write-Verbose -Message "Creating token for MatterMost ($url) using json"
   $token = (Invoke-WebRequest -Method Post -Uri $url -Body $json -ContentType 'application/json' -UseBasicParsing).Headers.Token
   return $token
}

function New-MMPost
{
    <#
       .SYNOPSIS
       Posts message to MatterMost channel
       .DESCRIPTION
       This function Posts message to MatterMost channel. For posting a message, first you need to create a token on MattrerMost.
       .EXAMPLE
       New-MMPost -url "http://matterdns:8065/api/v4/posts" -MatterToken $token -ChannelID "r8jbmbjsjbyiiqtbj4n4nqg7jh" -Message "this is a sample message"
       .PARAMETER url
       Specify the post url of MatterMost API
       .PARAMETER MatterToken
       Specify the token object for MatterMost
       .PARAMETER ChannelID
       Specify the channel id that you want to send message
       .PARAMETER Message
       Specify the message that you want to send
   #>
   [CmdletBinding()]
   Param (
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost URL')]
           [ValidatePattern('https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.([-a-zA-Z0-9@:%_\+.~#?&//=]*)')]
       [string]$url,         
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost UserName')]
       [string]$ChannelID,
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost Password')]
       [string]$Message,     
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='Please specify a valid token for MatterMost API')]
       $MatterToken
       )
   Write-Verbose -Message "Creating header for Authorization"
   $header = @{
       "Authorization" = "Bearer $token"
       }
   Write-Verbose -Message "Created header:`n$($header | Out-String)"
   Write-Verbose -Message "Creating body"
   $body = @{
           "channel_id"= $ChannelID
           "message"= $Message
       } | ConvertTo-Json
   Write-Verbose -Message "Json formatted body created:`n$body"
   Invoke-RestMethod -Method Post -Uri $url -Headers $header -ContentType "text/plain; charset=utf-8" -Body $body

}


function Get-MMProperties
{
    <#
       .SYNOPSIS
       Gets properties from MatterMost
       .DESCRIPTION
       This function gets properties from MatterMost(Ex:teams). For getting a property, first you need to create a token on MattrerMost.
       .EXAMPLE
       New-MMPost -url "http://matterdns:8065/api/v4" -MatterToken $token -MMProperty "teams"
       .PARAMETER url
       Specify the post url of MatterMost API
       .PARAMETER MatterToken
       Specify the token object for MatterMost
       .PARAMETER Property
       Specify the property that you want to see
   #>
   [CmdletBinding()]
   Param (
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost URL')]
           [ValidatePattern('https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.([-a-zA-Z0-9@:%_\+.~#?&//=]*)')]
           [string]$url,         
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='MatterMost property')]
           [string]$MMProperty,
          
       [Parameter(Mandatory=$True,
           ValueFromPipeline=$True,
           ValueFromPipelineByPropertyName=$True,
           HelpMessage='Please specify a valid token for MatterMost API')]
           $MatterToken
       )
   Write-Verbose -Message "Getting '$MMProperty' property from MatterMost"
   $url = $url + $MMProperty
   Write-Verbose -Message "MatterMost URL :$url"
   Write-Verbose -Message "Creating header for Authorization"
   $header = @{
       "Authorization" = "Bearer $token"
       }
   Write-Verbose -Message "Created header:`n$($header | Out-String)"
   Invoke-RestMethod -Method get -Uri $url -Headers $header
}