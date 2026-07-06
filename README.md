# Our Bucket List — private, Google sign-in, live sync

A shared bucket list for exactly two people. Sign in with Google; anyone else who finds the link sees a login wall and gets nothing — access is enforced by database rules on the server, not by the page.

**Stack:** GitHub Pages (hosting, free) + Supabase (Google login + database + live sync, free tier).

Everything is pre-built. Your part is the account-approval clicks below — about **15 minutes**, no terminal needed.

---

## Setup checklist

### 1 · Create the Supabase project (~2 min)
1. Go to [supabase.com](https://supabase.com) → sign in → **New project** (free plan).
2. Any name/region/password. Wait ~2 minutes while it provisions.
3. Note your **Project URL** — it looks like `https://abcdefgh.supabase.co`. The `abcdefgh` part is your **PROJECT-REF** (you'll paste it in step 3).

### 2 · Run the database setup (~1 min)
1. Open `setup.sql` from this repo, and edit the **two email lines** near the top to your two Google account emails.
2. In Supabase: **SQL Editor → New query** → paste the whole file → **Run**. You should see "Success".

That single script creates the data table, the two-email allowlist, the server-side security rules, and turns on live sync. Safe to re-run anytime (e.g. to change the emails).

### 3 · Create the Google sign-in client (~4 min)
1. Go to [console.cloud.google.com](https://console.cloud.google.com) → create a project (any name).
2. **APIs & Services → OAuth consent screen** (Google may call it *Google Auth Platform*):
   - User type: **External** → fill in app name + your email → Save.
   - **Audience → stay in "Testing"** and add **both** of your Google emails as *test users*. (Testing mode means only listed users can even attempt sign-in — a free extra lock. No verification/review needed since we only use basic profile scopes.)
3. **Clients → Create client** (or *Credentials → Create credentials → OAuth client ID*):
   - Application type: **Web application**.
   - **Authorized redirect URIs** — add exactly one:
     ```
     https://PROJECT-REF.supabase.co/auth/v1/callback
     ```
     (replace `PROJECT-REF` with yours from step 1)
4. Copy the **Client ID** and **Client secret**.

### 4 · Wire Google into Supabase (~1 min)
Supabase → **Authentication → Sign In / Providers → Google** → toggle **Enabled** → paste the Client ID and Client secret → **Save**.

### 5 · Put the site on GitHub (~3 min, no terminal)
1. [github.com/new](https://github.com/new) → name it e.g. `bucket-list` → **Public** → Create repository.
2. Click **"uploading an existing file"** → drag in all files from this folder (`index.html`, `config.js`, `setup.sql`, `README.md`, `.nojekyll`) → **Commit changes**.
3. Edit `config.js` right in the GitHub web UI (pencil icon): paste your **Project URL** and **anon public** key from Supabase → **Project Settings → API** → Commit.
   - The anon key is *designed* to be public — committing it to a public repo is fine. Security comes from the database rules, not from hiding this key.

### 6 · Turn on GitHub Pages (~1 min)
Repo → **Settings → Pages** → Source: **Deploy from a branch** → Branch: `main`, folder `/ (root)` → **Save**. After 1–2 minutes your site is live at:
```
https://YOUR-USERNAME.github.io/bucket-list/
```

### 7 · Tell Supabase your site's address (~1 min)
Supabase → **Authentication → URL Configuration**:
- **Site URL**: `https://YOUR-USERNAME.github.io/bucket-list/`
- **Redirect URLs**: add the same URL.

### 8 · Sign in 🎉
Open the site → **Continue with Google** → pick your account → your list appears. Have your partner do the same on their phone with their listed email. Each device stays signed in until you sign out from ⚙️ Settings.

---

## How access control actually works

- Google proves *who* someone is; Supabase issues them a session.
- The database has Row Level Security rules (from `setup.sql`) that check the signed-in email against the `allowed_users` table **on the server, for every read and write**.
- Anyone not on the list — even signed in with a real Google account, even holding the full link, even bypassing the page with dev tools — gets zero rows back. There is nothing to leak client-side.
- On iPhone, Google sign-in typically confirms via your Google passkey → you get the **Face ID prompt** without any extra setup.

## Everyday notes

- **Live sync:** when one of you adds or completes something, the other's open page updates within a couple of seconds.
- **Photos** are compressed and stored in the database — fine for the free tier at couple-scale.
- **Updating the app later:** upload a new `index.html` over the old one in the GitHub web UI; Pages redeploys automatically. Don't overwrite your edited `config.js`.
- **Add a third person someday:** add their email to the `insert` in `setup.sql` and re-run it in the SQL Editor. Also add them as a *test user* in the Google console (step 3).

## Troubleshooting

| Symptom | Fix |
|---|---|
| Google shows **redirect_uri_mismatch** | The redirect URI in step 3 must be *exactly* `https://PROJECT-REF.supabase.co/auth/v1/callback` — check the ref and no trailing slash. |
| Signed in but **"This account isn't on the list"** | The email in `allowed_users` must match your Google account email exactly (comparison is case-insensitive, but typos/aliases aren't). Re-run `setup.sql` with the exact address shown on the denied screen. |
| Google blocks sign-in with **"access denied / app not verified"** | Add that email as a *test user* in the OAuth consent screen (step 3.2). |
| Site shows the **"Almost there / config.js"** screen | `config.js` still has placeholder values, or you edited the wrong copy. Paste the Project URL + anon key and commit. |
| Login loops back to the sign-in screen | Step 7 missing: add your Pages URL to Supabase's Site URL + Redirect URLs. |
| Changes not appearing on the other phone instantly | Realtime can lag a few seconds; ⚙️ → Refresh list forces it. |
| Site was fine, now errors after ~a week unused | Supabase pauses idle free projects. Open your Supabase dashboard and click **Restore** — takes a minute. |
| You **rename the repo** | Your Pages URL changes → update step 7 with the new URL. |

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app (UI + logic). |
| `config.js` | The only file you edit — two Supabase values. |
| `setup.sql` | One-time database setup; edit the two emails. |
| `.nojekyll` | Tells GitHub Pages to serve files as-is. |
