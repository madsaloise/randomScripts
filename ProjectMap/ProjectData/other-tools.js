// Other Tools category projects
const otherToolsProjects = {
    "pwsh-profile": {
        title: "MCHs PowerShell Profile",
        name: "MCHs PowerShell Profile",
        category: "other tools",
        categoryColor: "#4CAF50",
        breadcrumb: "Tools / MCHs PowerShell Profile",
        shortDescription: "Custom PowerShell profile with Qlik clients and utilities",
        overview: "Custom PowerShell profile with enhanced logging, Qlik client classes, Outlook integration, and utility modules. Provides reusable components for BI automation and system administration tasks.",
        location: ["pwshProfile/"],
        dependencies: ["qlik-sense", "qlikview-engine"],
        integrations: ["monthly-tasks", "qv-automation", "devops-integration"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Profile installed in $PROFILE directory",
            "Qlik client modules available"
        ],
        contactSupport: [
            "See profile.ps1 for customization",
            "PowerShell documentation"
        ]
    }
};
