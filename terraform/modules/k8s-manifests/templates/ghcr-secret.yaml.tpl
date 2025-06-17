apiVersion: v1
kind: Secret
metadata:
  name: ${secret_name}
  namespace: ${namespace}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${base64encode(jsonencode({
    auths = {
      "ghcr.io" = {
        auth = base64encode("${ghcr_username}:${ghcr_token}")
      }
    }
  }))} 