#!/bin/bash

set -e
echo "in scripts autoscaling"

INSTANCE_ID="$1"
VOLUME_ID="$2"
# PRIVATE_NETWORK_ID="$3"
# PROJECT_ID="$4"
# LB_ID="$5"
# BACKEND_ID="$6"
ZONE="${SCW_DEFAULT_ZONE:-fr-par-1}"

echo "📸 Snapshot en creation"

# 1. Créer un snapshot à partir du volume root
SNAPSHOT_ID=$(curl -s -X POST "https://api.scaleway.com/instance/v1/zones/$ZONE/snapshots" \
  -H "X-Auth-Token: $SCW_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"volume_id\":\"$VOLUME_ID\",\"name\":\"demo-snapshot-$(date +%s)\"}" \
  | jq -r .snapshot.id)

echo "📸 Snapshot créé : $SNAPSHOT_ID"

# # 2. Créer une image personnalisée à partir du snapshot
# IMAGE_ID=$(curl -s -X POST "https://api.scaleway.com/instance/v1/zones/$ZONE/images" \
#   -H "X-Auth-Token: $SCW_SECRET_KEY" \
#   -H "Content-Type: application/json" \
#   -d "{\"root_volume\":{\"snapshot_id\":\"$SNAPSHOT_ID\"},\"name\":\"demo-image-$(date +%s)\",\"arch\":\"x86_64\"}" \
#   | jq -r .image.id)

# echo "🖼️ Image créée : $IMAGE_ID"

# # 3. Créer un server template (server metadata-based for automation)
# TEMPLATE_NAME="demo-template-$(date +%s)"

# # Optionnel : ici on saute l'étape server_template car Scaleway ne propose pas de template réutilisable comme GCP ou AWS,
# # on va utiliser directement l'image custom dans les futures instances.

# # 4. Créer un groupe de 2 instances avec l'image custom
# for i in 1 2; do
#   SERVER_ID=$(curl -s -X POST "https://api.scaleway.com/instance/v1/zones/$ZONE/servers" \
    # -H "X-Auth-Token: $SCW_SECRET_KEY" \
    # -H "Content-Type: application/json" \
    # -d "{
    #   \"name\": \"autoscaled-$i\",
    #   \"image\": \"$IMAGE_ID\",
    #   \"commercial_type\": \"PLAY2-NANO\",
    #   \"project_id\": \"$PROJECT_ID\",
    #   \"private_network\": {\"id\": \"$PRIVATE_NETWORK_ID\"},
    #   \"enable_ipv6\": false,
    #   \"tags\": [\"autoscaled\"]
    # }" | jq -r .server.id)

#   echo "🚀 Instance autoscalée $i créée : $SERVER_ID"

#   # Attacher au backend du Load Balancer
#   curl -s -X POST "https://api.scaleway.com/lb/v1/zones/$ZONE/backend-servers" \
    # -H "X-Auth-Token: $SCW_SECRET_KEY" \
    # -H "Content-Type: application/json" \
    # -d "{
    #   \"backend_id\": \"$BACKEND_ID\",
    #   \"ip\": null,
    #   \"server_id\": \"$SERVER_ID\"
    # }" > /dev/null

#   echo "🔗 Instance $i attachée au backend LB"
# done
