<#PowerShell deletion script that looks at folder time stamp and not on files
https://stackoverflow.com/questions/37016970/powershell-deletion-script-that-looks-at-folder-time-stamp-and-not-on-files
"D:\Program Files\RepliWeb\RDS\Satellite\Jobs"
#>
$dump_path = ".\"
$max_days = "-10"
$curr_date = Get-Date
$del_date = $curr_date.AddDays($max_days)
Get-ChildItem $dump_path -Recurse -Directory | 
    Where-Object {$_.LastWriteTime -lt $del_date } |   Remove-Item -Recurse -Confirm:$False -Force -whatif