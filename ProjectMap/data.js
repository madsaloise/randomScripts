const projectData = {
    "dwh-core": {
        id: "BIWarehouse",
        title: "BI Warehouse",
        name: "BI Warehouse",
        category: "Warehouse",
        breadcrumb: "Warehouse / BI Warehouse",
        shortDescription: "Central BI Warehouse with admin jobs, queries, and monitoring",
        overview: "Central BI warehouse infrastructure providing SQL Server-based data storage, transformation, and querying capabilities. Includes core database tables, views, administrative tools, and query utilities for BI and analytics.",
        location: ["DWH/", "Arkiv/DWH/"],
        dependencies: [],
        dependants: ["monthly-tasks","monthly-tasks"],
        requirements: [
            "SQL Server instance",
            "Windows Authentication",
            "Network access to database server"
        ],
        contactSupport: [
            "Internal DWH documentation",
            "SQL Server DBA team"
        ],
        examples: [
            {
                title: "Running Queries",
                description: "Example of querying data from the warehouse:",
                code: "-- Example: Column lookup\nSELECT * FROM YourTable WHERE ColumnName = 'Value';\n\n-- Example: Join tables\nSELECT a.*, b.Description\nFROM TableA a\nINNER JOIN TableB b ON a.ID = b.ID;"
            },
            {
                title: "Common Operations",
                description: "Typical use cases for the data warehouse:",
                code: "1. Data extraction for QlikView/QlikSense\n2. Ad-hoc analysis queries\n3. Data validation and verification"
            }
        ]
    },
    "sql-qv-converter": {
        id: "sql-qv-converter",
        title: "SQL → QlikView Converter",
        name: "SQL→QV Converter",
        category: "Warehouse",
        categoryColor: "#9C27B0",
        breadcrumb: "Warehouse / SQL→QV Converter",
        shortDescription: "Convert SQL queries to QlikView script and create PRs",
        overview: "PowerShell tool for converting SQL queries into QlikView script format and automatically creating pull requests in Azure DevOps. Streamlines the process of migrating warehouse queries to QlikView applications.",
        location: ["Powershell/SQLToQVConverter/"],
        dependencies: ["qlikview-engine", "devops-integration"],
        integrations: ["dwh-core"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Azure DevOps access",
            "QlikView script knowledge"
        ],
        relatedProjects: ["dwh-core", "qlikview-engine", "devops-integration"],
        contactSupport: [
            "BI development team",
            "See CreateBIQlikViewPullRequest.ps1 documentation"
        ],
        examples: [
            {
                title: "Basic Usage",
                description: "Convert a SQL query to QlikView script:",
                code: "# Run the converter\n.\\CreateBIQlikViewPullRequest.ps1 -QueryFile \"MyQuery.sql\"\n\n# Output: QlikView script + automatic PR creation"
            },
            {
                title: "SQL to QlikView Mapping",
                description: "Example of the conversion process:",
                code: "-- SQL Input\nSELECT CustomerID, CustomerName\nFROM Customers\nWHERE Country = 'Norway';\n\n// QlikView Output\nCustomers:\nLOAD\n    CustomerID,\n    CustomerName\nFROM [lib://DataWarehouse/Customers.qvd] (qvd)\nWHERE Country = 'Norway';"
            }
        ]
    },
    "qlik-sense": {
        id: "qlik-sense",
        title: "QlikSense Platform",
        name: "QlikSense Platform",
        category: "QlikSense",
        categoryColor: "#2196F3",
        breadcrumb: "QlikSense / Platform",
        shortDescription: "Qlik Sense version control and analysis tools",
        overview: "Tools and utilities for managing Qlik Sense Enterprise deployments, including version control, app analysis, QRS API integration, and platform monitoring. Enables automated management and governance of Sense applications.",
        location: ["QlikSense/"],
        dependencies: ["dwh-core"],
        integrations: ["pwsh-profile", "sit-cloud-tests"],
        requirements: [
            "Qlik Sense Enterprise installation",
            "QRS API access",
            "PowerShell with Qlik Sense modules"
        ],
        relatedProjects: ["dwh-core", "pwsh-profile", "sit-cloud-tests"],
        contactSupport: [
            "Qlik Sense admin team",
            "QlikSense documentation portal"
        ]
    },
    "qlikview": {
        id: "qlikview-engine",
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
        relatedProjects: ["qv-automation", "monthly-tasks", "sql-qv-converter", "pwsh-profile"],
        contactSupport: [
            "QlikView development team",
            "See QlikViewClient.ps1 for usage examples"
        ]
    },
    "monthly-tasks": {
        id: "monthly-tasks",
        title: "Monthly Tasks",
        name: "Monthly Tasks",
        category: "automation",
        categoryColor: "#FF9800",
        breadcrumb: "Automation / Monthly Tasks",
        shortDescription: "Automated monthly QVD transfers, health checks, and notifications",
        overview: "Scheduled automation framework for monthly BI operations. Handles QVD file transfers, health checks, link validation, and email notifications. Modular PowerShell architecture with centralized task orchestration.",
        location: ["MonthlyTasks/"],
        dependencies: ["qlikview-engine", "dwh-core"],
        integrations: ["pwsh-profile"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Scheduled Task permissions",
            "Access to QVD file shares",
            "SMTP server for email notifications"
        ],
        relatedProjects: ["qlikview-engine", "dwh-core", "pwsh-profile"],
        contactSupport: [
            "BI Operations team",
            "See master.ps1 for task scheduling"
        ]
    },
    "pwsh-profile": {
        id: "pwsh-profile",
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
        relatedProjects: ["qlik-sense", "qlikview-engine", "monthly-tasks", "qv-automation"],
        contactSupport: [
            "See profile.ps1 for customization",
            "PowerShell documentation"
        ]
    },
    "sit-cloud-tests": {
        id: "sit-cloud-tests",
        title: "SIT Cloud Tests",
        name: "SIT Cloud Tests",
        category: "other tools",
        categoryColor: "#4CAF50",
        breadcrumb: "Tools / SIT Cloud Tests",
        shortDescription: "Cloud testing for QlikSense and QlikView",
        overview: "Test suites for validating QlikSense and QlikView functionality in cloud environments. Includes test scenarios, validation scripts, and documentation for SIT (System Integration Testing) processes.",
        location: ["SIT Cloud tests/"],
        dependencies: ["qlik-sense", "qlikview-engine"],
        integrations: ["pwsh-profile", "devops-integration"],
        requirements: [
            "Cloud environment access",
            "Test credentials for QlikSense and QlikView",
            "See WhatToTest.txt for test scenarios"
        ],
        relatedProjects: ["qlik-sense", "qlikview-engine", "pwsh-profile"],
        contactSupport: [
            "QA team",
            "Cloud platform support"
        ]
    }
};

// Category definitions
const categories = {
    "Warehouse": {
        color: "#9C27B0",
        displayName: "Warehouse",
        icon: "🏛️"
    },
    "QlikSense": {
        color: "#2196F3",
        displayName: "QlikSense",
        icon: "🔵"
    },
    "QlikView": {
        color: "#00BCD4",
        displayName: "QlikView",
        icon: "🔷"
    },
    "automation": {
        color: "#FF9800",
        displayName: "Automation",
        icon: "⚙️"
    },
    "other tools": {
        color: "#4CAF50",
        displayName: "Other Tools",
        icon: "🛠️"
    },
    "Azure Devops": {
        color: "#607D8B",
        displayName: "Azure DevOps",
        icon: "🔧"
    }
};

// Helper function to get all projects as array (for portfolio.html)
function getAllProjects() {
    return Object.values(projectData);
}

// Helper function to get project by ID
function getProject(id) {
    return projectData[id];
}

// Helper function to get related projects
function getRelatedProjects(projectId) {
    const project = projectData[projectId];
    if (!project) return [];
    
    const related = new Set([...project.dependencies, ...project.integrations]);
    return Array.from(related).map(id => projectData[id]).filter(p => p);
}
