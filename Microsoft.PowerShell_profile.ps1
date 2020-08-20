function Prompt {
  $Host.UI.RawUI.WindowTitle = "Fasten your seatbelt !!!"
  Write-Host "♥ " -NoNewline -ForegroundColor DarkRed
  Write-Host "pwsh" -NoNewline -ForegroundColor DarkGreen
  Write-Host '::' -NoNewline
  Write-Host (Split-Path (Get-Location) -Leaf) -NoNewline
  return "$ "
}
