
K8S_MIN_VERSION=$1
K8S_MAX_VERSION=$2

if [ -z "$K8S_MIN_VERSION" ] || [ -z "$K8S_MAX_VERSION" ]; then
    echo "Usage: $0 <k8s_min_version> <k8s_max_version>"
    exit 1
fi

get_major(){
  echo $1 | cut -d. -f1
}

get_minor(){
  echo $1 | cut -d. -f2
}
get_patch() {
  echo $1 | cut -d. -f3  
}

get_all_releases() {
   local minor_version=$1 
   git -c 'versionsort.suffix=-' \
       ls-remote --exit-code --refs \
                 --sort='version:refname' --tags \
       https://github.com/kubernetes/kubernetes.git "*.${minor_version}.*" | \
       cut --delimiter='/' --fields=3 | \
       grep -v '-'
 }

get_max_patch_version() {
    local minor_version=$1
    get_all_releases $minor_version | sort -V | tail -n 1
}

min_minor_version=$(get_minor $K8S_MIN_VERSION)
max_minor_version=$(get_minor $K8S_MAX_VERSION)

for (( minor=min_minor_version; minor<=max_minor_version; minor++ ))
do
  version=$(get_max_patch_version $(get_minor $minor))

  echo "############################################"
  echo "$0 Creating the k8s env for $version"
  echo "############################################"
  ./prepare_minikube.sh $version
  echo "############################################" 
  echo "$0 Created the k8s env for $version"
  echo "############################################"
  # echo ""
  # echo ""
  # echo ""
  # echo "############################################" 
  # echo "$0 Running the test for ELK 7 for kubernetes $version"
  # echo "############################################"
  # ./run_tests_elk_7.sh  common.elkversion="7.17.18",common.sgversion="1.6.0-flx",common.sgkibanaversion="1.6.0-flx",common.sgctl_version="1.6.0"  false  
  # ./run_tests_elk_7.sh  common.elkversion="7.17.17",common.sgversion="1.4.1-flx",common.sgkibanaversion="1.4.1-flx",common.sgctl_version="1.4.0"  false
  # ./run_tests_elk_7.sh  common.elkversion="7.17.15",common.sgversion="1.4.0-flx",common.sgkibanaversion="1.4.0-flx",common.sgctl_version="1.4.0"  false 
  # ./run_tests_elk_7.sh  common.elkversion="7.17.14",common.sgversion="1.4.0-flx",common.sgkibanaversion="1.4.0-flx",common.sgctl_version="1.4.0"  false          
  # echo "############################################" 
  # echo "$0 Finished tests ELK 7 for kubernetes $version"
  # echo "############################################"
  # echo ""
  # echo ""
  # echo ""
  # echo "############################################" 
  # echo "$0 Running the test for ELK 8 for kubernetes $version"
  # echo "############################################"
  # ./run_tests.sh  common.elkversion="8.12.2",common.sgversion="2.0.0-flx",common.sgkibanaversion="2.0.0-flx",common.sgctl_version="2.0.0"  false
  # ./run_tests.sh  common.elkversion="8.11.4",common.sgversion="2.0.0-flx",common.sgkibanaversion="2.0.0-flx",common.sgctl_version="2.0.0"  false
  # ./run_tests.sh  common.elkversion="8.10.4",common.sgversion="2.0.0-flx",common.sgkibanaversion="2.0.0-flx",common.sgctl_version="2.0.0"  false
  # ./run_tests.sh  common.elkversion="8.9.2",common.sgversion="2.0.0-flx",common.sgkibanaversion="2.0.0-flx",common.sgctl_version="2.0.0"  false
  # ./run_tests.sh  common.elkversion="8.8.2",common.sgversion="2.0.0-flx",common.sgkibanaversion="2.0.0-flx",common.sgctl_version="2.0.0"  false

  echo ""
  echo ""
  echo ""
  echo "############################################" 
  echo "$0 Running the test for ELK 9 for kubernetes $version"
  echo "############################################"
  ./run_tests.sh  common.elkversion="9.0.1",common.sgversion="3.1.1-flx",common.sgkibanaversion="3.1.1-flx",common.sgctl_version="3.1.1"  false
  ./run_tests.sh  common.elkversion="9.0.2",common.sgversion="3.1.1-flx",common.sgkibanaversion="3.1.1-flx",common.sgctl_version="3.1.1"  false
  ./run_tests.sh  common.elkversion="9.0.3",common.sgversion="3.1.1-flx",common.sgkibanaversion="3.1.1-flx",common.sgctl_version="3.1.1"  false
      
  echo ""
  echo ""
  echo ""
  echo "############################################" 
  echo "$0 Finished tests ELK 8 for kubernetes $version"
  echo "############################################"  
done