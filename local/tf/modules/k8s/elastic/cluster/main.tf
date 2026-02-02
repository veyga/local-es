resource "kubernetes_manifest" "cluster" {
  # object owners (typically via operators) can modify fields
  # this results in conflicts with TF
  field_manager {
    force_conflicts = true
  }

  lifecycle {
    ignore_changes = [
      object.spec.nodeSets[0].podTemplate.metadata
    ]
  }
  # Recommended for local clusters
  # node.store.allow_mmap: false
  # Disabling results in degraded performance, 
  # but better stability in constrained envs (e.g. local)
  manifest = yamldecode(<<-EOF
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: ${var.cluster.name}
  namespace: ${var.namespace}
spec:
  version: ${var.cluster.version}
  nodeSets:
    - name: ${var.nodeset.name}
      count: ${var.nodeset.count}
%{if var.ctx == "kind-locales"~}
      config:
        node.store.allow_mmap: false
%{endif~}
      podTemplate:
        spec:
          containers:
            - name: elasticsearch
%{if var.jvm_options != null~}
              env:
                - name: JAVA_TOOL_OPTIONS
                  value: "${join(" ", var.jvm_options)}"
%{endif~}
%{if var.resources != null~}
              resources:
                requests:
                  memory: "${var.resources.requests.memory}"
                  cpu: "${var.resources.requests.cpu}"
                limits:
                  memory: "${var.resources.limits.memory}"
                  cpu: "${var.resources.limits.cpu}"
%{endif~}
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: "${var.storage}"
EOF
  )
}

# Without this check an apply will report as successful
# Even if the pods never start successfully
resource "null_resource" "wait_for_cluster" {
  depends_on = [kubernetes_manifest.cluster]

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      echo "Waiting for Elasticsearch cluster '${var.cluster.name}' to be ready..."
      for i in $(seq 1 10); do
        PHASE=$(kubectl get elasticsearch ${var.cluster.name} -n ${var.namespace} -o jsonpath='{.status.phase}' 2>/dev/null)
        HEALTH=$(kubectl get elasticsearch ${var.cluster.name} -n ${var.namespace} -o jsonpath='{.status.health}' 2>/dev/null)
        echo "  Attempt $i: phase=$PHASE health=$HEALTH"
        if [ "$PHASE" = "Ready" ] && [ "$HEALTH" = "green" ]; then
          echo "Elasticsearch cluster is ready."
          exit 0
        fi
        sleep 10
      done
      echo "Timed out waiting for Elasticsearch cluster to become ready."
      exit 1
    EOT
  }
}
