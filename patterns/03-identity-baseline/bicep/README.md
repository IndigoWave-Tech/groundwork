# Why there is no Bicep for this pattern

Conditional Access policies, named locations, and Microsoft Entra groups are Microsoft Graph objects, not Azure Resource Manager resources. Bicep and ARM templates can only deploy ARM resources, so there is no resource type for them to target.

The honest options were:

| Option | Rejected because |
|---|---|
| Bicep deployment script resource running Graph PowerShell | Hides imperative script inside a declarative template, needs a managed identity with Graph permissions and a storage account, and gives no plan or drift detection. Worse than either a plain script or Terraform. |
| Microsoft Graph Bicep extension (preview) | At time of writing it covers groups and applications but not Conditional Access policies or named locations. Revisit when it does. |
| Exported JSON policy files for manual upload | Documents the intent but is not deployable code, has no drift detection, and no exclusion-group wiring. |

Terraform's `azuread` provider is the mature, supported way to manage these objects as code, with plan, apply, and drift detection. That is what this pattern uses.

The one ARM-native piece, the Entra diagnostic setting that sends sign-in and audit logs to the Pattern 01 workspace, is deployed by the same Terraform configuration so the pattern stays in one place.
