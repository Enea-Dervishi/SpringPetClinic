apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
  namespace: ${namespace}
  labels:
    app: ${app_name}
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      imagePullSecrets:
        - name: ${ghcr_secret_name}
      containers:
        - name: ${app_name}
          image: ${image_repository}:${image_tag}
          ports:
            - containerPort: ${container_port}
          resources:
            limits:
              cpu: ${cpu_limit}
              memory: ${memory_limit}
            requests:
              cpu: ${cpu_request}
              memory: ${memory_request}
          env:
            - name: SERVER_PORT
              value: "${container_port}"
          livenessProbe:
            httpGet:
              path: /manage/health
              port: ${container_port}
            initialDelaySeconds: 120
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /manage/health
              port: ${container_port}
            initialDelaySeconds: 60
            periodSeconds: 10 