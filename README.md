# Taskbar Animation for Windows 11

<details name="readme-language">
<summary><strong>简体中文</strong></summary>

<a id="readme-zh-cn"></a>

[English](#user-content-readme-en) · **简体中文**

这是一个免安装脚本，可尝试启用自动隐藏任务栏的新版滑动动画。它使用 Windows 11 自带的 Windows PowerShell 和系统功能开关，也可以通过同一个脚本撤销。

## 快速开始

1. 从 [GitHub Releases 下载 `TaskbarAnimation.cmd`](https://github.com/BlackAllenZzz/windows-taskbar-animation/releases/latest/download/TaskbarAnimation.cmd)。也可以在仓库中查看[脚本源码](TaskbarAnimation.cmd)。
2. 在 Windows 的 **设置 → 个性化 → 任务栏 → 任务栏行为** 中开启 **自动隐藏任务栏**。如果之前关过动画，请在 **设置 → 辅助功能 → 视觉效果** 中恢复 **动画效果**。
3. 双击 `TaskbarAnimation.cmd`。菜单默认是英文，输入 **3** 切换到简体中文，再输入 **3** 可切回英文。语言选择仅在当前运行期间有效。
4. 输入 **1**，通过 Windows 的管理员提示，在方便时重启 Windows。
5. 重新打开脚本，查看当前功能标志。把鼠标移到屏幕边缘再移开，分别试一下任务栏滑出和收回。

| 菜单选项 | 操作 |
| --- | --- |
| `1` | 请求启用新版任务栏动画 |
| `2` | 移除脚本写入的覆盖项 |
| `3` | 在英文和简体中文之间切换 |
| `0` | 退出 |

## 撤销改动

双击同一个脚本，输入 **2**，通过管理员提示后重启 Windows。撤销前，脚本会核对归属记录和覆盖项的当前值。如果其他工具改动过该项，脚本会保留现有设置并提示冲突。

## 兼容性与排查

- **Windows 版本。** 脚本会检查已知的 Windows 11 任务栏组件是否包含对应功能 ID，并在写入前查询功能状态。初次本地检查使用的是 **Windows 11 25H2，内部版本 26200.8246**。这是实验功能，可用性会随系统更新变化。找到功能 ID 或看到「启用」，都无法据此确认动画表现。
- **任务栏一直显示。** 先确认 **自动隐藏任务栏** 仍然开启。如果桌面加载完、鼠标也移开后仍不收回，选择 **2** 撤销并重启。初次测试时观察到刚登录后自动隐藏曾短暂延迟。
- **系统未应用。** 如果已有覆盖项、系统保护阻止修改，或无法读取功能状态，脚本会停止。重启后，Windows 也可能未采用已保存的请求。重新打开脚本可查看当前功能标志和保存的覆盖值。
- **刷新率。** 动画由 Windows 渲染。脚本无法指定目标 FPS、测量实际帧率或保证动画与屏幕刷新率同步。

## 命令行

在命令提示符中进入脚本所在目录后运行：

```bat
TaskbarAnimation.cmd status
TaskbarAnimation.cmd apply
TaskbarAnimation.cmd restore
```

`status` 只读取状态，无需管理员权限。普通权限下运行 `apply`、`restore` 或对应的菜单选项时，脚本会先说明为什么需要管理员权限，再打开 Windows 授权提示。如果弹窗无法打开，可以右键点击脚本并选择 **以管理员身份运行**。改动成功后请重启 Windows。不带参数运行会显示数字菜单。

## 脚本修改的位置

脚本通过 `HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\276172940` 的用户优先级启动覆盖项，请求启用功能 ID `41356296`。它还写入独立的归属记录，供撤销时核对。该功能开关属于 Windows 内部设置。脚本使用系统任务栏，无需安装插件或后台服务。

微软在 [Windows Insider 发布说明](https://blogs.windows.com/windows-insider/2025/09/12/announcing-windows-11-insider-preview-build-26220-6682-dev-channel/) 中介绍了新版动画。覆盖项格式参考 [ViVe 源码](https://github.com/thebookisclosed/ViVe/blob/master/ViVe/FeatureManager.cs)，功能 ID 和注册表 ID 的对应关系见[社区实测](https://www.reddit.com/r/Windows11/comments/1tbg6un/)。

本项目采用 [MIT 许可证](LICENSE)。

</details>

<details name="readme-language" open>
<summary><strong>English</strong></summary>

<a id="readme-en"></a>

**English** · [简体中文](#user-content-readme-zh-cn)

A portable Windows script that tries to enable the newer slide animation for an auto-hidden taskbar. It uses a Windows feature flag and runs with the Windows PowerShell included in Windows 11. You can undo the change from the same script.

## Quick start

1. Download [`TaskbarAnimation.cmd` from GitHub Releases](https://github.com/BlackAllenZzz/windows-taskbar-animation/releases/latest/download/TaskbarAnimation.cmd). You can also [view the script source](TaskbarAnimation.cmd).
2. In Windows, open **Settings → Personalization → Taskbar → Taskbar behaviors** and turn on **Automatically hide the taskbar**. If you previously turned off animations, turn them back on under **Settings → Accessibility → Visual effects**.
3. Double-click `TaskbarAnimation.cmd`. The menu starts in English. Enter **3** for Simplified Chinese, or enter **3** again to return to English. The choice applies to the current session.
4. Enter **1**, approve the Windows administrator prompt, and restart Windows when you are ready.
5. Reopen the script to see the current feature flag. Move the pointer to the edge of the screen and then away to check both transitions.

| Menu option | Action |
| --- | --- |
| `1` | Request the newer taskbar animation |
| `2` | Remove the override created by this script |
| `3` | Switch between English and Simplified Chinese |
| `0` | Exit |

## Undo the change

Double-click the same file, enter **2**, approve the administrator prompt, and restart Windows. Restore checks the script’s ownership record and the override’s current values before removing them. If another tool changed the override, the script leaves it in place and reports the conflict.

## Compatibility and troubleshooting

- **Windows builds.** The script checks for the feature ID in known Windows 11 taskbar components and queries the feature state before writing. Windows 11 25H2 build **26200.8246** was used for the initial local check. The feature is experimental and availability varies across Windows updates. The presence of the ID or an enabled flag does not verify that the animation is working.
- **The taskbar stays visible.** Check that **Automatically hide the taskbar** is still on. If it stays visible after the desktop has loaded and the pointer has moved away, use **2** and restart. A temporary delay in auto-hide was observed just after signing in on the initial test system.
- **Windows rejects the change.** An existing override, a Windows safeguard, or missing feature data can stop the script. Windows may also ignore a saved request after a restart. Reopen the script to see the runtime flag and the saved override.
- **Refresh rate.** Windows controls how the animation renders. The script does not set a target FPS, measure frames, or guarantee synchronization with the display.

## Command line

Run these from the directory containing the file in Command Prompt:

```bat
TaskbarAnimation.cmd status
TaskbarAnimation.cmd apply
TaskbarAnimation.cmd restore
```

`status` is read-only and needs no administrator access. When you use `apply`, `restore`, or the equivalent menu option without administrator access, the script explains why it needs access and opens the Windows prompt. If the prompt cannot open, you can right-click the file and choose **Run as administrator**. Restart Windows after a successful change. Running with no argument opens the numbered menu.

## What changes

The script requests feature ID `41356296` through the user-priority boot override at `HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\276172940`. It writes a separate ownership record so it can remove its own change. The feature is an internal Windows setting. The script uses the built-in taskbar and does not install a plugin or a background service.

Microsoft described the newer transition in the [Windows Insider release notes](https://blogs.windows.com/windows-insider/2025/09/12/announcing-windows-11-insider-preview-build-26220-6682-dev-channel/). See the [ViVe source](https://github.com/thebookisclosed/ViVe/blob/master/ViVe/FeatureManager.cs) for the feature override registry format and the [community report](https://www.reddit.com/r/Windows11/comments/1tbg6un/) for the ID mapping.

Distributed under the [MIT License](LICENSE).

</details>
