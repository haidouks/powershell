$verbosepreference = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 5)
{
    Write-Verbose "Installing PSScriptAnalyzer & Pester"
    $AnalyzerModuleNames = "PSScriptAnalyzer","Pester"
    Install-PackageProvider -Name NuGet -Force 
    Install-Module -Name $AnalyzerModuleNames -Scope CurrentUser -Force 
    $PSScriptAnalyzerModule = get-module -Name $AnalyzerModuleNames -ListAvailable
    if ($PSScriptAnalyzerModule) {
        # Import the module if it is available
        Import-Module $AnalyzerModuleNames -Force
    }
    else
    {
        # Module could not/would not be installed - so warn user that tests will fail.
        Write-Warning -Message ( @(
            "The 'PSScriptAnalyzer' module is not installed. "
            "The 'PowerShell modules scriptanalyzer' Pester test will fail "
            ) -Join '' )
    }
}
else
{
    Write-Verbose -Verbose "Skipping installation of PSScriptAnalyzer since it requires PSVersion 5.0 or greater. Used PSVersion: $($PSVersion)"
}
write-verbose -Message "Running ScriptAnalyzer for code quality tests"
Invoke-ScriptAnalyzer -Path $PSScriptRoot 
$Output = Join-Path "$PSScriptRoot\Tests" TestsResults.xml
write-verbose -Message "Running Pester for unit tests"
$res = Invoke-Pester -Path "$PSScriptRoot\Tests" -OutputFormat NUnitXml -OutputFile $Output -PassThru 
if ($res.FailedCount -gt 0) { 
	throw "$($res.FailedCount) unit tests failed."
}
