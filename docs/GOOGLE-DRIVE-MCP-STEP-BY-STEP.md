# Google Drive MCP – Full procedure (step by step)

This guide takes you from zero to using specs stored in Google Drive inside Cursor.

---

## Part 1: Google Cloud setup

### Step 1 – Open Google Cloud Console

1. Go to **https://console.cloud.google.com/**
2. Sign in with the Google account that has (or will have) your spec documents in Drive.

### Step 2 – Create or select a project

1. In the top bar, click the **project** dropdown.
2. Click **New Project**, give it a name (e.g. “Cursor MCP”), click **Create**.
3. Or select an existing project.

### Step 3 – Enable Google Drive API

1. In the left menu: **APIs & Services** → **Enabled APIs and services**.
2. Click **+ Enable APIs and Services**.
3. Search for **Google Drive API**, open it, click **Enable**.
4. (Optional) Search for **Google Docs API** and enable it if you use Google Docs for specs.

### Step 4 – Configure the OAuth consent screen

1. **APIs & Services** → **OAuth consent screen**.
2. Choose **Internal** (only your Google Workspace) or **External** (any Google account), then **Create**.
3. Fill **App name** (e.g. “Cursor Drive MCP”) and **User support email**. Save.
4. Click **Add or remove scopes**.
5. Add: `https://www.googleapis.com/auth/drive.readonly` (read-only) or `https://www.googleapis.com/auth/drive` (read/write). Save.

### Step 5 – Create OAuth client credentials

1. **APIs & Services** → **Credentials**.
2. **+ Create credentials** → **OAuth client ID**.
3. Application type: **Desktop app**.
4. Name it (e.g. “Cursor MCP”) and click **Create**.
5. In the dialog, click **Download JSON**. Save the file somewhere you can find it (e.g. Downloads).

### Step 6 – Put the keys file where Cursor will use it

1. Rename the downloaded file to exactly: **`gcp-oauth.keys.json`**.
2. Move it to your Cursor config folder:
   - **Mac/Linux:** `~/.cursor/`  
     Full path example: `/Users/maurizio.bellini/.cursor/gcp-oauth.keys.json`
   - **Windows:** `%USERPROFILE%\.cursor\gcp-oauth.keys.json`
3. Confirm the file exists at that path (e.g. in Finder or with `ls ~/.cursor/gcp-oauth.keys.json` in Terminal).

---

## Part 2: MCP config in Cursor

### Step 7 – Check the gdrive entry in MCP config

1. Open your **global** MCP config:
   - **Mac/Linux:** `~/.cursor/mcp.json`
   - **Windows:** `%USERPROFILE%\.cursor\mcp.json`
2. You should see a `gdrive` server with something like:

```json
"gdrive": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-gdrive"],
  "env": {
    "GDRIVE_CREDENTIALS_PATH": "/Users/maurizio.bellini/.cursor/.gdrive-server-credentials.json",
    "GDRIVE_OAUTH_PATH": "/Users/maurizio.bellini/.cursor/gcp-oauth.keys.json"
  }
}
```

3. **Paths:** Replace the paths with your real paths if different:
   - `GDRIVE_CREDENTIALS_PATH` → where the **auth** command will write the token file (Step 9).
   - `GDRIVE_OAUTH_PATH` → where you put **gcp-oauth.keys.json** in Step 6.
4. Save the file.

---

## Part 3: One-time authentication

### Step 8 – Open a terminal

Use Terminal (Mac/Linux) or PowerShell/Command Prompt (Windows). Node.js must be installed (`node --version` should work).

### Step 9 – Run the auth command with the correct paths

**Mac/Linux** (replace the path with your home directory if different):

```bash
export GDRIVE_OAUTH_PATH="/Users/maurizio.bellini/.cursor/gcp-oauth.keys.json"
export GDRIVE_CREDENTIALS_PATH="//Users/maurizio.bellini/.cursor/.gdrive-server-credentials.json"
npx -y @modelcontextprotocol/server-gdrive auth
```

**Windows (PowerShell):**

```powershell
$env:GDRIVE_OAUTH_PATH = "$env:USERPROFILE\.cursor\gcp-oauth.keys.json"
$env:GDRIVE_CREDENTIALS_PATH = "$env:USERPROFILE\.cursor\.gdrive-server-credentials.json"
npx -y @modelcontextprotocol/server-gdrive auth
```

**Important:** The file `.gdrive-server-credentials.json` does **not** exist yet. It is **created** when you finish the auth flow in Step 10. So “I don’t have that file” at this point is normal.

**If nothing happens or you don’t get to authorization:** the `npx` auth command often fails to find the keys file. Use the **clone method** below instead of the `npx` command above. It runs auth from a folder that contains your keys file, so the browser/URL step works.

**Clone method (use this if Step 9 doesn’t open a browser or show a URL):**

```bash
# 1. Clone the MCP servers repo
git clone https://github.com/modelcontextprotocol/servers.git /tmp/mcp-servers
cd /tmp/mcp-servers/src/gdrive

# 2. Copy your keys file into this folder (so the auth script can find it)
cp /Users/maurizio.bellini/.cursor/gcp-oauth.keys.json .

# 3. Install and build
npm install && npm run build

# 4. Run auth (this should print a URL and/or open the browser)
node ./dist auth

# 5. After you complete sign-in in the browser, copy the created credentials to Cursor’s folder
cp .gdrive-server-credentials.json /Users/maurizio.bellini/.cursor/
```

Then do Step 11 (check the file exists) and Step 12 (restart Cursor).

### Step 10 – Complete the browser sign-in

1. A browser window should open asking you to sign in to Google (or the auth command prints a URL — open it in your browser).
2. Choose the account that has (or will have) your Drive specs.
3. If you see “Google hasn’t verified this app”, choose **Advanced** → **Go to … (unsafe)** (it’s your own app).
4. Allow access to Drive (read-only or read/write, depending on the scope you set).
5. When the page says you’re done, you can close the tab.

### Step 11 – Confirm the credentials file was created

Check that the file from `GDRIVE_CREDENTIALS_PATH` exists:

- **Mac/Linux:** `ls -la ~/.cursor/.gdrive-server-credentials.json`
- **Windows:** `dir %USERPROFILE%\.cursor\.gdrive-server-credentials.json`

If it’s there, auth worked.

**If you get “Cannot find module …/gcp-oauth.keys.json”:** the auth tool may be ignoring the env vars. Use the **clone method**:

```bash
git clone https://github.com/modelcontextprotocol/servers.git /tmp/mcp-servers
cd /tmp/mcp-servers/src/gdrive
cp /Users/maurizio.bellini/.cursor/gcp-oauth.keys.json .
npm install && npm run build
node ./dist auth
cp .gdrive-server-credentials.json /Users/maurizio.bellini/.cursor/
```

Then go back to Step 11 (check that the file exists).

### Step 12 – Restart Cursor

Quit Cursor completely and open it again so it loads the gdrive MCP and the new credentials.

---

## Part 4: Using specs from Drive in Cursor

### Step 13 – Organize specs in Google Drive (recommended)

1. In Google Drive, create a folder for this project (e.g. **Habit Tracker**).
2. Put your spec documents in that folder (Google Docs, Sheets, or other types).
3. Use clear names (e.g. “API spec”, “Onboarding spec”, “Data model”).

### Step 14 – Use the gdrive MCP in Cursor

1. Open your project in Cursor (e.g. habit-tracker).
2. In **Chat / Composer**, ask in natural language, for example:
   - *“Use the spec from Google Drive for the onboarding flow.”*
   - *“What does the API spec in Drive say about authentication?”*
   - *“Search my Drive for the habit-tracker spec and implement according to it.”*
3. The agent will use the Google Drive MCP to search and read the right file and follow the spec.

### Step 15 – Rely on the project rule (optional)

This project has a Cursor rule (`.cursor/rules/drive-specs.mdc`) that tells the agent to look at Google Drive for specs when relevant. You don’t have to say “check Drive” every time; the agent will use Drive when it’s appropriate.

---

## Quick checklist

- [ ] Google Cloud project created
- [ ] Google Drive API (and optionally Docs API) enabled
- [ ] OAuth consent screen configured with Drive scope
- [ ] Desktop OAuth client created and JSON downloaded
- [ ] JSON renamed to `gcp-oauth.keys.json` and placed in `~/.cursor/`
- [ ] `~/.cursor/mcp.json` has the gdrive server with `GDRIVE_CREDENTIALS_PATH` and `GDRIVE_OAUTH_PATH`
- [ ] Auth command run with those env vars set; browser sign-in completed
- [ ] `~/.cursor/.gdrive-server-credentials.json` exists
- [ ] Cursor restarted
- [ ] Specs in Drive; tested by asking the agent to use them in chat

---

## Troubleshooting

| Problem | What to try |
|--------|--------------|
| “Cannot find module …/gcp-oauth.keys.json” | Use the clone method in Step 11 and run `node ./dist auth` from the cloned repo. |
| gdrive MCP not in the list | Restart Cursor; check `mcp.json` syntax (valid JSON, paths correct). |
| “Credentials not found” or similar | Ensure `GDRIVE_CREDENTIALS_PATH` in `mcp.json` points to the file created in Step 11. |
| Agent doesn’t use Drive | Ask explicitly: “Search Google Drive for …” or “Use the spec from Drive for …”. |

That’s the full procedure from Google Cloud to using Drive specs in Cursor.
