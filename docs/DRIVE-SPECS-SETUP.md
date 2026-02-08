# Using Google Drive specs in Cursor

This project is set up so you can **write specs in Google Drive** and **use them in Cursor** via the Google Drive MCP.

## 1. One-time Google Drive MCP setup

The **gdrive** MCP is already in your global config (`~/.cursor/mcp.json`). You only need to authenticate once:

### A. Google Cloud

1. [Google Cloud Console](https://console.cloud.google.com/) → create/select a project.
2. **APIs & Services** → **Enable APIs** → enable **Google Drive API** (and **Google Docs API** if you use Docs).
3. **OAuth consent screen**: configure (e.g. Internal), add scope `https://www.googleapis.com/auth/drive.readonly` (or `drive` for read/write).
4. **Credentials** → **Create** → **OAuth client ID** → **Desktop app** → download JSON.
5. Save the JSON as `gcp-oauth.keys.json` in `~/.cursor/` (or the folder you’ll use for auth).

### B. Create credentials file used by the MCP

The auth command looks for the keys file in the package’s directory when run via `npx`, which causes “Cannot find module …/gcp-oauth.keys.json”. Use **environment variables** so it uses your file and saves credentials where the MCP expects them.

1. Put your Google OAuth JSON in `~/.cursor/` and name it **`gcp-oauth.keys.json`** (e.g. copy the file you downloaded from Google Cloud Console and rename it).

2. From a terminal (Node.js required), run:

```bash
export GDRIVE_OAUTH_PATH="/Users/maurizio.bellini/.cursor/gcp-oauth.keys.json"
export GDRIVE_CREDENTIALS_PATH="/Users/maurizio.bellini/.cursor/.gdrive-server-credentials.json"
npx -y @modelcontextprotocol/server-gdrive auth
```

A browser window will open to sign in with Google. After you complete the flow, credentials are written to `~/.cursor/.gdrive-server-credentials.json`. Your `mcp.json` already points to that path.

3. Restart Cursor so the gdrive MCP loads.

**If you still see “Cannot find module …/gcp-oauth.keys.json”:** the package may ignore env vars for the `auth` subcommand. Use the **clone method** instead:

```bash
git clone https://github.com/modelcontextprotocol/servers.git /tmp/mcp-servers
cd /tmp/mcp-servers/src/gdrive
cp /Users/maurizio.bellini/.cursor/gcp-oauth.keys.json .
npm install && npm run build
node ./dist auth
cp .gdrive-server-credentials.json /Users/maurizio.bellini/.cursor/
```

Then restart Cursor.

---

## 2. How to use specs from Drive in Cursor

- **In chat:** Ask in natural language, e.g.  
  *“Use the spec from Google Drive for the onboarding flow”* or *“What does the API spec in Drive say about auth?”*  
  The agent will use the gdrive MCP to search and read the right doc.

- **Naming/organization:** Use clear names or a folder for this project (e.g. “habit-tracker specs”, “Habit Tracker – API spec”). That makes it easier to search and say “the spec in folder X”.

- **Cursor rule:** The project has a rule that tells the agent to pull requirements and specs from Google Drive when relevant, so you don’t have to repeat “check Drive” every time.

---

## 3. Suggested Drive layout

- One **folder** for this project (e.g. “Habit Tracker”).
- **Docs** per feature or area: e.g. “Onboarding spec”, “API spec”, “Data model”.
- Optionally a **“Master spec”** or “Product requirements” doc that links to or summarizes the others.

Once the MCP is authenticated and Cursor restarted, you can write and edit these specs in Drive and reference them in Cursor as above.
