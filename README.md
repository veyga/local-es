# debaser - Database Operator

A k8s operator for dynamic provisioning of databases.

This repo sets up a local k8s cluster for development/testing of the operator itself.

## Usage
Run `just` to see list of relevant commands.

## Quick Start
`just installhooks`
`just build`
`just up`

## Local Development
On initial clone

You will have a local k8s cluster running docker, with your operator as a separate container.
Running things in that k8s context should trigger your operator.
For example, you can run `just k apply local/k8s/mysql/database.yaml` and you should see
operator logs. You can debug your operator locally too just by attaching a client.

Your cluster state will remain after you `just down`; you can effectively use this command to 
'stop' your cluster. Don't delete the stopped `kind` container though, or you will have to rebuild.
`just down --prune` clears all.

## Linting/Formatting
On initial clone, run `just installhooks`
Linting and formatting is run on commit. Code must be formatted and pass linting
in order to be committed. If you attempt to commit unformatted code, the formatter
formats automatically and places the changed files in the staging dir/index.
You will often have to `git add` and `git commit` twice when developing locally.

## Custom Resource Definitions (CRDs)

The operator manages two types of database resources:

### PostgresDatabase
- **CRD Name**: `postgresdbs.debaser.netx.us`
- **Kind**: `PostgresDatabase`
- **Spec**: Requires `databaseName`

**What it does:**
- Creates a PostgreSQL database and user in an existing PostgreSQL cluster
- Generates secure credentials (username: `{dbname}_admin`, random password)
- Saves credentials to Vault at: `kv/ops/postgres/{context}/{dbname}/{username}`

**On deletion:**
- Removes the database and user from PostgreSQL
- Deletes the secret from Vault

**Example:**
```yaml
---
apiVersion: debaser.netx.us/v1alpha1
kind: PostgresDatabase
metadata:
  name: exampledb
  namespace: default
spec:
  databaseName: exampledb
```

### MysqlDatabase
- **CRD Name**: `mysqldbs.debaser.netx.us`
- **Kind**: `MysqlDatabase`
- **Spec**: Requires `databaseName`, `secretStore`

**What it does:**
- Creates a MySQL database and user in an existing MySQL cluster
- Generates secure credentials (username based on dbname, random password)
- Saves credentials to Vault at: `mysql/{context}/{dbname}` (mount point configurable via `secretStore`)

**On deletion:**
- Removes the database and user from MySQL
- Deletes the secret from Vault

**Example:**
```yaml
---
apiVersion: debaser.netx.us/v1alpha1
kind: MysqlDatabase
metadata:
  name: exampledb
  namespace: default
spec:
  databaseName: exampledb
  secretStore: kv/netx
  netxSiteType: staff
  useProxysql: false
  rwSplitRouterPort: true
```

## New releases
- Deployment of this image uses the sole flow from CICD
- See the CICD [docs](https://gitlab.netx.net/netx/infrastructure/cicd/docs), specifically the section about `Sole`. 

## bin
`debaser` also serves as a debugging pod for easier access to mysql/proxysql, as it
contains the needed creds in its environment. Use the commands in `bin` for easier access
to mysql and proxysql. You can interact with postgres directly via `psql`.

# Kopf CRD Behavior: Adding & Removing Fields (Defaults vs Required)

This section summarizes how Kubernetes + Kopf behave when you change CRD schema, and how those changes affect:
- Existing CRD instances
- Kopf `@on.update` handlers
- GitOps tools (e.g., ArgoCD)

**Note:** Kopf does not support multiple versions of the same CRD simultaneously in the same cluster. 
Make changes to existing CRDs using the same apiVersion rather than introducing a new apiVersion. 
See also [SYS-9483](https://netx-dam.atlassian.net/browse/SYS-9483).

---

## Key Concepts

- **Default field (optional + default):**  
  A field defined in the CRD schema with a default value. Resource YAML does not need to include it.

- **Required field:**  
  A field listed in the CRD `required` section. Every CRD instance must explicitly define it.

- **Kopf `@on.update`:**  
  Triggered when a CRD instance spec changes — not when the CRD schema changes.

---

## 1. Adding an Optional Field (with Default)

### Behavior
- The new field is **automatically populated** into all existing CRD instances.
- **Kopf `on_update` fires once per CRD instance**, because every spec changes.
- The live cluster reflects the new default value immediately.

### GitOps (e.g., ArgoCD)
- The default field **will not appear as a diff** if it is not explicitly present in the Git manifest.
- Argo **does not revert** or fight these changes.

### Use Case
Good for **bulk changes**, migrations, or backfill:
- Update CRD → all instances receive default → operator runs logic once per instance.

---

## 2. Removing an Optional Field (with Default)

### Behavior
- The field is **removed from all existing CRD instances**.
- **Kopf `on_update` is triggered** for each affected resource.
- The updated spec no longer contains the field.

### Use Case
- Cleaning up deprecated fields.
- Triggering migration after removing a feature.

---

## 3. Adding a Required Field (no default)

### Kubernetes validation details
- **Existing CRD instances are grandfathered.**  
  They do not get revalidated and remain valid even if they lack the field.
- **Newly created or modified instances must include the field** or validation fails.

### Kopf
- **No `on_update` is triggered**, because existing specs do not change.

### GitOps
- Existing Git-managed YAML remains unchanged and valid.
- **Any edit** to a CRD instance must include the new required field or it will fail validation.

---

## 4. Removing a Previously Required Field

### Behavior
- Existing CRDs that had the field will have it **removed**.
- **Kopf `on_update` runs** for those instances with updated specs.

---

## 5. Editing Existing CRDs Manually

- `kubectl apply` with no changes → **no-update** → `on_update` does not fire.
- If the CRD schema demands a new required field and it isn't provided:
  - Apply will **fail validation**.
- GitOps behaves the same:
  - No change → no rollout.
  - Change without the required field → invalid.

---

## Practical Strategy

- **Use default fields** to trigger **bulk updates**:  
  > Add field with default → all resources update → operator logic runs once per resource.

- **Use required fields** for **targeted changes**:  
  > Add required schema → update individual CRDs where you want behavior changes.

--- 
