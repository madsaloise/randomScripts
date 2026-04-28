// Merge all category project files into one projectData object
const projectData = {
    ...warehouseProjects,
    ...qlikviewProjects,
    ...automationProjects,
    ...otherToolsProjects
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
    return Object.entries(projectData).map(([key, project]) => ({
        ...project,
        id: key  // Attach object key as id
    }));
}

// Helper function to get project by ID
function getProject(id) {
    const project = projectData[id];
    if (!project) return null;
    return {
        ...project,
        id: id  // Attach object key as id
    };
}

// Helper function to dynamically calculate dependants
function getDependants(projectId) {
    return Object.entries(projectData)
        .filter(([_, project]) => project.dependencies?.includes(projectId))
        .map(([key, _]) => key);
}

// Helper function to get related projects (combines dependencies and integrations)
function getRelatedProjects(projectId) {
    const project = projectData[projectId];
    if (!project) return [];
    
    const related = new Set([
        ...(project.dependencies || []),
        ...(project.integrations || [])
    ]);
    return Array.from(related)
        .map(id => {
            const p = projectData[id];
            return p ? { ...p, id } : null;
        })
        .filter(p => p);
}
