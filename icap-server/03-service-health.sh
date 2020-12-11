#!/usr/bin/env bash
  
# Restarts a pod
restart_pod() {
  kubectl -n icap-adaptation delete pods/$1
}

for ((;;))
do
   # Listing all unhealthy pods
   kubectl get pods --no-headers -n icap-adaptation | grep -Ev 'Running|Completed|ContainerCreating' |
   while read -r line
   do
       arr=($line)
       echo "Pod ${arr[0]} is reporting unhealthy status : ${arr[2]}"
       echo "Restarting the pod...Will check again in 30 sec...Make sure this server has access to the Internet"
       restart_pod ${arr[0]}
   done

   pod_unhealthy=`kubectl get pods --no-headers -n icap-adaptation | grep -Ev 'Running|Completed'`
   if [[ -z "$pod_unhealthy" ]]
   then
       echo "All pods are up and running"
       break
   else
       echo "sleeping"
       sleep 30
   fi

done
