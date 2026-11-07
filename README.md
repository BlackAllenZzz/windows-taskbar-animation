# Taskbar Animation for Windows 11

**English** · [简体中文](README.zh-CN.md)

A portable Windows script that tries to enable the newer slide animation for an auto-hidden taskbar. It uses a Windows feature flag and runs with the Windows PowerShell included in Windows 11. You can undo the change from the same script.

## Quick start

1. Download [`TaskbarAnimation.cmd`](TaskbarAnimation.cmd) using GitHub’s **Download raw file** button.
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

`status` is read-only. `apply` and `restore` request administrator access and require a restart to finish. Running with no argument opens the numbered menu.

## What changes

The script requests feature ID `41356296` through the user-priority boot override at `HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\276172940`. It writes a separate ownership record so it can remove its own change. The feature is an internal Windows setting. The script uses the built-in taskbar and does not install a plugin or a background service.

Microsoft described the newer transition in the [Windows Insider release notes](https://blogs.windows.com/windows-insider/2025/09/12/announcing-windows-11-insider-preview-build-26220-6682-dev-channel/). See the [ViVe source](https://github.com/thebookisclosed/ViVe/blob/master/ViVe/FeatureManager.cs) for the feature override registry format and the [community report](https://www.reddit.com/r/Windows11/comments/1tbg6un/) for the ID mapping.

Distributed under the [MIT License](LICENSE).
