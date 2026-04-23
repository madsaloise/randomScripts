# Qlik Sense QRS API Testing

This folder contains scripts and modules for testing Qlik Sense environments using the QRS (Repository Service) API.

## Structure

- **SenseConnect.ps1** - Main test script for validating Qlik Sense connectivity and features
- **Modules/** - Contains reusable modules and classes
  - **QRSClient.ps1** - Client class for QRS API interactions

## QRSClient Class

The `QRSClient` class provides a structured interface for making REST API calls to Qlik Sense QRS.

### Features

- Automatic XRF key generation
- TLS 1.2 configuration
- Certificate validation bypass (for test environments)
- Windows authentication support
- Convenience methods for common API endpoints

### Usage

```powershell
# Initialize client
$qrsClient = [QRSClient]::new("sense-server.domain.com")

# Get all apps
$apps = $qrsClient.GetApps()

# Get specific app
$app = $qrsClient.GetApp("app-id-guid")

# Get users
$users = $qrsClient.GetUsers()

# Get streams
$streams = $qrsClient.GetStreams()

# Get reload tasks
$tasks = $qrsClient.GetReloadTasks()

# Start a reload task
$result = $qrsClient.StartReloadTask("task-id-guid")

# Custom endpoint call
$response = $qrsClient.Get("customendpoint", @{ filter = "name eq 'MyApp'" })
```

### Common Methods

- `Get(endpoint)` - GET request
- `Post(endpoint, body)` - POST request
- `Put(endpoint, body)` - PUT request
- `Delete(endpoint)` - DELETE request
- `GetApps()` - Retrieve all apps
- `GetUsers()` - Retrieve all users
- `GetStreams()` - Retrieve all streams
- `GetTasks()` - Retrieve all tasks
- `GetReloadTasks()` - Retrieve all reload tasks with full details
- `GetAbout()` - Get Qlik Sense version and build info

## Running Tests

```powershell
# Run with default server (from profile)
.\SenseConnect.ps1

# Run with specific server
.\SenseConnect.ps1 -SenseServer "sense-server.domain.com"
```

## Requirements

- PowerShell 5.1 or later
- Windows authentication access to Qlik Sense QRS API
- EnhancedLogger module (from pwshProfile)
- `$senseHubTest` variable defined in PowerShell profile (or pass -SenseServer parameter)
