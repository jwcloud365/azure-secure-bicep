# Secure Azure Infrastructure with Bicep

This repository contains a complete Azure infrastructure deployment using Bicep templates. The architecture features a secure web application setup with an App Service as frontend and Azure SQL Database as backend, connected via private endpoints and protected by a Web Application Firewall. The entire infrastructure has been implemented with a security-first approach to ensure isolation and protection of sensitive resources.

## Architecture Overview

The infrastructure includes:
- App Service (Frontend) with health endpoint for monitoring
- Azure SQL Database (Backend) secured with private endpoints
- Web Application Firewall (Application Gateway) with custom health probes
- Azure Key Vault for secret management and credential storage
- Virtual Networks with subnet segregation (Frontend and Backend)
- Private Endpoints for secure connectivity between components
- Network Security Groups for traffic control with least-privilege rules
- Monitoring with Log Analytics and diagnostic integration

For a detailed architecture diagram, see [Architecture Diagram](./infra/Final-Architecture-Diagram.md).

## Documentation

This repository includes comprehensive documentation:

| Document | Description |
|----------|-------------|
| [README.md](./README.md) | This file with project overview and instructions |
| [PLANNING.md](./PLANNING.md) | Project planning document with vision and constraints |
| [TASK.md](./TASK.md) | Task tracking with implementation checklist |
| [DEPLOYMENT_TASK.md](./DEPLOYMENT_TASK.md) | Detailed deployment tasks and progress |
| [SUMMARY.md](./SUMMARY.md) | Implementation summary with key decisions |
| [COMPLETION.md](./COMPLETION.md) | Deployment completion summary |
| [VALIDATION_REPORT.md](./VALIDATION_REPORT.md) | Infrastructure validation test results |
| [STATUS_REPORT.md](./STATUS_REPORT.md) | Current status report for all components |
| [AZURE_DEPLOYMENT_SUMMARY.txt](./AZURE_DEPLOYMENT_SUMMARY.txt) | Comprehensive deployment summary |
| [Architecture Diagram](./infra/Architecture-Diagram.md) | Architecture diagram description |
| [Final Architecture Diagram](./infra/Final-Architecture-Diagram.md) | Final architecture diagram in ASCII format |

## Repository Structure

```
.
├── DEPLOYMENT_TASK.md    # Detailed deployment tasks and progress tracking
├── PLANNING.md           # High-level planning document
├── SUMMARY.md            # Implementation summary
├── TASK.md               # Project tasks and progress tracking
├── README.md             # This file
├── infra/                # Infrastructure as Code files
│   ├── main.bicep        # Main deployment template
│   ├── main.deployment.parameters.json # Parameters for deployment
│   ├── appservice.parameters.json # App Service parameters
│   ├── database.parameters.json    # Database parameters
│   ├── keyvault.parameters.json    # Key Vault parameters 
│   ├── waf.parameters.json         # WAF parameters
│   ├── Architecture-Diagram.md # Architecture diagram description
│   ├── modules/          # Bicep modules
│   │   ├── appService-simple.bicep  # Simplified App Service deployment
│   │   ├── appService.bicep  # App Service deployment
│   │   ├── database-simple.bicep    # Simplified Database deployment 
│   │   ├── database.bicep    # Database deployment
│   │   ├── keyVault-simple.bicep    # Simplified Key Vault deployment
│   │   ├── keyVault.bicep    # Key Vault for secret management
│   │   ├── monitoring.bicep  # Monitoring resources
│   │   ├── networking.bicep  # VNets, subnets, NSGs
│   │   ├── networking-fixed.bicep  # Fixed networking module
│   │   ├── privateDnsZones.bicep # Private DNS Zones for private endpoints
│   │   ├── resourceGroup.bicep # Resource group creation
│   │   └── waf.bicep         # WAF/Application Gateway with custom health probes
│   ├── scripts/          # Deployment scripts
│   │   ├── configure-private-endpoints.sh # Script for private endpoints
│   │   ├── configure-vnet-integration.sh # Script for VNet integration
│   │   ├── deploy-full.sh   # Full deployment script
│   │   ├── deploy-keyvault.sh # Key Vault deployment
│   │   ├── deploy-monitoring.sh # Monitoring deployment 
│   │   ├── deploy-waf.sh    # WAF deployment
│   │   ├── deploy-waf-improved.sh # Fixed WAF deployment
│   │   ├── deploy-waf-bicep.sh # Alternative WAF deployment with Bicep
│   │   ├── test-deploy-networking.sh # Networking deployment
│   │   ├── test-deploy-rg.sh # Resource group deployment
│   │   ├── validate-infrastructure.sh # Validation script
│   │   └── fix-sql-security.sh # Script to fix SQL security
│   └── tests/            # Test scripts
│       ├── run-tests.sh  # Main test script
│       ├── deploy-test-app.sh # Test app deployment script
│       ├── app/          # Test application files
│       └── test-page.html # Test page template
```

## Prerequisites

- Azure CLI installed and configured
- Access to an Azure subscription
- Bash shell environment (GitBash, WSL, or Linux/macOS terminal)

## Deployment Instructions

### Prerequisites
- Azure CLI installed and configured
- Access to an Azure subscription
- Bash shell environment (GitBash, WSL, or Linux/macOS terminal)

### Deployment Options

#### Option 1: Complete Deployment
To deploy the entire infrastructure in one go:

```bash
cd infra/scripts
chmod +x deploy-full.sh
./deploy-full.sh
```

#### Option 2: Step-by-Step Deployment
For a more controlled deployment process:

```bash
cd infra/scripts
chmod +x deploy-step-by-step.sh
./deploy-step-by-step.sh
```

### Post-Deployment Configuration

After deployment, execute the following scripts to complete the configuration:

1. Configure VNet Integration for App Service:
```bash
cd infra/scripts
chmod +x configure-vnet-integration.sh
./configure-vnet-integration.sh
```

2. Configure Private Endpoints for SQL Server:
```bash
cd infra/scripts
chmod +x configure-private-endpoints.sh
./configure-private-endpoints.sh
```

3. Fix SQL Server Security Settings:
```bash
cd infra/scripts
chmod +x fix-sql-security.sh
./fix-sql-security.sh
```

## Testing

To validate the deployed infrastructure:

```bash
cd infra/tests
chmod +x run-tests.sh
./run-tests.sh
```

To deploy a test application to the App Service:

```bash
cd infra/tests
chmod +x deploy-test-app.sh
./deploy-test-app.sh
```

The test application includes:
- Static HTML page showing deployment status
- Health API endpoint for WAF health probes
- Basic web.config for Node.js runtime

## Security Features

This infrastructure implements multiple security layers:

1. **Network Isolation**:
   - Frontend and backend resources in separate VNets
   - NSGs with least privilege access rules
   - Private endpoints for backend services

2. **WAF Protection**:
   - Application Gateway with WAF_v2 SKU
   - OWASP 3.2 ruleset in Prevention mode
   - Custom health probe for App Service monitoring

3. **Access Control**:
   - SQL Server with public network access disabled
   - Key Vault for secure credential storage
   - System-assigned managed identities

4. **Monitoring**:
   - Log Analytics workspace for centralized logging
   - Diagnostic settings for all resources
   - Application Insights integration (planned)

## Maintenance

Regular maintenance tasks:
1. Review and apply security patches
2. Monitor WAF logs for attack patterns
3. Check diagnostic logs for anomalies
4. Update OWASP ruleset as new versions become available
5. Rotate SQL credentials periodically

## Limitations and Known Issues

- Key Vault private endpoint needs further configuration
- End-to-end application testing with database connectivity pending
- Certificate management for Application Gateway not yet implemented

## Contributing

1. Review the PLANNING.md for design guidelines
2. Update DEPLOYMENT_TASK.md with any new tasks or improvements
3. Follow the modular approach when adding new components
4. Include test scripts for new components

## Documentation

- [DEPLOYMENT_TASK.md](./DEPLOYMENT_TASK.md) - Detailed tasks and progress tracking
- [SUMMARY.md](./SUMMARY.md) - Implementation summary and overview
- [Architecture Diagram](./infra/Architecture-Diagram.md) - Visual representation of the architecture

## Environment Information

- **Tenant ID:** 24716ce3-de3f-46ef-a555-0dd2c9e293d8
- **Subscription ID:** 6d505432-f45f-4fb8-9afb-a5c761876cd3
- **Primary Region:** Sweden Central
- **Date:** May 18, 2025

## License

MIT License
