FROM alpine:3.18

# Install dependencies: curl, bash, git, openjdk11 (for Jenkins agent)
RUN apk add --no-cache curl bash git openjdk11

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl -LO https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz \
    && tar -zxvf helm-v3.14.0-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64* helm-v3.14.0-linux-amd64.tar.gz

# --- ADD TERRAFORM INSTALLATION ---
RUN apk add --no-cache unzip \
    && curl -LO https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip \
    && unzip terraform_1.8.5_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_1.8.5_linux_amd64.zip

# Default command (Jenkins agent requires this)
CMD ["cat"]
