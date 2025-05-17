# Azure Infrastructure Architecture Diagram

This document describes the architecture diagram for the Azure infrastructure. The diagram can be created using tools like draw.io, Lucidchart, or Microsoft Visio.

## Diagram Components

### Network Topology
1. **Frontend Virtual Network (10.0.0.0/16)**
   - WAF Subnet (10.0.0.0/24)
   - App Service Subnet (10.0.1.0/24)

2. **Backend Virtual Network (10.1.0.0/16)**
   - Database Subnet (10.1.0.0/24)

3. **VNet Peering**
   - Bidirectional peering between Frontend and Backend VNets

### Security Components
1. **Network Security Groups (NSGs)**
   - WAF NSG: Allows HTTP/HTTPS from Internet
   - App Service NSG: Allows traffic only from WAF subnet
   - Database NSG: Allows traffic only from App Service subnet

2. **Private Endpoints**
   - SQL Server Private Endpoint in Database subnet

3. **Web Application Firewall**
   - Deployed as an Application Gateway with WAF_v2 SKU
   - Public-facing with static IP
   - Protection for the App Service

### Application Components
1. **App Service**
   - Integrated with Frontend VNet
   - System-assigned managed identity
   - HTTPS only enabled
   - Connected to SQL Database via private endpoint

2. **SQL Database**
   - Public network access disabled
   - Accessible only via private endpoint
   - Located in Backend VNet

### Monitoring Components
1. **Log Analytics Workspace**
   - Central repository for logs

2. **Application Insights**
   - Connected to App Service
   - Linked to Log Analytics Workspace

3. **Diagnostic Settings**
   - Configured for App Service, SQL Server, and WAF
   - Sends logs and metrics to Log Analytics Workspace

## Traffic Flow Description

1. **User Traffic Flow**
   - Internet users → WAF Public IP → WAF/Application Gateway → App Service (via VNet integration)
   - App Service → SQL Server (via Private Endpoint)

2. **Management Traffic Flow**
   - Azure Portal/APIs → Resource Provider endpoints → Resources

## Diagram Layout

The diagram should be organized in the following way:
- Internet users at the top
- WAF/Application Gateway in a security perimeter
- Frontend VNet and Backend VNet side by side
- App Service in Frontend VNet
- SQL Server and Private Endpoint in Backend VNet
- Monitoring components at the bottom
- Arrows indicating traffic flow
- NSGs represented at subnet boundaries

## Color Coding

- Frontend VNet: Blue
- Backend VNet: Green
- Security Components: Red
- Monitoring Components: Purple
- External Traffic: Orange arrows
- Internal Traffic: Blue arrows
