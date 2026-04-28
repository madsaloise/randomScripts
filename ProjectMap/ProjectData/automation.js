// Automation category projects
const automationProjects = {
    "monthly-tasks": {
        title: "Monthly Tasks",
        name: "Monthly Tasks",
        category: "automation",
        categoryColor: "#FF9800",
        languages: ["PowerShell"],
        shortDescription: "Automated monthly QVD transfers, health checks, and notifications",
        overview: "Scheduled automation framework for monthly BI operations. Handles QVD file transfers, health checks, link validation, and email notifications. Modular PowerShell architecture with centralized task orchestration.",
        location: ["MonthlyTasks/"],
        dependencies: ["BI_QlikView", "dwh-core"],
        integrations: ["pwsh-profile"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Scheduled Task permissions",
            "Access to QVD file shares",
            "SMTP server for email notifications or Send-OutlookMail function from pwsh-profile"
        ],
        contactSupport: [
            "BI Operations team",
            "See master.ps1 for task scheduling"
        ]
    }
};
