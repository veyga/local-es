resource "kubernetes_manifest" "nodeport" {
  manifest = yamldecode(<<-EOF
apiVersion: v1
kind: Service
metadata:
  name: ${var.service_name}
  namespace: ${var.namespace}
spec:
  type: NodePort
  selector:
%{for key, value in var.selectors~}
    ${key}: ${value}
%{endfor~}
  ports:
  - port: ${var.ports.target}
    targetPort: ${var.ports.target}
    nodePort: ${var.ports.node}
    protocol: ${var.protocol}
EOF
  )
}
