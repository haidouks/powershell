$email=$env:email
$verbose=[System.Convert]::ToBoolean($env:details)
$user=$env:BUILD_USER
$password=$env:password
$sendMail=[System.Convert]::ToBoolean($env:sendMail)
$env:ADPS_LoadDefaultDrive = 0
$PSModuleAutoloadingPreference = “none”
import-module ActiveDirectory -Cmdlet Get-ADUser,Unlock-ADAccount,Set-ADAccountPassword

function Reset-Password
{
Param(
   [Parameter(Mandatory=$True,Position=1)]
   $userEmail,
   [Parameter(Mandatory=$True,Position=2)]
   $password,
   [Parameter(Mandatory=$False)]
   [switch]$info=$false
)
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Reset request received for user :`n$userEmail" -verbose:$info
    $userId = Get-ADUser -Filter {Emailaddress -eq $userEmail} | Select-Object -ExpandProperty SamAccountName
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Parsed user id from Email :`n$userId" -verbose:$info
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Starting to create random password" -verbose:$info
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Received password($password), secure conversion is on fly" -verbose:$info
    $securePass = ConvertTo-SecureString –String $password –AsPlainText –Force
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Updating user password" -verbose:$info
    Set-ADAccountPassword -Identity $userId -NewPassword $securePass
    Set-aduser $userId -changepasswordatlogon $true 
    Write-Host "####################################"
    Write-Host "#########Password:$password#########"
    $url = $("http://jenkins.hurriyet.com.tr/view/ActiveDirectory/job/$ENV:JOB_NAME/$ENV:BUILD_ID/console").replace(" ","%20")
    Write-Host "####################################"
    if($sendMail)
    {
    Write-Verbose "$(get-date -Format "dd/MM/yyyy HH:mm") - Function:$($MyInvocation.MyCommand) - Sending mail to $($env:BUILD_USER_EMAIL)" -verbose:$info
    Send-MailMessage -Subject "Kullanıcı Şifre Resetleme - $email" -Body "$user tarafından $email kullanıcısı için şifre resetleme işlemi yapılmıştır. `nDetaylı bilgiye $url linki üzerinden ulaşabilirsiniz" -SmtpServer "hursmtp01.hurriyet.do.net.tr" -To "$env:BUILD_USER_EMAIL" -From "jenkinsADAutomation@hurriyet.com.tr" -Cc "maktas@hurriyet.com.tr","bilisim@hurriyet.com.tr" -Encoding ([System.Text.Encoding]::UTF8)
    }
}


try
{
    Reset-Password -userEmail $email -password $password -info:$verbose
}
catch
{
    $errorMessage = "$($_.Exception.Message)`n$(($_|select -ExpandProperty invocationinfo).PositionMessage)"
    Write-Warning -Message "Catched an exception in Function:$($MyInvocation.MyCommand)`n$errorMessage" -Verbose:$true
    Exit 1
}
