# Azure Infrastructure with Bicep

This repository contains a complete Azure infrastructure deployment using Bicep templates. The architecture features a secure web application setup with an App Service as frontend and Azure SQL Database as backend, connected via private endpoints and protected by a Web Application Firewall.

## Architecture Overview

The infrastructure includes:
- App Service (Frontend)
- Azure SQL Database (Backend)
- Web Application Firewall (Application Gateway)
- Virtual Networks with subnet segregation
- Private Endpoints for secure connectivity
- Network Security Groups for traffic control
- Monitoring with Log Analytics and Application Insights

For a detailed architecture diagram, see [Architecture Diagram](./infra/Architecture-Diagram.md).

## Repository Structure

```
.
├── PLANNING.md           # High-level planning document
├── TASK.md               # Project tasks and progress tracking
├── README.md             # This file
├── infra/                # Infrastructure as Code files
│   ├── main.bicep        # Main deployment template
│   ├── main.parameters.json # Parameters for deployment
│   ├── Architecture-Diagram.md # Architecture diagram description
│   ├── modules/          # Bicep modules
│   │   ├── appService.bicep  # App Service deployment
│   │   ├── database.bicep    # Database deployment
│   │   ├── monitoring.bicep  # Monitoring resources
│   │   ├── networking.bicep  # VNets, subnets, NSGs
│   │   ├── resourceGroup.bicep # Resource group creation
│   │   └── waf.bicep         # WAF/Application Gateway
│   ├── scripts/          # Deployment scripts
│   │   ├── deploy.ps1    # PowerShell deployment script
│   │   └── deploy.sh     # Bash deployment script
│   └── tests/            # Validation test scripts
│       ├── run-all-tests.sh  # Master test runner
│       ├── test-appservice.sh # App Service tests
│       ├── test-database.sh   # Database tests
│       ├── test-monitoring.sh # Monitoring tests
│       ├── test-networking.sh # Networking tests
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
   git clone <repository-url>
   cd Biceptest
   ```

2. Update the parameter file:
   - Open `infra/main.parameters.json`
   - Update the values with your specific configuration
   - For secure parameters, use Key Vault references or provide them during deployment

3. Deploy the infrastructure:

   **Using Bash:**
   ```bash
   # Update subscription ID and tenant ID in the script
   vi infra/scripts/deploy.sh
   # Make the script executable
   chmod +x infra/scripts/deploy.sh
   # Run the deployment
   ./infra/scripts/deploy.sh
   ```

   **Using PowerShell:**
   ```powershell
   # Update subscription ID and tenant ID in the script
   notepad infra/scripts/deploy.ps1
   # Run the deployment
   ./infra/scripts/deploy.ps1
   ```

4. Validate the deployment:
   ```bash
   # Make the test scripts executable
   chmod +x infra/tests/*.sh
   # Run all tests
   ./infra/tests/run-all-tests.sh
   ```

## Customization

- **Resource Sizing**: Modify the SKUs in the Bicep module files to adjust resource sizes
- **Network Settings**: Update address spaces in the networking.bicep file
- **Security Rules**: Modify NSG rules in networking.bicep to adjust security posture
- **Monitoring**: Configure additional diagnostic settings in monitoring.bicep

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
2. Update TASK.md with any new tasks
3. Follow the modular approach when adding new components
4. Include test scripts for new components

## License

[Specify your license information]
