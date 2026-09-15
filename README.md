# Remote File Access for Intune-Managed Windows 11 Devices

This solution enables the minimum local configuration required for remote administrative SMB access to built-in administrative shares such as `\\PC123\C$` from authorised IT workstations on the local network.

It does not modify Windows LAPS, local administrator accounts, passwords, SMBv1, SMB signing, NTLM settings, UAC policy, or unrelated firewall rules.

## What must change for `\\PC-NAME\C$` to work

Remote access to `\\PC-NAME\C$` depends on a small set of Windows components:

1. The `LanmanServer` (`Server`) service must be available and running.
   If this service is stopped or disabled, Windows cannot host SMB shares and TCP 445 will not be available for `C$`.

2. Built-in administrative shares must not be explicitly disabled.
   Windows normally creates `C$` automatically. If `AutoShareWks` has been set to `0`, that is an explicit configuration decision and this solution reports it instead of overriding it.

3. Inbound TCP 445 must be allowed to the device.
   This solution creates a single dedicated inbound Windows Defender Firewall rule named `College IT - SMB Admin` that allows TCP 445. If you set `$ITManagementSubnet`, the rule is restricted to that subnet or address list. If you leave it blank, the rule uses `Any` for `RemoteAddress`.

Nothing else should be changed for the primary objective. In particular:

- LAPS does not need changing.
- Existing local administrator passwords do not need changing.
- SMBv1 must stay disabled.
- The broad `File and Printer Sharing` ruleset does not need to be enabled when only SMB administration is required.
- `LocalAccountTokenFilterPolicy` is not changed automatically.

## About UAC remote token filtering

This solution detects and reports `LocalAccountTokenFilterPolicy`, but does not set it.

That setting can matter when you authenticate over the network with a local administrator account that is not the built-in RID 500 `Administrator` account. In that case, the connection may authenticate successfully but still receive a filtered token and fail with `Access is denied` when opening `C$`.

Security implication: setting `LocalAccountTokenFilterPolicy=1` gives remote local administrator logons a full elevated token over the network. That increases lateral movement risk if a local admin credential is compromised. Because of that, the deployment script only reports this as a possible manual follow-up if testing shows it is required for your chosen LAPS-managed account.

## About PowerShell Remoting / WinRM

PowerShell Remoting is treated separately from SMB and is not configured by these scripts.

On a Microsoft Entra ID joined Windows 11 device, enabling WinRM securely usually requires additional decisions beyond simply starting the service, for example:

- whether HTTP on TCP 5985 is acceptable on the local network, or whether HTTPS on TCP 5986 is required
- how the remote client will authenticate the server
- whether existing firewall policy should allow WinRM inbound
- whether your support model can avoid risky fallbacks such as broad `TrustedHosts`, Basic authentication, or unencrypted transport

Because those are separate security and infrastructure decisions, the deployment script only reports the current WinRM state and does not change it.

## Files

- `scripts/Deploy-RemoteFileAccess.ps1`
- `scripts/Detect-RemoteFileAccess.ps1`
- `scripts/Remove-RemoteFileAccess.ps1`
- `scripts/Connect-RemoteFileAccessGui.ps1`

## Deployment through Intune

Recommended approach: use Intune Remediations so detection can confirm the required local state and remediation can apply only the minimum changes.

1. Optionally edit each script and set the value of `$ITManagementSubnet`.
2. If you set it, use a restricted value such as a single subnet, CIDR range, or explicit address list.
3. If you leave it blank, the firewall rule will allow TCP 445 from any remote address.
4. In Intune, create a Remediation package.
5. Upload `scripts/Detect-RemoteFileAccess.ps1` as the detection script.
6. Upload `scripts/Deploy-RemoteFileAccess.ps1` as the remediation script.
7. Run scripts in 64-bit PowerShell.
8. Run in system context.
9. Target a pilot device group first.

If you only want one-time deployment, you can also assign `scripts/Deploy-RemoteFileAccess.ps1` as a device PowerShell script in Intune. The rollback script is intended for separate targeted removal if you later want to remove only the configuration created by this solution.

## What the deployment script does

`Deploy-RemoteFileAccess.ps1`:

- requires administrator rights
- treats the management subnet as optional
- inspects `LanmanServer`, `C$`, TCP 445 readiness, network profile, firewall policy merge state, and `AutoShareWks`
- starts `LanmanServer` only if required
- changes `LanmanServer` startup type only if it was disabled and SMB hosting cannot work otherwise
- creates or updates only one firewall rule: `College IT - SMB Admin`
- logs all findings and changes to `C:\ProgramData\CollegeIT\RemoteFileAccess\Logs`
- stores rollback state in `C:\ProgramData\CollegeIT\RemoteFileAccess\State`
- reports manual intervention if an organisational setting such as `AutoShareWks=0` or firewall policy override prevents success

## Detection logic

`Detect-RemoteFileAccess.ps1` checks:

- `LanmanServer` exists and is running
- `C$` exists
- the `College IT - SMB Admin` firewall rule exists
- the firewall rule is enabled
- the firewall rule allows TCP 445 inbound
- the firewall rule `RemoteAddress` matches the expected configuration, whether restricted or `Any`
- SMBv1 is not enabled

Exit codes:

- `0`: compliant
- `1`: not compliant or blocked by policy / manual intervention required

## Rollback behaviour

`Remove-RemoteFileAccess.ps1` removes only the configuration this solution created.

It will:

- remove the `College IT - SMB Admin` firewall rule if it matches this solution
- restore the original `LanmanServer` startup type only if the deployment changed it
- stop `LanmanServer` only if the deployment started it and it was originally not running

It will not:

- remove `C$`
- change existing `File and Printer Sharing` rules
- modify LAPS
- modify local administrator accounts or passwords

## IT workstation testing

From an authorised IT workstation, test TCP 445 first:

```powershell
Test-NetConnection PC123 -Port 445
```

Then authenticate using the existing LAPS-managed local administrator account:

```powershell
net use \\PC123\C$ /user:PC123\<LAPS-ADMIN-ACCOUNT> *
```

Then browse:

```text
\\PC123\C$
```

Disconnect when finished:

```powershell
net use \\PC123\C$ /delete
```

If you need to clear conflicting SMB sessions first:

```powershell
net use \\PC123\* /delete
```

## IT workstation GUI

If you want a simple local tool on an authorised IT workstation, run `scripts/Connect-RemoteFileAccessGui.ps1` in a normal PowerShell session on the IT workstation.

The GUI:

- tests whether TCP 445 is reachable on the target device
- prompts for the existing LAPS-managed credential only when you connect
- opens `\\PC\C$` in Explorer after a successful connection
- disconnects the SMB session when finished
- can clear an existing `C$` session first if Windows is holding different cached credentials

This GUI does not deploy anything to the endpoint. It is only a client-side tool for authorised IT staff.

## Troubleshooting

### DNS or name resolution failure

```powershell
Resolve-DnsName PC123
ping PC123
```

If name resolution fails, try the device IP address to separate DNS issues from SMB issues.

### PC offline

```powershell
Test-Connection PC123 -Count 2
```

If the device does not respond and TCP 445 is unreachable, the workstation may be asleep, disconnected, or off-site.

### TCP 445 blocked

```powershell
Test-NetConnection PC123 -Port 445
```

If the TCP test fails, check whether:

- `LanmanServer` is running on the target
- the `College IT - SMB Admin` rule exists and matches the expected `RemoteAddress` scope
- an Intune or Defender Firewall policy is disabling local firewall rule merge or otherwise overriding the local rule

### Access denied

Common causes:

- wrong local username format
- wrong LAPS password
- remote UAC token filtering for a non-RID 500 local admin account
- `C$` not present because administrative shares were disabled by policy

### Incorrect LAPS credentials

Re-check the account name and current password in Windows LAPS, then reconnect:

```powershell
net use \\PC123\C$ /delete
net use \\PC123\C$ /user:PC123\<LAPS-ADMIN-ACCOUNT> *
```

### UAC remote token filtering

If authentication succeeds but opening `\\PC123\C$` still returns `Access is denied`, and the LAPS-managed account is a local admin account other than the built-in `Administrator`, test whether remote UAC token filtering is the cause before changing anything.

This solution reports the current `LocalAccountTokenFilterPolicy` value but does not modify it.

### `C$` unavailable

On the target workstation, verify:

```powershell
Get-SmbShare -Name C$
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name AutoShareWks
```

If `AutoShareWks` is `0`, the share has been intentionally disabled and the deployment script will report that instead of overriding it.

### Existing SMB sessions using different credentials

Windows will usually reuse an existing SMB session to the same device. Remove the session and reconnect with the LAPS-managed account:

```powershell
net use \\PC123\* /delete
```

### Intune firewall policy overriding local configuration

If detection shows the local firewall rule is present but TCP 445 is still blocked, review whether an Intune-delivered Defender Firewall policy has disabled local rule merge or otherwise imposed a conflicting inbound rule set. That must be corrected in policy; this script does not override it.