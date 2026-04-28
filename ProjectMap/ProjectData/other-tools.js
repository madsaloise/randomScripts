// Other Tools category projects
const otherToolsProjects = {
    "pwsh-profile": {
        title: "MCHs PowerShell Profile",
        name: "MCHs PowerShell Profile",
        category: "other tools",
        languages: ["PowerShell"],
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
    },
    "monthly-tasks": {
        title: "Monthly Tasks",
        name: "Monthly Tasks",
        category: "other tools",
        languages: ["PowerShell"],
        shortDescription: "Automated monthly QVD transfers, health checks, and notifications",
        overview: "Scheduled automation framework for monthly BI operations. Handles QVD file transfers, health checks, link validation, and email notifications. Modular PowerShell architecture with centralized task orchestration.",
        location: ["MonthlyTasks/"],
        dependencies: ["BI_QlikView", "BI_Warehouse"],
        integrations: ["pwsh-profile"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Scheduled Task permissions",
            "Access to QVD file shares",
            "SMTP server for email notifications or Send-OutlookMail function from pwsh-profile"
        ],
        contactSupport: [
            "Mads Chrøis",
            "See master.ps1 for task scheduling"
        ]
    }
};
