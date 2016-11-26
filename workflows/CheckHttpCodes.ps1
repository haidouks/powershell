workflow HttpCodeCheck-Parallelism
{
Param([string[]]$urls, [int]$threads, [int]$delay)

foreach -Parallel -throttlelimit $threads ($url in $urls)
{
    InlineScript{
        try {
            $statusCode = (Invoke-WebRequest -Uri $using:url -TimeoutSec $using:delay -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
            if ($statusCode -eq 200) {
            Write-Output "$using:url --> Available"
            }
            else {
            Write-Output "$using:url --> Not Available(TimeOut(>$using:delay seconds))"
            }
        } 
        catch {
            Write-Output "$using:url --> Not Available($($_.Exception.Message))"
        }
    }
}
}

$urlList =  @("www.webservicex.net","www.powershelldunyasi.com","asdlkjasdlkj","www.twitter.com","www.hurriyet.com.tr","www.google.com","www.powershell.com","www.linkedin.com","www.facebook.com","stackoverflow.com","www.bing.com","www.onlinemedikalmarket.com") 

HttpCodeCheck-Parallelism -delay 4 -urls-threads 4
