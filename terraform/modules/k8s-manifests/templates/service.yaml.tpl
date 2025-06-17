apiVersion: v1
kind: Service
metadata:
  name: ${app_name}
  namespace: ${namespace}
  labels:
    app: ${app_name}
spec:
  type: NodePort
  selector:
    app: ${app_name}
  ports:
    - port: ${service_port}
      targetPort: ${container_port}
      nodePort: ${node_port}
      protocol: TCP 