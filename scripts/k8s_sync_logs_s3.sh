#!/bin/bash

kubectl_cmd="/usr/bin/kubectl --kubeconfig /opt/devops/.kube/eks-app"

master_pod="app-master-0"
executor_pods=$(${kubectl_cmd} get pods | grep app-executor | awk '{print $1}')

pod_logs_dir="/opt/app/logs"
sync_logs_dir="/opt/backups/app_sync_logs"
mkdir -p ${sync_logs_dir}

${kubectl_cmd} exec -i ${master_pod} -- mkdir -p ${pod_logs_dir}
for i in $(${kubectl_cmd} exec -i ${master_pod} -- find ${pod_logs_dir} -type f -mtime -1); do
  echo "INFO: Copying ${i}..."
  i_basename=$(echo ${i} | sed "s|${pod_logs_dir}||g")
  ${kubectl_cmd} cp ${master_pod}:${i} ${sync_logs_dir}/${master_pod}${i_basename}
done

for j in ${executor_pods}; do
  ${kubectl_cmd} exec -i ${j} -- mkdir -p ${pod_logs_dir}
  for k in $(${kubectl_cmd} exec -i ${j} -- find ${pod_logs_dir} -type f -mmin -120); do
    echo "INFO: Copying ${k}..."
    k_basename=$(echo ${k} | sed "s|${pod_logs_dir}||g")
    ${kubectl_cmd} cp ${j}:${k} ${sync_logs_dir}/${j}${k_basename}
  done
done

/usr/local/bin/aws --profile app s3 sync --size-only ${sync_logs_dir}/ s3://heylinux-backups/app/app_sync_logs/
if [ $? -eq 0 ]; then
  find ${sync_logs_dir} -type f -mtime +7 -delete
fi
