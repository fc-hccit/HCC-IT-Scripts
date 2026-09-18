# PowerShell App Creator

Use the published app to turn a PowerShell script into a Windows executable.

1. Browse to a `.ps1` file.
2. Browse to an `.ico` file.
3. Choose the output `.exe` path.
4. Select **Create EXE**.

The app creates an in-house .NET wrapper project, embeds the script, applies the selected icon, and publishes a single-file Windows executable. It does not require the `ps2exe` module.

The published creator executable is in the `publish` folder and is self-contained for Windows x64. The .NET SDK is required on the creator computer. PowerShell is required by the generated application when it runs.
