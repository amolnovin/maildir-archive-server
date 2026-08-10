<#
.SYNOPSIS
    نمایش فهرست دامنه‌ها، اکانت‌ها، تعداد پیام و حجم هر mailbox.
.EXAMPLE
    .\Get-Mailboxes.ps1
    .\Get-Mailboxes.ps1 -Domain komajsaba.com
#>
param(
    [string]$Domain
)

. "$PSScriptRoot\Common.ps1"

$users = Get-UsersTable
$report = @()

$domains = Get-ChildItem -Path $MailRoot -Directory -Force -ErrorAction SilentlyContinue
if ($Domain) { $domains = $domains | Where-Object { $_.Name -eq $Domain.ToLower() } }

foreach ($d in $domains) {
    foreach ($u in Get-ChildItem -Path $d.FullName -Directory -Force -ErrorAction SilentlyContinue) {
        $maildir = Join-Path $u.FullName "Maildir"
        $count = 0
        if (Test-Path $maildir) {
            $count = @(Get-ChildItem -Path $maildir -Recurse -File -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Directory.Name -in @('cur','new') }).Count
        }
        $email = "$($u.Name)@$($d.Name)"
        $report += [pscustomobject]@{
            Email      = $email
            Domain     = $d.Name
            Messages   = $count
            SizeMB     = Get-FolderSizeMB -Path $maildir
            HasAccount = [bool]($users | Where-Object { $_.Email -eq $email })
        }
    }
}

if ($report.Count -eq 0) {
    Write-Warn2 "هیچ mailbox ای پیدا نشد. ابتدا بکاپ را import کنید."
    exit 0
}

$report | Sort-Object Domain, Email | Format-Table -AutoSize
Write-Host ""
Write-Ok ("مجموع: {0} اکانت — {1} پیام — {2} MB" -f `
    $report.Count, ($report | Measure-Object Messages -Sum).Sum, ($report | Measure-Object SizeMB -Sum).Sum)

$noAcc = $report | Where-Object { -not $_.HasAccount }
if ($noAcc) {
    Write-Host ""
    Write-Warn2 "این mailboxها فایل روی دیسک دارند ولی رمز/اکانت ندارند (با Add-User.ps1 بسازید):"
    $noAcc | ForEach-Object { Write-Host "   - $($_.Email)" }
}
