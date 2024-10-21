# **Tumor-Prediction with Deep Neural Networks**

This microservice will serve as a scalable classification tool for MRI images with the goal of determining the presence of a tumor using a deep neural network. Infrastructure is provisioned using terraform, which describes an eks cluster along with a vpc and its private and public subnets. Kubernetes manifest files are used to create deployments for our nodes, and service discovery is done through a nodeport service. Traffic entering through an AWS-managed application load balancer is routed to a flask application hosting the tumor-prediction microservice. 

<div align="center">
  <img src=".assets/mri-example.jpg" alt="Image won't load" />
</div>
