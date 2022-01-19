Get-ChildItem -Path 'W:\git\conv2mp4\files\functions' -Include "*.ps1" -Recurse |
  ForEach-Object {
    Write-Output "$_"
    . $_
  }

New-Log

Describe "New-Log" {

  It "Given no parameters, will return false" {
    $noParams = New-Log
    $noParams | Should -Be $False
  }


}