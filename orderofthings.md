# ASP.NET Core Web API Sample Assignment

## Steps

1. **Read the assignment**
2. **Fork the Repository**

   - Fork the [ASPNETCore-WebAPI-Sample](https://github.com/FabianGosebrink/ASPNETCore-WebAPI-Sample) repo to my GitHub account: [Forked Repository](https://github.com/dean3772/ASPNETCore-WebAPI-Sample-assignment/tree/main)
3. **Create Docker Hub Repository**

   - Created a Docker Hub repository: [Docker Hub Repository](https://hub.docker.com/repository/docker/dean377/project2/general)
4. **Connect to EC2**

   - On my machine, in `~/.ssh`, created a file named `as.pem` for the SSH session to the provided EC2, pasted the SSH private key, and set the file permissions to `chmod 400`.
   - Used the command `ssh -i ~/.ssh/as.pem ubuntu@51.17.21.49` to connect to the EC2 instance.
5. **Install Software on EC2**

   - Installed the following software on the EC2 instance:
     - Docker (and added the current user to the Docker group)
     - Minikube
     - Kubectl
     - Helm
     - ArgoCD
     - K6
6. **Start Minikube**

   - Started Minikube using the command: `minikube start`
7. **Test the Forked .NET Repo Locally**

   - Installed the .NET SDK using the command: `sudo apt-get install -y dotnet-sdk-7.0`
   - Tested the application locally with `dotnet build` and `dotnet run`, visiting `http://localhost:7124/swagger/index.html`
8. **Create Dockerfile for .NET App**

   - Referenced an example Dockerfile: [Example Dockerfile](https://github.com/Jaydeep-007/NET-Core-Web-API-Docker-Demo/blob/master/NET-Core-Web-API-Docker-Demo/Dockerfile)
   - Created and built the Docker image:
     ```sh
     docker build -t dotnet1 .
     docker tag dotnet1 dean377/project2:v1
     docker login -u dean377
     docker push dean377/project2:v1
     docker pull dean377/project2:v1
     docker run -d -p 8080:80 docker.io/dean377/project2:v1
     ```
   - Added the following environment variables to the Dockerfile to avoid needing a secure connection for testing:
     ```
     ENV ASPNETCORE_URLS http://*:80
     ENV ASPNETCORE_ENVIRONMENT=Development
     ```
9. **Test the .NET App Locally Using Docker Image**

   - Tested the .NET application locally using the local Docker image.
10. **Publish the Docker Image to Docker Hub**

- Published the Docker image to Docker Hub: [Published Docker Image](https://hub.docker.com/repository/docker/dean377/project2/general)

11. **Deploy the App Using Helm in the Minikube Cluster on EC2**

    - Created a Helm chart for the app:
      ```sh
      helm create myapp
      ```
    - Updated the values of the Helm chart `values.yaml` file to include the Docker image URL and tag:
      ```yaml
      image:
        repository: dean377/project2
        pullPolicy: IfNotPresent
        tag: v3
      ```
    - Updated the values of the Helm chart to have 2 replicas of the app:
      ```yaml
      replicaCount: 2
      ```
    - Added environment variables to the `values.yaml` of the app, similar to the Dockerfile, to bypass the use of secure connections:
      ```yaml
      env:
        - name: ASPNETCORE_URLS
          value: "http://*:80"
        - name: ASPNETCORE_ENVIRONMENT
          value: "Development"
      ```
    - Set Horizontal Pod Autoscaler (HPA) from 2 to 10 pods if any pod uses more than 80% CPU:
      ```yaml
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 10
        targetCPUUtilizationPercentage: 80
      ```
    - Set health check in the URL:
      ```yaml
      healthCheckPath: /swagger/index.html
      ```
    - Port forwarded the Helm chart app service:
      ```sh
      kubectl get pods
      kubectl port-forward --address 0.0.0.0 myapp-6f895cd86c-kq6n6 8080:80
      kubectl port-forward --address 0.0.0.0 myapp-574b968cb8-qmm47 8080:80
      ```
    - Visited the address to test:
      [http://51.17.21.49:8080/swagger/index.html](http://51.17.21.49:8080/swagger/index.html)
12. **Install ArgoCD in the Minikube Cluster**

    - Created a namespace and installed ArgoCD:

      ```sh
      kubectl create namespace argocd
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      ```
    - Installed ArgoCD CLI:
      [ArgoCD CLI Installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
    - Validated ArgoCD installation:

      ```sh
      kubectl get all -n argocd
      ```
    - Created ArgoCD app YAML file as per the example:
      [Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)

      - Placed it in `repo-root/argocd/argocd-app.yaml`
      - Annotated with the Docker image URL to use ArgoCD image updater:
        [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/en/stable/install/installation/)
    - Edited the image tag of the Helm chart of the app in the `values.yaml` to test ArgoCD.
    - Exposed the ArgoCD UI using port forward:

      ```sh
      kubectl get pods -n argocd
      kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8084:443
      ```
    - Logged in to the ArgoCD dashboard using the username `admin` and password retrieved from the secret:

      ```sh
      argocd admin initial-password -n argocd
      # or
      kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
      # Password: xrjq-hxr9RAwi2Ak
      argocd login localhost:8084 --username admin --password xrjq-hxr9RAwi2Ak --insecure
      ```
13. **K6 Load Test**

    - Installed K6 locally following the instructions: [Install K6](https://grafana.com/docs/k6/latest/set-up/install-k6/?pg=get&plcmt=selfmanaged-box4-cta1)
    - Enabled Minikube metrics server:

      ```sh
      minikube addons enable metrics-server
      ```
    - Monitored the Horizontal Pod Autoscaler (HPA) and deployment:

      ```sh
      kubectl get hpa --watch
      kubectl get deployment myapp -o wide --watch
      ```
    - Created `load-test.js` script:

      ```javascript
      import http from 'k6/http';
      import { check, sleep } from 'k6';

      export let options = {
        stages: [
          { duration: '30s', target: 50 }, // simulate ramp-up of traffic from 1 to 50 users over 30 seconds
          { duration: '1m30s', target: 50 }, // stay at 50 users for 1 minute 30 seconds
          { duration: '20s', target: 0 }, // ramp-down to 0 users
        ],
      };

      export default function () {
        let res = http.get('http://localhost:8080/swagger/index.html');
        check(res, { 'status was 200': (r) => r.status == 200 });
        sleep(1);
      }
      ```
    - Ran the load test using K6 after port forwarding the pod:

      ```sh
      kubectl port-forward --address 0.0.0.0 myapp-574b968cb8-qmm47 8080:80
      k6 run load-test.js
      ```
    - **Q & A:**

      **How would you implement monitoring for the environment?**

      - To implement monitoring for the environment, I would use Prometheus and Grafana. They can be installed using the Helm Chart called `kube-prometheus-stack`.

      **Prometheus:**

      - **Role:** Prometheus is a monitoring and alerting toolkit. It collects metrics from various servers and services and stores them efficiently.
      - **How it works:** Prometheus scrapes metrics from different sources over HTTP. It then stores this data in its internal time-series database.

      **Grafana:**

      - **Role:** Grafana is a visualization and analytics platform. It allows you to create interactive dashboards that display the metrics collected by Prometheus.
      - **How it works:** Grafana connects to Prometheus as a data source and can pull metrics from it to display on dashboards. You can create graphs and charts to visually represent the collected data.

      **Helm:**

      - **Role:** Helm is a package manager for Kubernetes. It simplifies the installation, update, and removal of applications in a Kubernetes environment.
      - **How it works:** Using Helm, you can install the Helm Chart for Prometheus and Grafana with a single command, which sets up all the necessary components and configurations automatically.

      **Installation Steps Using Helm:**

      - Add the Helm Repository:

        ```sh
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        ```
      - Install the Helm Chart:

        ```sh
        helm install prometheus-grafana prometheus-community/kube-prometheus-stack
        ```
      - **Access Grafana:**

        - After installation, you can access the Grafana interface through a web browser using the appropriate port. By default, you can use Port Forwarding to access Grafana.
          ```sh
          kubectl port-forward svc/prometheus-grafana 3000:80
          ```
      - **Setting Up Dashboards:**

        - Once logged into Grafana, you can set up dashboards to display the metrics collected by Prometheus. Grafana provides pre-configured templates that you can download and customize.

      **How would you run background job using argo-workflows ?**
    - Argo Workflows is a tool for scheduling and managing complex tasks in a Kubernetes environment.
      It allows you to run jobs on a schedule or based on certain triggers and build complex workflows that can include parallel steps, dependent steps, and more.
    - Argo Workflows uses Kubernetes Custom Resource Definitions (CRDs) to define and manage workflows.
      Each workflow is defined as a resource in the Kubernetes cluster and consists of a series of steps that can run in parallel or sequentially. Each step can be a separate job like a Docker container performing a specific task.
      A workflow consists of a specification that contains an entrypoint and a list of templates.
      A workflow can model complex logic using directed acyclic graphs (DAGs) or steps to capture the dependencies or sequences between the templates.

    How to Install Argo Workflows:

    ```
    kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.7/install.yaml

    ```

    To run a background job using Argo Workflows, I would create a YAML file defining the background job as a container template.
    For a simple job that prints "hello world," it can be a container type template. Here is an example:

```
"
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: my-background-job-
spec:
  entrypoint: background-job
  templates:
  - name: background-job
    container:
      image: alpine:latest
      command: [echo]
      args: ["Running background job"]
"
```


than we would save and apply the yaml as a job:

```
"kubectl create -f background-job.yaml"
```

* in argo workflowa there are 6 different execution patterns controlled by templates
  workflow templates types are:
  DAG: Define complex workflows where tasks depend on the completion of other tasks.
  Container: Run a specific task in a container.
  Suspend: Pause the execution of a workflow for a specified duration or until manually resumed.
  Resource: Manage Kubernetes resources within workflows, such as creating or deleting Kubernetes objects.
  Step: Define tasks as a series of steps, with steps running sequentially or in parallel.
  Script: Run a script as a task within a workflow, defined inline and executed in a container.

**How would i manage different enviroment variables in in an organization with several enviroments for a singel system:**


1. create .env files containing the env a spesific enviroment demends
   2.use cicd to inject those env in a specific enviroment
   3.use secret managment tools
   4.use configuration managment tools like ansible

for local development we can use .env files

while using helm in each enviroment, we can have different values.yaml file for each enviroment

values-dev.yaml
values-test.yaml
values-prod.yaml

for each enviroment we use different branch, each with it's cicd , and when helm deploy \ upgrade a chart,
it can use a specific values file for each enviroment.


```
"
helm install example-qa sample-app -n qa -f values-qa.yaml
helm install example-staging sample-app -n staging -f values-staging.yaml
helm install example-prod sample-app -n production -f values-prod.yaml
"
```
