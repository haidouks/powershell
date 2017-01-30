$path = 'C:\Users\cnsn\Downloads\cnsn\cnsn\data.sql' #path for source text
$r = [IO.File]::OpenText($path)
while ($r.Peek() -ge 0) {
    $line = $r.ReadLine()
    if($line.Contains("Cansin") -and $line.Contains("ISTANBUL") -and $line.Contains("DENEME") )
    {
        $line
    }
    # Process $line here...
}
$r.Dispose()
