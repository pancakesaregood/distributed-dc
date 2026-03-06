# Business Case 04 - VDI Service Enablement

## Decision Statement
Deploy a standardized VDI service (Guacamole-based access path) to improve secure remote productivity and simplify endpoint dependency.

## Current Problem
- Remote user experience varies by endpoint and network posture.
- Support overhead increases with fragmented remote-access tooling.

## Proposed Investment
- Implement browser-based VDI access path behind existing DMZ controls.
- Integrate AD-backed authorization and MFA for session access.
- Deploy site-local desktop pools with policy-based failover behavior.

## Cost Drivers
- Additional compute/storage for desktop pools.
- Service operations and image lifecycle management.
- User onboarding and service desk enablement.

## Expected Business Outcomes
- Improved remote workforce continuity.
- Reduced endpoint configuration complexity.
- Faster recovery of user productivity during office/site disruptions.

## KPIs
- VDI session success rate.
- Service desk ticket volume for remote access issues.
- Time to provision or recover user desktop access.

## Recommendation
Approve where remote productivity, contractor access control, and support standardization are strategic priorities.
