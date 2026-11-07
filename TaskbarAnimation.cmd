@echo off
setlocal DisableDelayedExpansion
set "CODEX_TASKBAR_SCRIPT=%~f0"
set "CODEX_TASKBAR_MODE=%~1"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "$p=$env:CODEX_TASKBAR_SCRIPT; $s=[IO.File]::ReadAllText($p); $m=[regex]::Match($s,'(?m)^#<TASKBAR_PS>\r?$'); if(!$m.Success){exit 2}; & ([scriptblock]::Create($s.Substring($m.Index+$m.Length))) -Path $p -Mode $env:CODEX_TASKBAR_MODE"
exit /b %errorlevel%
#<TASKBAR_PS>
param(
    [string]$Path,
    [string]$Mode,
    [ValidateSet('en', 'zh-CN')][string]$Language = 'en',
    [switch]$PauseOnExit
)

$ErrorActionPreference = 'Stop'
# Windows 11's private auto-hide animation feature, using the user-priority store.
# Registry format: https://github.com/thebookisclosed/ViVe/blob/master/ViVe/FeatureManager.cs
# Feature ID and its registry ID: https://www.reddit.com/r/Windows11/comments/1tbg6un/
$featureId = [uint32]41356296
$registryId = '276172940'
$overrideRoot = 'SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides'
$userOverride = "$overrideRoot\8\$registryId"
$ownerKey = 'SYSTEM\CurrentControlSet\Control\CodexTaskbarAnimation_41356296'
$ownerToken = 'Codex.TaskbarAnimation.41356296.v1'
$launchedElevated = $false
$messages = @{
    en = @{
        States = @('Default', 'Disabled', 'Enabled')
        UnknownShell = 'The feature ID was not found in the expected taskbar components. Apply is unavailable.'
        Runtime = 'Runtime feature flag: {0} (priority {1})'
        UnknownRuntime = 'The runtime feature flag could not be read.'
        BootOverride = 'User-priority boot override: {0} (2 requests enablement)'
        Pending = 'The requested state is not active. If you already restarted, Windows did not apply it.'
        ChangedOverride = 'The override was modified elsewhere. Its current values have been kept.'
        Unsupported = 'The taskbar components are outside the recognized set.'
        UnknownState = 'The Windows feature state could not be confirmed.'
        AlreadyManaged = 'A script record already exists. Use Restore before reapplying.'
        ExternalOverride = 'An existing user-priority override has been kept.'
        AlreadyEnabled = 'The feature flag is already enabled.'
        ProtectedOverride = 'Windows has a safeguard or an override at user priority or higher.'
        Blocked = 'Windows has a higher-priority setting that disables this feature.'
        Applied = 'Boot override saved. Restart Windows and reopen this script to check the runtime flag.'
        AdminRequired = 'Changing the taskbar setting requires administrator access. Approve the Windows prompt to continue.'
        AdminFailed = 'Administrator access was not granted or the prompt could not open. To retry, right-click the script and choose Run as administrator. Windows reported: {0}'
        Busy = 'Another instance is changing the setting.'
        Restored = 'The script override was removed. Restart Windows to finish restoring the default.'
        NoOverride = 'No override created by this script was found.'
        Menu = @('1  Enable newer taskbar animation (experimental)', '2  Restore Windows default', '3  Switch language / 切换到简体中文', '0  Exit')
        Select = 'Enter a number'
        InvalidChoice = 'Choose 1, 2, 3, or 0.'
        Commands = 'Available commands: status, apply, restore.'
        Close = 'Press Enter to close'
    }
    'zh-CN' = @{
        States = @('默认', '禁用', '启用')
        UnknownShell = '未在已知的任务栏组件中找到这个功能标识，无法启用。'
        Runtime = '本次启动的功能标志：{0}，优先级 {1}'
        UnknownRuntime = '无法读取本次启动的功能标志。'
        BootOverride = '用户级启动覆盖值：{0}（2 表示请求启用）'
        Pending = '请求尚未生效。如果已经重启，表示 Windows 未采用该请求。'
        ChangedOverride = '覆盖项已被其他操作改动，已保留现有设置。'
        Unsupported = '当前任务栏组件不在可识别范围内。'
        UnknownState = '无法确认此版本的功能状态。'
        AlreadyManaged = '已有脚本记录。如需重新应用，请先选「撤销」。'
        ExternalOverride = '已保留其他工具或用户设置的覆盖项。'
        AlreadyEnabled = '这个功能标志已经启用。'
        ProtectedOverride = '检测到系统保护，或已有优先级不低于用户设置的覆盖项。'
        Blocked = 'Windows 有优先级更高的设置禁用了此功能。'
        Applied = '已写入启动覆盖项。请重启 Windows，然后重新打开脚本检查功能标志。'
        AdminRequired = '修改任务栏设置需要管理员权限。请在 Windows 弹窗中允许后继续。'
        AdminFailed = '未获得管理员权限，或 Windows 无法打开授权提示。若要重试，请右键点击脚本并选择「以管理员身份运行」。Windows 返回：{0}'
        Busy = '另一个脚本实例正在更改设置。'
        Restored = '已移除脚本写入的覆盖项。请重启 Windows 以恢复默认行为。'
        NoOverride = '没有找到由此脚本写入的覆盖项。'
        Menu = @('1  启用新版任务栏动画（实验功能）', '2  撤销脚本改动', '3  切换语言 / Switch to English', '0  退出')
        Select = '请输入数字'
        InvalidChoice = '请选择 1、2、3 或 0。'
        Commands = '可用命令：status、apply、restore。'
        Close = '按回车关闭'
    }
}
$ui = $messages[$Language]

function Get-FeatureState([int]$Store) {
    if (-not ('CodexTaskbarFeature' -as [type])) {
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;

public static class CodexTaskbarFeature {
    [StructLayout(LayoutKind.Sequential)]
    public struct Configuration {
        public uint Id, Flags, VariantPayload;
    }

    [DllImport("ntdll.dll")]
    public static extern int RtlQueryFeatureConfiguration(
        uint id, int store, out ulong stamp, out Configuration configuration);
}
'@
    }

    $stamp = [uint64]0
    $config = New-Object 'CodexTaskbarFeature+Configuration'
    $result = [CodexTaskbarFeature]::RtlQueryFeatureConfiguration($featureId, $Store, [ref]$stamp, [ref]$config)
    if ($result -ne 0 -or $config.Id -ne $featureId) { return $null }
    [pscustomobject]@{ State = ($config.Flags -shr 4) -band 3; Priority = $config.Flags -band 15 }
}

function Test-FeatureInFile([string]$File) {
    if (-not [IO.File]::Exists($File)) { return $false }
    $encoding = [Text.Encoding]::GetEncoding(28591)
    $signature = $encoding.GetString([BitConverter]::GetBytes($featureId))
    $encoding.GetString([IO.File]::ReadAllBytes($File)).Contains($signature)
}

function Test-KnownShell {
    if ($build -lt 26100) { return $false }
    $taskbar = Join-Path $env:windir 'System32\Taskbar.dll'
    $view = Join-Path $env:windir 'SystemApps\MicrosoftWindows.Client.Core_cw5n1h2txyewy\Taskbar.View.dll'
    (Test-FeatureInFile $taskbar) -and (Test-FeatureInFile $view)
}

function Show-Status {
    Write-Host "Windows $($windows.DisplayVersion) ($build.$($windows.UBR))"
    if (-not (Test-KnownShell)) {
        Write-Host $ui.UnknownShell
    }
    if ($build -ge 26100) {
        $current = Get-FeatureState 1
        if ($null -ne $current) {
            Write-Host ($ui.Runtime -f $ui.States[$current.State], $current.Priority)
        } else {
            Write-Host $ui.UnknownRuntime
        }
    }
    $entry = $registry.OpenSubKey($userOverride)
    if ($null -ne $entry) {
        try { $requested = $entry.GetValue('EnabledState') }
        finally { $entry.Dispose() }
        Write-Host ($ui.BootOverride -f $requested)
        if ($requested -eq 2 -and $null -ne $current -and $current.State -ne 2) {
            Write-Host $ui.Pending
        }
    }
}

function Read-Owner {
    $key = $registry.OpenSubKey($ownerKey)
    if ($null -eq $key) { return $null }
    try { $key.GetValue('Owner', '') }
    finally { $key.Dispose() }
}

function Remove-OwnOverride {
    $entry = $registry.OpenSubKey($userOverride)
    if ($null -ne $entry) {
        try {
            $expected = @{ EnabledState = 2; EnabledStateOptions = 0 }
            foreach ($name in $entry.GetValueNames()) {
                if (-not $expected.ContainsKey($name) -or
                    $entry.GetValueKind($name) -ne [Microsoft.Win32.RegistryValueKind]::DWord -or
                    $entry.GetValue($name) -ne $expected[$name]) {
                    throw $ui.ChangedOverride
                }
            }
        } finally { $entry.Dispose() }
        $registry.DeleteSubKey($userOverride, $false)
    }
    $registry.DeleteSubKey($ownerKey, $false)
}

function Enable-Animation {
    if (-not (Test-KnownShell)) { throw $ui.Unsupported }
    $boot = Get-FeatureState 0
    $runtime = Get-FeatureState 1
    if ($null -eq $boot -or $null -eq $runtime) { throw $ui.UnknownState }

    if ($null -ne (Read-Owner)) { throw $ui.AlreadyManaged }
    $existing = $registry.OpenSubKey($userOverride)
    if ($null -ne $existing) {
        $existing.Dispose()
        throw $ui.ExternalOverride
    }
    if ($boot.State -eq 2 -and $runtime.State -eq 2) {
        Write-Host $ui.AlreadyEnabled
        return
    }
    foreach ($config in @($boot, $runtime)) {
        if ($config.Priority -ge 8 -or ($config.Priority -eq 2 -and $config.State -eq 1)) {
            throw $ui.ProtectedOverride
        }
    }
    foreach ($priority in @(2) + (9..15)) {
        $protected = $registry.OpenSubKey("$overrideRoot\$priority\$registryId")
        if ($null -eq $protected) { continue }
        try {
            if ($protected.GetValue('EnabledState') -eq 1) {
                throw $ui.Blocked
            }
        } finally { $protected.Dispose() }
    }

    $marker = $registry.CreateSubKey($ownerKey)
    try { $marker.SetValue('Owner', $ownerToken, [Microsoft.Win32.RegistryValueKind]::String) }
    finally { $marker.Dispose() }

    try {
        $entry = $registry.CreateSubKey($userOverride)
        try {
            $entry.SetValue('EnabledStateOptions', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
            $entry.SetValue('EnabledState', 2, [Microsoft.Win32.RegistryValueKind]::DWord)
        } finally { $entry.Dispose() }
    } catch {
        Remove-OwnOverride
        throw
    }
    Write-Host $ui.Applied
}

function Invoke-Change([string]$Action) {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host $ui.AdminRequired
        $quotedPath = "'" + $Path.Replace("'", "''") + "'"
        $command = @"
`$p = $quotedPath
`$s = [IO.File]::ReadAllText(`$p)
`$m = [regex]::Match(`$s, '(?m)^#<TASKBAR_PS>\r?$')
if (!`$m.Success) { exit 2 }
& ([scriptblock]::Create(`$s.Substring(`$m.Index + `$m.Length))) -Path `$p -Mode '$Action' -Language '$Language' -PauseOnExit
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        try {
            $child = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -Verb RunAs `
                -ArgumentList '-NoLogo', '-NoProfile', '-EncodedCommand', $encoded -Wait -PassThru
        } catch {
            throw ($ui.AdminFailed -f $_.Exception.Message)
        }
        $script:launchedElevated = $true
        return $child.ExitCode
    }

    $mutex = New-Object Threading.Mutex($false, 'Global\CodexTaskbarAnimation_41356296')
    $locked = $false
    try {
        try { $locked = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { throw $ui.Busy }
        if ($Action -eq 'apply') {
            Enable-Animation
        } elseif ((Read-Owner) -eq $ownerToken) {
            Remove-OwnOverride
            Write-Host $ui.Restored
        } else {
            Write-Host $ui.NoOverride
        }
        return 0
    } finally {
        if ($locked) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

$result = 0
$menu = [string]::IsNullOrEmpty($Mode)
try {
    $registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $windows = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $build = [int]$windows.CurrentBuild

    while ([string]::IsNullOrEmpty($Mode)) {
        Show-Status
        Write-Host ''
        $ui.Menu | ForEach-Object { Write-Host $_ }
        $choice = Read-Host $ui.Select
        if ($null -eq $choice) {
            $Mode = 'exit'
            break
        }
        switch ($choice.Trim()) {
            '1' { $Mode = 'apply' }
            '2' { $Mode = 'restore' }
            '3' {
                if ($Language -eq 'en') { $Language = 'zh-CN' }
                else { $Language = 'en' }
                $ui = $messages[$Language]
                Write-Host ''
            }
            '0' { $Mode = 'exit' }
            default { Write-Host $ui.InvalidChoice -ForegroundColor Yellow }
        }
    }

    switch ($Mode) {
        'status'  { Show-Status }
        'apply'   { $result = Invoke-Change 'apply' }
        'restore' { $result = Invoke-Change 'restore' }
        'exit'    { }
        default   { throw $ui.Commands }
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    $result = 1
} finally {
    if ($null -ne $registry) { $registry.Dispose() }
    if ($PauseOnExit -or ($menu -and $Mode -ne 'exit' -and -not $launchedElevated)) {
        $null = Read-Host $ui.Close
    }
}
exit $result
