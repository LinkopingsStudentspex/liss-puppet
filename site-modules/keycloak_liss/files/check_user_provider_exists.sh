if /opt/keycloak/bin/kcadm-wrapper.sh get components -r liss -q name=batadas-user-provider | grep -q '^\[ \]$'; then
  exit 0
else
  exit 1
fi
