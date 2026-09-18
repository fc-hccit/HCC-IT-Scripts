using System.Diagnostics;
using System.IO;
using System.Text;
using Microsoft.Win32;

namespace PowerShellAppCreator;

public partial class MainWindow : System.Windows.Window
{
    public MainWindow()
    {
        InitializeComponent();
        BrowseScript.Click += (_, _) => SelectScript();
        BrowseIcon.Click += (_, _) => SelectIcon();
        BrowseOutput.Click += (_, _) => SelectOutput();
        GenerateButton.Click += async (_, _) => await GenerateAsync();
    }

    private void SelectScript()
    {
        var dialog = new OpenFileDialog { Filter = "PowerShell scripts (*.ps1)|*.ps1", Title = "Select PowerShell script" };
        if (dialog.ShowDialog() != true) return;
        ScriptPath.Text = dialog.FileName;
        if (string.IsNullOrWhiteSpace(OutputPath.Text)) OutputPath.Text = System.IO.Path.Combine(System.IO.Path.GetDirectoryName(dialog.FileName)!, System.IO.Path.GetFileNameWithoutExtension(dialog.FileName) + ".exe");
        UpdateState();
    }

    private void SelectIcon()
    {
        var dialog = new OpenFileDialog { Filter = "Icon files (*.ico)|*.ico", Title = "Select application icon" };
        if (dialog.ShowDialog() == true) { IconPath.Text = dialog.FileName; UpdateState(); }
    }

    private void SelectOutput()
    {
        var dialog = new SaveFileDialog { Filter = "Windows executable (*.exe)|*.exe", DefaultExt = ".exe", Title = "Choose generated executable" };
        if (dialog.ShowDialog() == true) { OutputPath.Text = dialog.FileName; UpdateState(); }
    }

    private void UpdateState() => GenerateButton.IsEnabled = File.Exists(ScriptPath.Text) && File.Exists(IconPath.Text) && !string.IsNullOrWhiteSpace(OutputPath.Text);

    private async Task GenerateAsync()
    {
        if (!UpdatePaths()) return;
        SetBusy(true, "Compiling in-house .NET wrapper...");
        var result = await BuildWrapperAsync(ScriptPath.Text, IconPath.Text, OutputPath.Text);
            SetBusy(false, result.ExitCode == 0 && File.Exists(OutputPath.Text) ? "EXE created: " + OutputPath.Text : "Creation failed: " + result.Output);
        if (result.ExitCode == 0 && File.Exists(OutputPath.Text)) System.Windows.MessageBox.Show("The PowerShell script was embedded into a new .NET executable.", "App created", System.Windows.MessageBoxButton.OK, System.Windows.MessageBoxImage.Information);
    }

    private bool UpdatePaths()
    {
        if (!File.Exists(ScriptPath.Text)) { SetStatus("Select a valid .ps1 script."); return false; }
        if (!File.Exists(IconPath.Text) || !IconPath.Text.EndsWith(".ico", StringComparison.OrdinalIgnoreCase)) { SetStatus("Select a valid .ico file."); return false; }
        if (!OutputPath.Text.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) OutputPath.Text += ".exe";
        return true;
    }

    private static async Task<PowerShellResult> BuildWrapperAsync(string scriptPath, string iconPath, string outputPath)
    {
        var dotnet = Environment.GetEnvironmentVariable("DOTNET_ROOT") is not null ? "dotnet" : "dotnet.exe";
        var tempRoot = Path.Combine(Path.GetTempPath(), "PowerShellAppCreator", Guid.NewGuid().ToString("N")); Directory.CreateDirectory(tempRoot);
        var projectOutput = Path.Combine(tempRoot, "publish");
        var scriptBase64 = Convert.ToBase64String(await File.ReadAllBytesAsync(scriptPath));
        var program = $$"""
            using System.Diagnostics;
            using System.IO;
            internal static class Program
            {
                [STAThread]
                private static int Main(string[] args)
                {
                    var script = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".ps1");
                    File.WriteAllBytes(script, Convert.FromBase64String("{{scriptBase64}}"));
                    try
                    {
                        var start = new ProcessStartInfo("powershell.exe") { UseShellExecute = false, CreateNoWindow = true };
                        start.ArgumentList.Add("-NoProfile");
                        start.ArgumentList.Add("-ExecutionPolicy");
                        start.ArgumentList.Add("Bypass");
                        start.ArgumentList.Add("-File");
                        start.ArgumentList.Add(script);
                        foreach (var arg in args) start.ArgumentList.Add(arg);
                        using var process = Process.Start(start);
                        if (process is null) return 1;
                        process.WaitForExit();
                        return process.ExitCode;
                    }
                    finally { try { File.Delete(script); } catch { } }
                }
            }
            """;
            var project = $"<Project Sdk=\"Microsoft.NET.Sdk\"><PropertyGroup><OutputType>WinExe</OutputType><TargetFramework>net10.0-windows</TargetFramework><EnableDefaultApplicationDefinition>false</EnableDefaultApplicationDefinition><ApplicationIcon>app.ico</ApplicationIcon><AssemblyName>{Path.GetFileNameWithoutExtension(outputPath)}</AssemblyName><Nullable>enable</Nullable><ImplicitUsings>enable</ImplicitUsings></PropertyGroup><ItemGroup><Content Include=\"app.ico\" /></ItemGroup></Project>";
        await File.WriteAllTextAsync(Path.Combine(tempRoot, "Program.cs"), program, Encoding.UTF8); await File.WriteAllTextAsync(Path.Combine(tempRoot, "Wrapper.csproj"), project, Encoding.UTF8); File.Copy(iconPath, Path.Combine(tempRoot, "app.ico"));
        var start = new ProcessStartInfo(dotnet) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true, WorkingDirectory = tempRoot };
        start.ArgumentList.Add("publish"); start.ArgumentList.Add("Wrapper.csproj"); start.ArgumentList.Add("--configuration"); start.ArgumentList.Add("Release"); start.ArgumentList.Add("--runtime"); start.ArgumentList.Add("win-x64"); start.ArgumentList.Add("--self-contained"); start.ArgumentList.Add("true"); start.ArgumentList.Add("-p:PublishSingleFile=true"); start.ArgumentList.Add("-p:IncludeNativeLibrariesForSelfExtract=true"); start.ArgumentList.Add("-p:EnableCompressionInSingleFile=true"); start.ArgumentList.Add("--output"); start.ArgumentList.Add(projectOutput);
        using var process = Process.Start(start) ?? throw new InvalidOperationException("The .NET SDK could not be started.");
        var outputTask = process.StandardOutput.ReadToEndAsync(); var errorTask = process.StandardError.ReadToEndAsync(); await process.WaitForExitAsync();
        var output = (await outputTask + " " + await errorTask).Trim(); var builtExe = Path.Combine(projectOutput, Path.GetFileName(outputPath)); if (process.ExitCode == 0 && File.Exists(builtExe)) File.Copy(builtExe, outputPath, true); return new PowerShellResult(process.ExitCode, string.IsNullOrWhiteSpace(output) ? "No details were returned." : output);
    }

    private void SetBusy(bool busy, string status)
    {
        BrowseScript.IsEnabled = !busy; BrowseIcon.IsEnabled = !busy; BrowseOutput.IsEnabled = !busy; GenerateButton.IsEnabled = !busy && File.Exists(ScriptPath.Text) && File.Exists(IconPath.Text); SetStatus(status, busy ? false : status.StartsWith("EXE created", StringComparison.Ordinal));
    }

    private void SetStatus(string message, bool success = false) { StatusText.Text = message; StatusText.Foreground = success ? System.Windows.Media.Brushes.DarkGreen : System.Windows.Media.Brushes.Firebrick; }

    private sealed record PowerShellResult(int ExitCode, string Output);
}
