# Hextris Kubernetes Deployment

This project demonstrates how to deploy the **Hextris web game** on a **Kubernetes cluster** using **Docker, Helm, Terraform, and Jenkins** for CI/CD automation.

---

## Project Structure

```

hextris-k8s-deployment/
├── Dockerfile
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── terraform/
│   └── main.tf
├── jenkins/
│   └── Jenkinsfile
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
FROM nginx:alpine
COPY app/ /usr/share/nginx/html
EXPOSE 80
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
  repository: israa/hextris
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
```

#### `helm-chart/templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hextris
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: hextris
  template:
    metadata:
      labels:
        app: hextris
    spec:
      containers:
        - name: hextris
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
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
  name: hextris
spec:
  selector:
    app: hextris
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
```

#### `helm-chart/templates/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hextris
spec:
  rules:
    - host: hextris.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hextris
                port:
                  number: 80
```

---

### Terraform

#### `terraform/main.tf`

```hcl
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "hextris" {
  metadata {
    name = "hextris"
  }
}
```

---

### Jenkins

#### `jenkins/Jenkinsfile`

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
"""
        }
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t israa/hextris:latest .'
            }
        }
        stage('Deploy with Helm') {
            steps {
                sh 'helm upgrade --install hextris ./helm-chart --namespace hextris --create-namespace'
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

