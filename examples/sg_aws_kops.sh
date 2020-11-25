#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OPTIND=1
assumeyes=0
create=0
delete=0

check_ret() {
    local status=$?
    if [ $status -ne 0 ]; then
         echo "ERR - The command $1 failed with status $status" 1>&2
         exit $status
    fi
}

check_cmd() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    echo "ERR - $1 not found" 1>&2
    echo "You need to have aws-cli, kops, helm and kubectl installed"
    echo "On macOS just run 'brew install awscli kops kubectl kubernetes-helm'"
    echo "aws-cli needs to be configured with appropriate permissions to setup a kubernetes cluster"
    exit 1
  fi
}

function show_help() {
    echo "sg_aws_kops.sh [-y] [-c|-d <clustername>]"
    echo "  -h show help"
    echo "  -y non-interactive"
    echo "  -c create a new cluster (min 6 chars, only [a-z])"
    echo "  -d delete a cluster"
    exit 1
}

NAME=""

while getopts "h?yc:d:" opt; do
    case "$opt" in
    h|\?)
        show_help
        ;;
    y)  assumeyes=1
        ;;
    c)  create=1
        NAME="$OPTARG"
        ;;
    d)  delete=1
        NAME="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$create" == 1 ] && [ "$delete" == 1 ];then
    echo "Specifiy only -c or -d" >&2
    show_help
fi

if [ "$create" == 0 ] && [ "$delete" == 0 ];then
    echo "Specifiy -c or -d" >&2
    show_help
fi

if [ ${#NAME} -le 5 ]; then
    echo "Invalid clustername: $NAME (must be at least 6 chars long)" >&2
    show_help
fi

check_cmd aws
check_cmd kops
check_cmd helm
check_cmd kubectl

CLUSTERNAME="$NAME.sg.k8s.local"
BUCKET="$CLUSTERNAME.kopsstate"
KOPS_STATE_STORE="s3://$BUCKET"
LOGFILE="$CLUSTERNAME.log"
REGION="$(aws configure get region)"
AWS_KEY="$(aws configure list | grep access_key)"

if [ "$create" == 1 ]; then
    echo "WARNING: This script will create AWS resources like EC2 instances, S3 buckets and ebs volumes for which you will be charged"
    echo "         Both Elasticsearch and Kibana will be exposed to the internet"
    echo "         Make sure aws-cli is configured to use the correct account, access_key ($AWS_KEY) and default region ($REGION)"
fi

if [ "$assumeyes" == 0 ]; then
  
   QUESTION="Create cluster $CLUSTERNAME?"

   if [ "$delete" == 1 ]; then
       QUESTION="Delete cluster $CLUSTERNAME?"
   fi

	read -r -p "$QUESTION [y/N] " response
	case "$response" in
	    [yY][eE][sS]|[yY]) 
	        ;;
	    *)
	        exit 0
	        ;;
	esac
fi

if [ "$delete" == 1 ]; then
    echo "Delete kops k8s cluster $CLUSTERNAME with state in $KOPS_STATE_STORE"
    kops delete cluster --name="$CLUSTERNAME" --state="$KOPS_STATE_STORE" --yes
    check_ret "Cluster delete"
    exit 0
fi


#aws configure list
#kops version
#kubectl version --client=true
#helm version -c



echo "Create S3 bucket $BUCKET in $REGION to hold the kops state"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null  2>&1
aws s3api put-bucket-versioning --bucket "$BUCKET" --region "$REGION"  --versioning-configuration Status=Enabled > /dev/null  2>&1

echo "Create kops k8s cluster $CLUSTERNAME in $REGION"
kops create cluster $CLUSTERNAME \
  --state="$KOPS_STATE_STORE" \
  --zones="$REGION"a \
  --master-zones="$REGION"a \
  --master-size m5.large \
  --master-volume-size 10 \
  --node-size m5.large \
  --node-volume-size 10 \
  --node-count=2 \
  --master-count=1 \
  --yes
  
  #> /dev/null  2>&1
#check_ret "Cluster create"

echo "Wait until cluster $CLUSTERNAME is valid ... (may take a few minutes)"
until kops validate cluster --name="$CLUSTERNAME" --state="$KOPS_STATE_STORE" > /dev/null 2>&1; do sleep 15 ; done
echo "Cluster is ready!"

helm repo add sg-helm https://floragunncom.github.io/search-guard-helm > /dev/null  2>&1

echo "Install ElasticSearch/Kibana secured by Search Guard"

helm install sg-elk sg-helm \
  --version sgh-beta4 \
  --set data.storageClass=gp2  \
  --set master.storageClass=gp2 \
  --set data.replicas=1  \
  --set master.replicas=1 \
  --set client.replicas=1 \
  --set kibana.replicas=1 \
  --set common.serviceType=NodePort \
  --set kibana.serviceType=NodePort \
  --set common.ingressNginx.enabled=true \
  --set common.ingressNginx.ingressCertificates=self-signed \
  --set common.ingressNginx.ingressKibanaDomain=kibana.example.com \
  --set common.ingressNginx.ingressElasticsearchDomain=elasticsearch.example.com \
  --set common.do_not_fail_on_forbidden=true


check_ret "Helm install"

  # \
  #--set common.elkversion=6.6.2 \
  #--set common.sgversion=24.3 \
  #--set common.sgkibanaversion=18.3

echo "Wait for Ingress to start ..."

until kubectl get ing --namespace default sg-elk-sg-helm-ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' &> /dev/null; do sleep 15 ; done
#ES_URL=$(kubectl get svc --namespace default sg-elk-sg-helm-clients -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#KIBANA_URL=$(kubectl get svc --namespace default sg-elk-sg-helm -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#echo "Elasticsearch: https://$ES_URL:9200"
#echo "Kibana: https://$KIBANA_URL:5601"

sleep 30

INGRESS_HOST=$(kubectl get ing --namespace default sg-elk-sg-helm-ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'|cut -d. -f 1-5)
echo "You can use IP of $INGRESS_HOST to assign to kibana.example.com, elasticsearch.example.com in DNS"

echo "Install Dashboard"

#Previously used dashboard yaml is kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml #> /dev/null  2>&1


BASIC_PASS_CMD="kubectl config view -o=jsonpath='{.users[?(@.name=="\"$CLUSTERNAME-basic-auth\"")].user.password}'"
BASIC_PASS=$($BASIC_PASS_CMD | tr -d "'")
DASHBOARD_TOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') | grep "token: " | awk '{print $2}')
APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")
#DASHBOARD="$APISERVER/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview"

kubectl cluster-info
echo "To acess dashboard run: kubectl proxy"

echo "Kubernetes Dashboard URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
#echo "  Username: admin"
#echo "  Password: $BASIC_PASS"
echo "  Token: $DASHBOARD_TOKEN"


echo ""
echo "Done"

cat << EOF
To upgrade run a command similar to:


helm upgrade sg-elk sg-helm/sg-helm \\
  --version sgh-beta4 \\
  --set data.storageClass=gp2  \\
  --set master.storageClass=gp2 \\
  --set data.replicas=1  \\
  --set master.replicas=1 \\
  --set client.replicas=1 \\
  --set kibana.replicas=1 \\
  --set common.serviceType=NodePort \\
  --set kibana.serviceType=NodePort \\
  --set common.ingressNginx.enabled=true \\
  --set common.ingressNginx.ingressCertificates=self-signed \\
  --set common.ingressNginx.ingressKibanaDomain=kibana.example.com \\
  --set common.ingressNginx.ingressElasticsearchDomain=elasticsearch.example.com \\
  --set common.do_not_fail_on_forbidden=true
  --set common.elkversion="7.9.2" \\
  --set common.sgversion="46.0.0" \\
  --set common.sgkibanaversion="46.0.0"


(NB: For upgrade you need two times more resources in the cluster to keep old and starting new instances at the same time)
EOF

#\\
#  --set common.sg_enterprise_modules_enabled=false \\
#  --set common.do_not_fail_on_forbidden=true