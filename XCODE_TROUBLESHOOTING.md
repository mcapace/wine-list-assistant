# Xcode Troubleshooting Guide

## Error: "attach by pid failed -- no such process"

This error occurs when Xcode tries to attach to a process that no longer exists. Common causes:

### Solutions:

1. **Clean Build Folder**
   - In Xcode: `Product` → `Clean Build Folder` (Shift+Cmd+K)
   - Or: `Product` → `Clean` (Cmd+K)

2. **Quit and Restart Xcode**
   - Quit Xcode completely (Cmd+Q)
   - Restart Xcode
   - Reopen your project

3. **Reset Simulator/Device**
   - If using Simulator: `Device` → `Erase All Content and Settings`
   - If using physical device: Disconnect and reconnect

4. **Delete Derived Data**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

5. **Kill Zombie Processes**
   ```bash
   killall -9 Xcode
   killall -9 com.apple.CoreSimulator.CoreSimulatorService
   ```

## Error: "Failed to initialize logging system due to time out"

This is a logging system initialization issue.

### Solutions:

1. **Add Environment Variable (Recommended)**
   - In Xcode: `Product` → `Scheme` → `Edit Scheme`
   - Select `Run` → `Arguments` tab
   - Under `Environment Variables`, add:
     - Name: `IDEPreferLogStreaming`
     - Value: `YES`
   - Click `Close`

2. **Restart Xcode**
   - Quit Xcode completely
   - Restart and try again

3. **Reset Simulator**
   - `Device` → `Erase All Content and Settings`

4. **Check Console.app**
   - Open Console.app
   - Look for Xcode-related errors
   - Clear logs if needed

## Quick Fix Checklist

- [ ] Clean Build Folder (Shift+Cmd+K)
- [ ] Quit and Restart Xcode
- [ ] Add `IDEPreferLogStreaming=YES` to scheme
- [ ] Reset Simulator/Device
- [ ] Delete Derived Data
- [ ] Restart Mac (if issues persist)

## Prevention

- Always stop the app properly before rebuilding
- Don't force quit Xcode while debugging
- Keep Xcode updated to latest version

