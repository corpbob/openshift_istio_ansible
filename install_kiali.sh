# URLS for Jaeger and Grafana
JAEGER_URL="http://tracing-istio-system.18.214.127.95.nip.io"
GRAFANA_URL="http://grafana-istio-system.18.214.127.95.nip.io"
VERSION_LABEL="v0.7.2"

# Installs Kiali's configmap
curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali-configmap.yaml | \
  VERSION_LABEL=${VERSION_LABEL} \
  JAEGER_URL=${JAEGER_URL}  \
  GRAFANA_URL=${GRAFANA_URL} envsubst | oc create -n istio-system -f -

# Installs Kiali's secrets
curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali-secrets.yaml | \
  VERSION_LABEL=${VERSION_LABEL} envsubst | oc create -n istio-system -f -

# Deploys Kiali to the cluster
curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali.yaml | \
  VERSION_LABEL=${VERSION_LABEL}  \
  IMAGE_NAME=kiali/kiali \
  IMAGE_VERSION=${VERSION_LABEL}  \
  NAMESPACE=istio-system  \
  VERBOSE_MODE=4  \
  IMAGE_PULL_POLICY_TOKEN="imagePullPolicy: Always" envsubst | oc create -n istio-system -f -
