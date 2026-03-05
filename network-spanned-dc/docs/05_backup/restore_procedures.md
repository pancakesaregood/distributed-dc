# Restore Procedures

## Restore Workflow
1. Declare restore scope and incident reference.
2. Identify latest known clean restore point.
3. Restore into isolated validation environment.
4. Execute integrity and application checks.
5. Promote restored dataset to production path.
6. Monitor service and close incident with evidence.

## Tier-Specific Procedure Notes
- Configs and repositories: restore Git mirrors first to rehydrate automation state.
- Databases: apply snapshot then replay logs to target point.
- VM images: restore base image, then reattach recovered volumes.
- Container registry: restore metadata index before blob layers to avoid orphaned references.

## Verification Checklist
- Data checksum or consistency verification passes.
- Application startup and synthetic transaction checks pass.
- Replication resumes without backlog growth.
- Security review confirms no residual malicious artifacts.
