#!/usr/bin/env sh
set -eu

#############################################
# 設定（環境変数で上書き可能）
#############################################
BROKER_BASE_URL="${BROKER_BASE_URL:-http://nginx/api/orion/ngsi-ld/v1}"
TENANT="${TENANT:-agri_farm_robot_house}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-urn:ngsi-ld:Subscription:AgrifarmRobotHouseSnapshotToQL}"
NOTIFY_URI="${NOTIFY_URI:-http://quantumleap:8668/v2/notify}"

# 共通ヘッダ
COMMON_HEADERS="-H Content-Type:application/ld+json -H NGSILD-Tenant:${TENANT}"

#############################################
# 起動待ち（ブローカー疎通確認）
#############################################
echo "Waiting for Orion-LD at ${BROKER_BASE_URL} ..."
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${BROKER_BASE_URL}/subscriptions/")
  if [ "$code" != "000" ] && [ "$code" -ne 502 ] && [ "$code" -ne 503 ] && [ "$code" -ne 504 ]; then
    echo "Orion-LD is reachable (HTTP $code)."
    break
  fi
  sleep 2
done

#############################################
# 1) 既存確認（GET /subscriptions/{id}）
#############################################
echo "Checking if subscription exists: ${SUBSCRIPTION_ID}"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "NGSILD-Tenant: ${TENANT}" \
  "${BROKER_BASE_URL}/subscriptions/${SUBSCRIPTION_ID}")

#############################################
# 2) 新規作成（無ければPOST）
#############################################
if [ "$STATUS" -eq 404 ]; then
  echo "Not found. Creating subscription ${SUBSCRIPTION_ID} ..."
  curl -sS -L -X POST "${BROKER_BASE_URL}/subscriptions/" \
    $COMMON_HEADERS \
    --data-raw "{
      \"id\": \"${SUBSCRIPTION_ID}\",
      \"description\": \"Notify me of all changes AgrifarmRobotHouseSnapshot\",
      \"type\": \"Subscription\",
      \"entities\": [{\"type\": \"AgrifarmRobotHouseSnapshot\"}],
      \"watchedAttributes\": [\"systemTimestamp\"],
      \"notification\": {
        \"attributes\": [\"systemTimestamp\", \"analysis\"],
        \"endpoint\": {
          \"uri\": \"${NOTIFY_URI}\",
          \"accept\": \"application/json\",
          \"receiverInfo\": [
            { \"key\": \"Fiware-TimeIndex-Attribute\", \"value\": \"systemTimestamp\" }
          ]
        }
      },
      \"@context\": [
        \"https://smart-data-models.github.io/dataModel.Device/context.jsonld\",
        \"https://smart-data-models.github.io/dataModel.Environment/context.jsonld\",
        \"https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context-v1.8.jsonld\",
        \"http://nginx/ld/contexts/context.jsonld\"
      ]
    }"
  echo
  echo "Subscription created."
#############################################
# 3) 既存
#############################################
elif [ "$STATUS" -eq 200 ]; then
  echo "Already exists."
#############################################
# 4) 想定外のステータス
#############################################
else
  echo "Unexpected response when checking subscription: HTTP $STATUS" >&2
  exit 1
fi

echo "Done."