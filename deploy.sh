# deploy.sh
#!/bin/bash
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
  echo "Please set AWS_ACCOUNT_ID and AWS_REGION environment variables."
  exit 1
fi
envsubst < kubernetes/deployment.yaml | kubectl apply -f -
