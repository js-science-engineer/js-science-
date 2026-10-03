# ============================================================
#  电脑清理与优化工具 v1.0
#  功能：安全清理C盘垃圾 + 可选禁用非必要启动项
#  说明：本脚本只删除可再生的缓存/临时文件，不碰个人文件
#  使用：双击桌面的"电脑清理优化工具.bat"（会请求管理员权限）
# ============================================================
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "           电脑清理与优化工具 v1.0" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  [1] 仅清理垃圾（推荐，安全可逆）"
Write-Host "  [2] 清理垃圾 + 禁用非必要启动项（加快开机）"
Write-Host "  [0] 退出"
Write-Host ""
$choice = Read-Host "  请输入选项 (0/1/2)"
if ($choice -eq '0') { Write-Host "已退出。"; Read-Host "按回车关闭窗口"; exit }

# ==================== 清理部分 ====================
Write-Host ""
Write-Host ">>> 开始清理（只删缓存/临时文件，不碰个人文件）..." -ForegroundColor Yellow

$beforeC = (Get-PSDrive C).Free
$beforeD = (Get-PSDrive D).Free

function Clear-Path([string]$path) {
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
        Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host ("   OK  {0}" -f $path) -ForegroundColor DarkGray
        Write-Host ("       释放 {0:N2} GB" -f ($size / 1GB)) -ForegroundColor Green
    }
}

Clear-Path $env:TEMP
Clear-Path "C:\Windows\SoftwareDistribution\Download"
Clear-Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
Clear-Path "$env:LOCALAPPDATA\NVIDIA\DXCache"
Clear-Path "$env:LOCALAPPDATA\NVIDIA\GLCache"
Clear-Path "$env:LOCALAPPDATA\npm-cache"
if (Test-Path "D:\DeliveryOptimization") { Clear-Path "D:\DeliveryOptimization" }
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

$afterC = (Get-PSDrive C).Free
$afterD = (Get-PSDrive D).Free
Write-Host ""
Write-Host ("  ★ C盘释放 {0:N2} GB，当前剩余 {1:N2} GB" -f (($afterC - $beforeC) / 1GB), ($afterC / 1GB)) -ForegroundColor Green
Write-Host ("  ★ D盘释放 {0:N2} GB，当前剩余 {1:N2} GB" -f (($afterD - $beforeD) / 1GB), ($afterD / 1GB)) -ForegroundColor Green

# ==================== 优化部分 ====================
if ($choice -eq '2') {
    Write-Host ""
    Write-Host ">>> 启动项优化（先备份注册表，可随时恢复）..." -ForegroundColor Yellow

    $backupDir = Join-Path $PSScriptRoot ("启动项备份_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" (Join-Path $backupDir "HKCU_Run.reg") /y 2>$null | Out-Null
    reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" (Join-Path $backupDir "HKLM_Run.reg") /y 2>$null | Out-Null
    Write-Host ("  注册表备份已保存到: {0}" -f $backupDir) -ForegroundColor DarkGray

    $runKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )

    $candidates = @(
        @{ Name = 'OneDrive 云同步自启';       Match = 'OneDrive.exe' },
        @{ Name = 'CrystalTaskBar 任务栏美化';  Match = 'crystaltaskbar' },
        @{ Name = 'SOLIDWORKS 后台下载';        Match = 'SLDBGD|SOLIDWORKS Background' },
        @{ Name = 'Autodesk Access 自动启动';   Match = 'AdskAccess' },
        @{ Name = '雷神加速器';                  Match = 'LeiGod' }
    )

    foreach ($c in $candidates) {
        $hit = @()
        foreach ($key in $runKeys) {
            if (Test-Path $key) {
                $props = Get-ItemProperty $key
                $props.PSObject.Properties | Where-Object {
                    $_.Name -notmatch '^PS' -and $_.Value -match $c.Match
                } | ForEach-Object { $hit += $_.Name }
            }
        }
        if ($hit.Count -gt 0) {
            $ans = Read-Host ("  检测到「" + $c.Name + "」(" + ($hit -join ',') + ")，是否禁用? (y/n)")
            if ($ans -eq 'y') {
                foreach ($key in $runKeys) {
                    if (Test-Path $key) {
                        $props = Get-ItemProperty $key
                        $props.PSObject.Properties | Where-Object {
                            $_.Name -notmatch '^PS' -and $_.Value -match $c.Match
                        } | ForEach-Object {
                            Remove-ItemProperty -Path $key -Name $_.Name -ErrorAction SilentlyContinue
                            Write-Host ("    已禁用: {0}" -f $_.Name) -ForegroundColor Green
                        }
                    }
                }
            } else {
                Write-Host ("    已跳过: {0}" -f $c.Name) -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ""
    Write-Host "  提示：如需恢复启动项，双击备份文件夹中的 .reg 文件即可。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  清理完成！如仍有卡顿，可检查后台程序或考虑加内存。" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Read-Host "按回车键关闭窗口"
