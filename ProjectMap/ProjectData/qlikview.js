// QlikView category projects
const qlikviewProjects = {
    "BI_QlikView": {
        title: "QlikView Engine",
        name: "QlikView Engine",
        category: "QlikView",
        categoryColor: "#00BCD4",
        breadcrumb: "QlikView / Engine",
        shortDescription: "QlikView client libraries and automation",
        overview: "PowerShell class-based client library for QlikView automation. Provides programmatic access to QlikView Desktop for opening, reloading, and saving QVW files. Used across multiple automation projects.",
        location: ["pwshProfile/QlikClasses/"],
        dependencies: ["dwh-core"],
        integrations: ["qv-automation", "monthly-tasks", "sql-qv-converter", "pwsh-profile"],
        requirements: [
            "QlikView Desktop installed",
            "PowerShell 5.1 or higher",
            "QlikViewClient.ps1 class loaded"
        ],
        contactSupport: [
            "QlikView development team",
            "See QlikViewClient.ps1 for usage examples"
        ]
    }
};
