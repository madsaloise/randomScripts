// Warehouse category projects
const warehouseProjects = {
    "BI_Warehouse": {
        title: "BI Warehouse",
        name: "BI Warehouse",
        category: "Warehouse",
        languages: ["SQL"],
        shortDescription: "Central BI Warehouse with admin jobs, queries, and monitoring",
        overview: "Central BI warehouse infrastructure providing SQL Server-based data storage, transformation, and querying capabilities. Includes core database tables, views, administrative tools, and query utilities for BI and analytics.",
        location: ["DWH/", "Arkiv/DWH/"],
        dependencies: [],
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
    "SQLToQV_Converter": {
        title: "SQL to QlikView Converter",
        name: "SQL to QV Converter",
        category: "Warehouse",
        languages: ["PowerShell", "SQL", "Qlik"],
        shortDescription: "Convert SQL queries to QlikView script and create PRs",
        overview: "PowerShell tool for converting SQL queries into QlikView script format and automatically creating pull requests in Azure DevOps. Streamlines the process of migrating warehouse queries to QlikView applications.",
        location: ["Powershell/SQLToQVConverter/"],
        dependencies: ["BI_Warehouse", "BI_QlikView"],
        requirements: [
            "PowerShell 5.1 or higher",
            "Azure DevOps access",
            "QlikView script knowledge"
        ],
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
    }
};
