# Hextris Kubernetes Deployment

This project demonstrates how to deploy the **Hextris web game** on a **Kubernetes cluster** using **Docker, Helm, Terraform, and Jenkins** for CI/CD automation.

---

## Project Structure

```

hextris-k8s-deployment/
│
├── app/
│ ├── index.html
│ ├── js/
│ ├── style/
│ ├── images/
│ ├── vendor/
│ ├── favicon.ico
│ └── manifest.webmanifest
│
├── Dockerfile
├── helm-chart/
│ ├── Chart.yaml
│ ├── values.yaml
│ └── templates/
│ ├── deployment.yaml
│ ├── service.yaml
│ └── ingress.yaml
├── terraform/
│ └── main.tf
├── jenkins/
│ └── Jenkinsfile
└── README.md

````

---

## Prerequisites

You’ll need to have these installed locally:

- **Docker**
- **Minikube** or any Kubernetes cluster (EKS, GKE, AKS)
- **Helm**
- **Terraform**
- **Kubectl**
- **Jenkins**

---

## Files Content

### Dockerfile
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN if [ -f package.json ]; then npm ci --silent || true; fi
COPY . .
RUN if [ -f package.json ] && grep -q "\"build\"" package.json; then \
      npm run build --silent; \
      mkdir -p /app/dist && cp -r ./dist/* /app/dist/ || true; \
    else \
      mkdir -p /app/dist && cp -r . /app/dist/ ; \
    fi

FROM nginx:stable-alpine
COPY --chown=nginx:nginx --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
````

---

### Helm Chart

#### `helm-chart/Chart.yaml`

```yaml
apiVersion: v2
name: hextris
version: 0.1.0
description: Helm chart for Hextris web app
```

#### `helm-chart/values.yaml`

```yaml
replicaCount: 2

image:
  repository: israa2000/hextris
  tag: latest

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "250m"
    memory: "256Mi"

ingress:
  enabled: true
  hosts:
    - host: hextris.local
      paths:
        - path: /
          pathType: Prefix    
```

#### `helm-chart/templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "hextris.name" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "hextris.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "hextris.name" . }}
    spec:
      containers:
        - name: hextris
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: {{ .Values.resources.requests.cpu }}
              memory: {{ .Values.resources.requests.memory }}
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}
```

#### `helm-chart/templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hextris.name" . }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "hextris.name" . }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
```

#### `helm-chart/templates/ingress.yaml`

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "hextris.name" . }}
spec:
  rules:
    - host: {{ .Values.ingress.hosts[0].host }}
      http:
        paths:
          - path: {{ .Values.ingress.hosts[0].paths[0].path }}
            pathType: {{ .Values.ingress.hosts[0].paths[0].pathType }}
            backend:
              service:
                name: {{ include "hextris.name" . }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
```

---

### Terraform

#### `terraform/main.tf`

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "hextris" {
  metadata {
    name = "hextris"
  }
}

resource "helm_release" "hextris" {
  name       = "hextris"
  chart      = "${path.module}/../../chart/hextris"
  namespace  = kubernetes_namespace.hextris.metadata[0].name
  values = [
    yamlencode({
      replicaCount = 2
      image = {
        repository = "docker.io/israa2000/hextris"
        tag        = "latest"
      }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
    })
  ]
}
```

---

### Jenkins

#### `jenkins/Jenkinsfile`

```groovy
pipeline {
    agent {
        kubernetes {
            label 'kaniko-agent'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: kaniko-agent
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    tty: true
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker
  volumes:
  - name: kaniko-secret
    secret:
      secretName: docker-config-json
"""
        }
    }

    environment {
        IMAGE_NAME = "docker.io/israa2000/hextris:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                container('kaniko') {
                    withCredentials([string(credentialsId: 'DOCKER_CONFIG_JSON', variable: 'DOCKER_CONFIG_JSON')]) {
                        sh """
                          mkdir -p /kaniko/.docker
                          echo "\$DOCKER_CONFIG_JSON" > /kaniko/.docker/config.json
                          /kaniko/executor \\
                            --dockerfile=$WORKSPACE/Dockerfile \\
                            --context=dir://$WORKSPACE \\
                            --destination=${IMAGE_NAME} \\
                            --cache=true
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                  terraform init
                  terraform apply -auto-approve
                """
            }
        }
    }
}
```

---

## Deployment Steps

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/israa-mosad/hextris-k8s-deployment.git
cd hextris-k8s-deployment
```

### 2️⃣ Build Docker Image

```bash
docker build -t israa/hextris:latest .
```

### 3️⃣ Start Minikube

```bash
minikube start
```

### 4️⃣ Deploy with Helm

```bash
helm upgrade --install hextris ./helm-chart --namespace hextris --create-namespace
```

### 5️⃣ Access the Application

```bash
minikube service hextris -n hextris
```

➡️ This will open the **Hextris game** in your browser 

---

## Terraform (optional)

To create a namespace with Terraform:

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

---

## Jenkins CI/CD

* **Jenkins URL:** `[your_Jenkins_URL]`
* **Username:** `[your_username]`
* **Password:** `[your_pass]`

The Jenkins pipeline:

1. Builds the Docker image
2. Deploys Hextris using Helm
3. Runs on Kubernetes agent pods (via PodTemplates)

---

## Cleanup

To delete everything:

```bash
helm uninstall hextris -n hextris
kubectl delete namespace hextris
minikube stop
```

---

