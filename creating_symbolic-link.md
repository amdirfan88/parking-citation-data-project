# Connecting Local Files to Power BI Using OneDrive

## Step 1 — Create a OneDrive Sync Folder

1. Install and sign in to OneDrive.
2. Inside the OneDrive directory, create a folder:

```text
parking-citation-analytics
```

Example path:

```bash
~/OneDrive/parking-citation-analytics
```

---

# Step 2 — Connect the Local Project to OneDrive Using a Symbolic Link

Go to the folder inside the local project where you want Power BI export files to appear.

Example:

```bash
cd ~/projects/my-project/data
```

Create the symbolic link:

```bash
ln -s ~/OneDrive/parking-citation-analytics data_exports
```

If the OneDrive path contains spaces:

```bash
ln -s ~/OneDrive\ -\ OrganizationName/parking-citation-analytics data_exports
```

Verify the link:

```bash
ls -l
```

You should see:

```text
data_exports -> /Users/username/OneDrive/parking-citation-analytics
```

Test the connection:

```bash
touch data_exports/test.txt
ls data_exports
```

If `test.txt` appears both locally and in OneDrive cloud storage, the sync is working.

Remove the test file:

```bash
rm data_exports/test.txt
```

Export CSV Files into the Shared Folder. OneDrive automatically syncs the files to the cloud.

---

# Step 3 — Connect Power BI to the OneDrive File

1. Open Power BI Web.
2. Open the workspace, and open the desired folder where you want to save in.
3. Click:

```text
New Item → Semantic Model → CSV
```

4. Click Browse OneDrive and select the CSV file. Or, you copy and paste your one drive cloud link.
5. Authenticate if prompted.
6. Click **Next** to load the preview.
7. In the next step Power Query will appear, perform transformations if needed.
8. Select:
   - **Create a Report**
   - or **Create a Semantic Model Only**

   In this step, you may be asked again to select the directory where you want to save.

---

# Final Workflow

```text
Local Project
      ↓
CSV Export
      ↓
Symbolic Link
      ↓
OneDrive Sync
      ↓
Power BI Semantic Model
      ↓
Dashboard
```