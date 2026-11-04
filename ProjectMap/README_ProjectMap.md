# ProjectMap Documentation

Interactive technical documentation and project portfolio for the MchWork-1 workspace.

## 🚀 Getting Started

**Open [portfolio.html](portfolio.html) in your browser** to access the interactive project portfolio.

- Browse all projects with category and language filtering
- Search projects by name or description
- Click any project to view detailed documentation

## 📁 Structure

```
ProjectMap/
├── portfolio.html          # Interactive project portfolio (START HERE)
├── project-detail.html     # Dynamic project detail page
├── styles.css              # Shared stylesheet
├── data.js                 # Single source of truth for all project metadata
└── ProjectData/            # Category-specific project data files
    ├── warehouse.js
    ├── qliksense.js
    ├── qlikview.js
    ├── automation.js
    ├── other-tools.js
    └── azure-devops.js
```

## 🗂️ Data Architecture

**Modular Data Structure:** Project data is organized into category files under `ProjectData/`:
- Each category has its own `.js` file (e.g., `warehouse.js`, `qlikview.js`)
- `data.js` merges all category files into a single source of truth
- Categories define colors and display names centrally

**Dynamic Rendering:** The `project-detail.html` page:
1. Reads project ID from URL (`?project=BI_Warehouse`)
2. Loads all data dynamically from `data.js`
3. Renders lineage visualization showing dependencies and dependants
4. Creates clickable navigation between projects
5. Automatically calculates project relationships

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

- **Sidebar Filtering** - Filter by category, programming language, or search text
- **No Web Server Required** - Works on file shares with `file://` URLs
- **Dynamic Detail Pages** - Single `project-detail.html` loads all content from data.js
- **Clickable Navigation** - Click dependencies/dependants to navigate between projects
- **Lineage Visualization** - Visual dependency graph for each project
- **Modular Data** - Projects organized by category in separate files
- **Language Grouping** - Special grouping for multi-language projects
- **Automatic Relationships** - Dependants calculated automatically from dependencies
- **Responsive** - Works on desktop, tablet, and mobile

## 🌐 Hosting Options

### File Share (Current)
1. Copy the entire `ProjectMap/` folder to a network share
2. Users open `portfolio.html` directly from the share
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
Edit the appropriate category file in `ProjectData/` (e.g., `warehouse.js`):
```javascript
"BI_Warehouse": {
    title: "Data Warehouse (DWH Core)",   // Page title
    name: "Data Warehouse",               // Display name
    category: "Warehouse",                // Category (defines color)
    languages: ["SQL", "PowerShell"],     // Programming languages
    shortDescription: "...",              // Portfolio list description
    overview: "...",                      // Detailed description
    location: ["DWH/"],                   // File locations
    dependencies: [],                     // What this depends on
    integrations: ["BI_QlikView"],        // What integrates with this
    requirements: [],                     // Prerequisites
    contactSupport: []                    // Support contacts
}
```

Changes automatically propagate to:
- Portfolio list view
- Detail pages
- Lineage visualization
- Category colors (from `categories` object in `data.js`)

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

### Changing Global Styles
Edit `styles.css` - changes apply to all pages immediately.

## 🔗 Quick Links

- [portfolio.html](portfolio.html) - Interactive project portfolio (START HERE)
- [project-detail.html](project-detail.html) - Dynamic project detail pages
- [data.js](data.js) - Central data aggregation
- [styles.css](styles.css) - Shared stylesheet

---

**Last Updated:** April 2026
