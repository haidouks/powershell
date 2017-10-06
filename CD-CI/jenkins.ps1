$auth = "userName:password"
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($Auth)
$Base64bytes = [System.Convert]::ToBase64String($Bytes)
$Headers = @{ "Authorization" = "Basic $Base64bytes"}
$url = "Your Project Url" # http://1.1.1.1/job/Sample
$Token = "Token for the project"
Invoke-RestMethod -Uri "$url/build?token=$Token" -Method Post -Headers $Headers
