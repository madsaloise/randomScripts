# ProjectMap Documentation

Interactive technical documentation and project portfolio for the MchWork-1 workspace.

## 🚀 Getting Started

**Open `index.html` in your browser** to access the documentation hub.

Or jump directly to:
- **[Interactive Portfolio Map](portfolio.html)** - Visual project dependency graph
- **[Project Details](project-detail.html)** - Dynamic project detail pages (navigated via portfolio map)

## 📁 Structure

```
ProjectMap/
├── index.html              # Documentation hub (START HERE)
├── portfolio.html          # Interactive SVG project map
├── project-detail.html     # ✨ NEW: Dynamic project detail page
├── styles.css              # Shared stylesheet
├── data.js                 # Single source of truth for all project metadata
└── ProjectData/            # Legacy static HTML files (deprecated)
```

## 🗂️ Data Architecture

**Centralized Metadata:** All project information is stored in `data.js`:
- Project titles, categories, colors
- Dependencies and integrations
- Locations and descriptions
- Breadcrumb navigation paths
- **✨ NEW:** Example code snippets

**Dynamic Loading:** The new `project-detail.html` page:
1. Reads project ID from URL (`?project=dwh-core`)
2. Loads all data dynamically from `data.js`
3. Renders lineage visualization
4. Creates clickable navigation between projects
5. **No static HTML files needed!**

## 🎨 Categories

Documentation is organized into color-coded categories:

| Category | Color | Projects |
|----------|-------|----------|
| 🏛️ **Data Warehouse** | Purple | DWH Core, DWH Admin, SQL→QV Converter |
| 🔵 **QlikSense** | Blue | QlikSense Platform |
| 🔷 **QlikView** | Cyan | QlikView Engine, QV Automation |
| ⚙️ **Automation** | Orange | Monthly Tasks, SAP Time Tracking |
| 🛠️ **Tools** | Green | PowerShell Profile, SIT Cloud Tests |
| 🔧 **Azure DevOps** | Gray | DevOps Integration |

## 💡 Features

- **Dual View Modes** - Toggle between interactive Map View and organized List View
- **No Web Server Required** - Works on file shares with `file://` URLs
- **Dynamic Detail Pages** - Single `project-detail.html` loads all content from data.js
- **Clickable Navigation** - Click dependencies/dependants to navigate between projects
- **Lineage Visualization** - Visual dependency graph for each project
- **Modular CSS** - Single `styles.css` for all pages
- **Navigation** - Breadcrumbs and "Back to Map" links on every page
- **Cross-Linked** - Related projects are linked together
- **Responsive** - Works on desktop, tablet, and mobile

## 🌐 Hosting Options

### File Share (Current)
1. Copy the entire `ProjectMap/` folder to a network share
2. Users open `index.html` directly from the share
3. No configuration needed!

### Internal Web Server
1. Copy to web server document root
2. Access via `http://intranet/ProjectMap/`
3. Benefits: Better performance, easier to bookmark

### GitHub Pages / Static Host
1. Push to GitHub repository
2. Enable GitHub Pages
3. Access globally via HTTPS

## 📝 Updating Documentation

### Modular Architecture Benefits
All project metadata is centralized in `data.js` - update once, reflect everywhere!

### To Update Project Metadata
Edit `data.js` and change any property:
```javascript
"dwh-core": {
    title: "Data Warehouse (DWH Core)",  // Page title
    category: "Warehouse",                // Category
    breadcrumb: "Warehouse / DWH Core",   // Navigation breadcrumb
    shortDescription: "...",              // Portfolio map description
    location: ["DWH/"],                   // File locations
    dependencies: [],                     // What this depends on
    integrations: ["dwh-admin"]           // What integrates with this
}
```

Changes automatically propagate to:
- Portfolio map
- Breadcrumb navigation
- Page titles
- Category colors

### To Update Page Content
Simply edit the HTML file in `ProjectData/` - the content section is independent of metadata.

### Adding a New Project
1. **Add to appropriate category file** (e.g., `ProjectData/warehouse.js`, `ProjectData/qlikview.js`, etc.):
   ```javascript
   "new-project": {
       title: "New Project",
       name: "New Project",
       category: "Warehouse",
       languages: ["SQL", "PowerShell"],
       shortDescription: "Brief description for list view",
       overview: "Detailed overview of the project",
       location: ["NewProject/"],
       dependencies: ["other-project-key"],
       integrations: ["integrated-project-key"],
       requirements: [
           "Requirement 1",
           "Requirement 2"
       ],
       contactSupport: [
           "Contact Person",
           "Documentation link"
       ]
   }
   ```

2. **No HTML file needed** - All projects use the dynamic `project-detail.html` page with URL parameters (e.g., `project-detail.html?project=new-project`)

3. **Color is inherited** from the category definition in `data.js` - no need to specify per-project

3. **Update `index.html`** to add link in appropriate category

### Changing Global Styles
Edit `styles.css` - changes apply to all pages immediately.

## 🔗 Quick Links

- [index.html](index.html) - Documentation hub
- [portfolio.html](portfolio.html) - Interactive project map
- [styles.css](styles.css) - Shared stylesheet

---

**Last Updated:** April 2026
