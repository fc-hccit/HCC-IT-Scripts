# Microsoft 365 Group Creator

![Microsoft 365 Group Creator](icon.ico)

This is the .NET/WPF version of `New-Microsoft365Group.ps1`.

## Run the published app

Open `New-Microsoft365Group.exe` from the `publish` folder. The first connection opens Microsoft sign-in in a browser.

The signed-in account needs delegated Microsoft Graph permissions:

- `User.Read.All`
- `Group.ReadWrite.All`

The original script's `DeviceManagementManagedDevices.Read.All` permission is not needed by this app.

The optional HopeCC alias requires PowerShell 7 and the `ExchangeOnlineManagement` module. Selecting that option opens the normal Exchange Online sign-in flow after the group is created.

## Build

From the repository root:

```powershell
dotnet publish .\New-Microsoft365Group\New-Microsoft365Group.csproj --configuration Release --runtime win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:EnableCompressionInSingleFile=true -p:PublishDir=.\publish\
```
