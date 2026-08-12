# Costos — etapa AWS

Placeholder (ADR 011). La tabla de verdad sale de Infracost cuando exista `iac/aws`:

```bash
infracost breakdown --path iac/aws
```

No correr Infracost sobre `iac/local` (LocalStack = USD 0).

Hasta A7, la estimación de orden de magnitud está en el plan: ~USD 0.80 por 8 h con destroy; ~USD 36 si se olvida 30 días. Región: `us-east-1`. Sin NAT Gateway.

Después del primer apply, contrastar con Cost Explorer (~48 h).
