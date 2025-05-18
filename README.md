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

For a detailed architecture diagram, see [Architecture Diagram](./infra/Architecture-Diagram.md).

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
│   │   └── deploy.ps1    # PowerShell deployment script
│   └── tests/            # Validation test scripts
│       ├── run-all-tests.sh  # Master test runner
│       ├── test-appservice.sh # App Service tests
│       ├── test-database.sh   # Database tests
│       ├── test-e2e-deployment.sh # End-to-end tests
│       ├── test-health-probe.sh # Health probe tests
│       ├── test-monitoring.sh # Monitoring tests
│       ├── test-networking.sh # Networking tests
│       ├── test-validation.sh # Validation tests
│       └── test-waf.sh       # WAF tests
```

## Prerequisites

- Azure CLI installed and configured
- Bash or PowerShell environment
- Azure subscription and appropriate permissions
- (Optional) Bicep CLI for local development

## Deployment Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/jwcloud365/azure-secure-bicep.git
   cd azure-secure-bicep
   ```

2. Review parameter files:
   - `infra/main.deployment.parameters.json` - Main deployment parameters
   - `infra/keyvault.parameters.json` - Key Vault parameters
   - `infra/database.parameters.json` - Database parameters
   - `infra/appservice.parameters.json` - App Service parameters
   - `infra/waf.parameters.json` - WAF parameters
   - Update the values with your specific configuration

3. Make the deployment scripts executable:
   ```bash
   chmod +x infra/scripts/*.sh
   chmod +x infra/tests/*.sh
   ```

4. Deploy the complete infrastructure:
   ```bash
   ./infra/scripts/deploy-full.sh
   ```
   
   Or deploy individual components:
   ```bash
   # Resource Group
   ./infra/scripts/test-deploy-rg.sh
   
   # Networking
   ./infra/scripts/test-deploy-networking.sh
   
   # Key Vault
   ./infra/scripts/deploy-keyvault.sh
   
   # And so on for other components
   ```

5. Validate the deployment:
   ```bash
   ./infra/scripts/validate-infrastructure.sh
   ```

## Customization

- **Resource Sizing**: Modify the SKUs in the Bicep module files to adjust resource sizes
- **Network Settings**: Update address spaces in the networking.bicep file
- **Security Rules**: Modify NSG rules in networking.bicep to adjust security posture
- **Monitoring**: Configure additional diagnostic settings in monitoring.bicep
- **Health Probes**: Configure custom health probe settings in waf.bicep
- **Secret Management**: Update Key Vault access policies and secrets in keyVault.bicep

## Security Features

- Frontend protected by WAF (OWASP ruleset)
- Backend database accessible only via private endpoint
- No direct internet exposure for backend resources
- Network segmentation with NSGs
- HTTPS enforced on App Service
- Managed identity for secure authentication

## Monitoring and Management

- All components send logs to a central Log Analytics Workspace
- Application Insights for application telemetry
- Diagnostic settings for infrastructure components
- Comprehensive metrics and logs available in Azure Portal

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
