using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Azure.Core;
using Azure.Identity;

namespace NewMicrosoft365Group;

public partial class MainWindow : System.Windows.Window
{
    private const string MailDomain = "ccmschools.onmicrosoft.com";
    private const string PriorityDomain = "hopecc.sa.edu.au";
    private readonly GraphClient graph = new();
    private readonly List<UserChoice> owners = [];
    private readonly List<UserChoice> members = [];
    private bool connected;
    private bool changingName;
    private bool changingAlias;

    public MainWindow()
    {
        InitializeComponent();
        GroupName.TextChanged += (_, _) => { EnsureHccName(); SetAlias(); };
        EmailAddress.TextChanged += (_, _) => { if (!changingAlias) EmailAddress.Tag = true; };
        AddHopeCcAlias.Checked += (_, _) => HopeCcAlias.IsEnabled = true;
        AddHopeCcAlias.Unchecked += (_, _) => HopeCcAlias.IsEnabled = false;
        OwnerSearchButton.Click += async (_, _) => await SearchAsync(OwnerSearch.Text, OwnerResults);
        MemberSearchButton.Click += async (_, _) => await SearchAsync(MemberSearch.Text, MemberResults);
        OwnerResults.MouseDoubleClick += (_, _) => AddSelection(OwnerResults, SelectedOwners, owners);
        MemberResults.MouseDoubleClick += (_, _) => AddSelection(MemberResults, SelectedMembers, members);
        ConnectButton.Click += async (_, _) => await ConnectAsync();
        CreateButton.Click += async (_, _) => await CreateAsync();
        Loaded += async (_, _) => await ConnectAsync();
    }

    private void EnsureHccName()
    {
        if (changingName || string.IsNullOrWhiteSpace(GroupName.Text) || GroupName.Text.StartsWith("HCC ", StringComparison.OrdinalIgnoreCase)) return;
        changingName = true; GroupName.Text = "HCC " + GroupName.Text.Trim(); GroupName.CaretIndex = GroupName.Text.Length; changingName = false;
    }

    private void SetAlias()
    {
        var name = System.Text.RegularExpressions.Regex.Replace(GroupName.Text, "^hcc[\\s._-]*", "", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        var alias = "hcc." + new string(name.ToLowerInvariant().Where(c => char.IsAsciiLetterOrDigit(c) || c is '.' or '_' or '-').ToArray());
        if (alias.Length > 64) alias = alias[..64].TrimEnd('.', '_', '-');
        if (EmailAddress.Tag is null) { changingAlias = true; EmailAddress.Text = alias + "@" + MailDomain; changingAlias = false; }
    }

    private async Task ConnectAsync()
    {
        try { var account = await graph.ConnectAsync(); connected = true; SignedInText.Text = "Connected: " + account; ConnectButton.IsEnabled = false; CreateButton.IsEnabled = true; SetStatus("Connected to Microsoft Graph.", false); }
        catch (Exception ex) { SetStatus("Connection failed: " + ex.Message); }
    }

    private async Task SearchAsync(string query, System.Windows.Controls.ListBox target)
    {
        if (!connected) { SetStatus("Connect to Microsoft Graph before searching for users."); return; }
        if (string.IsNullOrWhiteSpace(query)) { SetStatus("Enter a name or email address to search."); return; }
        try { var results = await graph.SearchUsersAsync(query.Trim()); target.Items.Clear(); foreach (var user in results) target.Items.Add(user); SetStatus($"{results.Count} user(s) found.", false); }
        catch (Exception ex) { SetStatus("User search failed: " + ex.Message); }
    }

    private static void AddSelection(System.Windows.Controls.ListBox source, System.Windows.Controls.ListBox target, List<UserChoice> collection)
    {
        if (source.SelectedItem is not UserChoice user || collection.Any(x => x.Id == user.Id)) return;
        collection.Add(user); target.Items.Add(user);
    }

    private async Task CreateAsync()
    {
        var name = GroupName.Text.Trim(); var email = EmailAddress.Text.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(name)) { SetStatus("Group name is required."); return; }
        if (!System.Text.RegularExpressions.Regex.IsMatch(email, $"^hcc\\.[a-z0-9][a-z0-9._-]{{0,59}}@{MailDomain.Replace(".", "\\.")}$")) { SetStatus("Enter an email address in the format hcc.groupname@" + MailDomain + "."); return; }
        if (owners.Count == 0) { SetStatus("Select at least one owner."); return; }
        var hopeAlias = HopeCcAlias.Text.Trim().ToLowerInvariant();
        if (AddHopeCcAlias.IsChecked == true && !System.Text.RegularExpressions.Regex.IsMatch(hopeAlias, @"^[^\s@]+@[^\s@]+\.[^\s@]+$")) { SetStatus("Enter a valid HopeCC email address."); return; }
        var summary = $"Name: {name}\nEmail address: {email}\nPrivacy: {((System.Windows.Controls.ComboBoxItem)Privacy.SelectedItem).Content}\nOwners: {owners.Count} | Members: {members.Count}";
        if (System.Windows.MessageBox.Show(summary + "\n\nCreate this Microsoft 365 Group?", "Confirm group creation", System.Windows.MessageBoxButton.YesNo, System.Windows.MessageBoxImage.Question) != System.Windows.MessageBoxResult.Yes) return;
        CreateButton.IsEnabled = false; ProgressPanel.Visibility = System.Windows.Visibility.Visible; ProgressTitle.Text = "Creating group..."; ProgressText.Text = "Creating group..."; SetStatus("");
        try
        {
            var group = await graph.CreateGroupAsync(name, Description.Text.Trim(), email[..email.IndexOf('@')], ((System.Windows.Controls.ComboBoxItem)Privacy.SelectedItem).Content.ToString()!, owners, members, AutoSubscribe.IsChecked == true, ExternalSenders.IsChecked == true);
            ProgressText.Text += "\nOK Group created\nOK Owners added\nOK Members added\nOK Email settings configured";
            if (AddHopeCcAlias.IsChecked == true) { await ExchangeAliasAsync(email, hopeAlias); ProgressText.Text += "\nOK HopeCC alias added"; }
            ProgressTitle.Text = "Group created successfully"; ProgressTitle.Foreground = System.Windows.Media.Brushes.DarkGreen; ProgressText.Text += $"\n\n{name}\n{group["mail"]?.GetValue<string>() ?? email}";
        }
        catch (Exception ex) { ProgressTitle.Text = "Creation could not be completed"; SetStatus("Graph request failed: " + ex.Message); CreateButton.IsEnabled = true; }
    }

    private static async Task ExchangeAliasAsync(string identity, string alias)
    {
        var command = $"Import-Module ExchangeOnlineManagement -ErrorAction Stop; Connect-ExchangeOnline -ShowBanner:$false; Set-UnifiedGroup -Identity '{identity}' -EmailAddresses @{{ Add = '{alias}' }}";
        var start = new ProcessStartInfo("pwsh.exe") { UseShellExecute = false, CreateNoWindow = false };
        start.ArgumentList.Add("-NoProfile"); start.ArgumentList.Add("-Command"); start.ArgumentList.Add(command);
        using var process = Process.Start(start) ?? throw new InvalidOperationException("PowerShell is not installed."); await process.WaitForExitAsync();
        if (process.ExitCode != 0) throw new InvalidOperationException("Exchange Online alias command failed.");
    }

    private void SetStatus(string message, bool error = true) { StatusText.Text = message; StatusText.Foreground = error ? System.Windows.Media.Brushes.Firebrick : System.Windows.Media.Brushes.DarkGreen; }

    private sealed class GraphClient
    {
        private static readonly string[] Scopes = ["DeviceManagementManagedDevices.Read.All", "User.Read.All", "Group.ReadWrite.All"];
        private readonly InteractiveBrowserCredential credential = new(new InteractiveBrowserCredentialOptions { ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e", TenantId = "common" });
        private readonly HttpClient http = new();
        private async Task<HttpRequestMessage> RequestAsync(HttpMethod method, string path, object? body = null)
        {
            var token = await credential.GetTokenAsync(new TokenRequestContext(Scopes)); var request = new HttpRequestMessage(method, "https://graph.microsoft.com/v1.0" + path); request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token); request.Headers.Add("ConsistencyLevel", "eventual");
            if (body is not null) request.Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json"); return request;
        }
        private async Task<JsonObject> SendAsync(HttpMethod method, string path, object? body = null)
        { using var request = await RequestAsync(method, path, body); using var response = await http.SendAsync(request); var text = await response.Content.ReadAsStringAsync(); if (!response.IsSuccessStatusCode) throw new InvalidOperationException($"{(int)response.StatusCode}: {text}"); return string.IsNullOrWhiteSpace(text) ? new JsonObject() : JsonNode.Parse(text)!.AsObject(); }
        public async Task<string> ConnectAsync() { var result = await SendAsync(HttpMethod.Get, "/me?$select=userPrincipalName"); return result["userPrincipalName"]?.GetValue<string>() ?? "signed-in user"; }
        public async Task<List<UserChoice>> SearchUsersAsync(string query)
        { var safe = query.Replace("'", "''"); var path = "/users?$filter=" + Uri.EscapeDataString($"startsWith(displayName,'{safe}') or startsWith(userPrincipalName,'{safe}')") + "&$top=25&$select=id,displayName,userPrincipalName"; var json = await SendAsync(HttpMethod.Get, path); return json["value"]!.AsArray().Select(x => new UserChoice(x!["id"]!.GetValue<string>(), $"{x["displayName"]?.GetValue<string>()} <{x["userPrincipalName"]?.GetValue<string>()}>", x["userPrincipalName"]?.GetValue<string>() ?? "")).OrderBy(x => x.Upn.EndsWith("@" + PriorityDomain, StringComparison.OrdinalIgnoreCase) ? 0 : 1).ThenBy(x => x.Display).ToList(); }
        public async Task<JsonObject> CreateGroupAsync(string name, string description, string alias, string privacy, List<UserChoice> owners, List<UserChoice> members, bool autoSubscribe, bool externalSenders)
        { var body = new Dictionary<string, object?> { ["displayName"] = name, ["description"] = description, ["groupTypes"] = new[] { "Unified" }, ["mailEnabled"] = true, ["mailNickname"] = alias, ["securityEnabled"] = false, ["visibility"] = privacy, ["owners@odata.bind"] = owners.Select(x => "https://graph.microsoft.com/v1.0/users/" + x.Id).ToArray() }; if (members.Count > 0) body["members@odata.bind"] = members.Select(x => "https://graph.microsoft.com/v1.0/users/" + x.Id).ToArray(); var group = await SendAsync(HttpMethod.Post, "/groups", body); var patch = new Dictionary<string, bool>(); if (autoSubscribe) patch["autoSubscribeNewMembers"] = true; if (externalSenders) patch["allowExternalSenders"] = true; if (patch.Count > 0) await SendAsync(HttpMethod.Patch, "/groups/" + group["id"]!.GetValue<string>(), patch); return group; }
    }

    private sealed record UserChoice(string Id, string Display, string Upn);
}
