#!/usr/bin/env sh
set -e

# Create subscription for AgrifarmRobotHouseSnapshot to QuantumLeap
curl -L -X POST 'http://nginx/api/orion/ngsi-ld/v1/subscriptions/' \
-H 'Content-Type: application/ld+json' \
-H 'NGSILD-Tenant: agri_farm_robot_house' \
--data-raw '{
  "description": "Notify me of all changes AgrifarmRobotHouseSnapshot",
  "type": "Subscription",
  "entities": [{"type": "AgrifarmRobotHouseSnapshot"}],
  "watchedAttributes": ["systemTimestamp"],
  "notification": {
    "attributes": ["systemTimestamp", "robot", "house", "analysis"],
    "endpoint": {
      "uri": "http://quantumleap:8668/v2/notify",
      "accept": "application/json",
       "receiverInfo": [
                    { "key": "Fiware-TimeIndex-Attribute", "value": "systemTimestamp" }
       ]
    }
  },
    "@context": [
    "https://smart-data-models.github.io/dataModel.Device/context.jsonld",
    "https://smart-data-models.github.io/dataModel.Environment/context.jsonld",
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context-v1.8.jsonld"
  ]
 }'

echo "Subscription for AgrifarmRobotHouseSnapshot created."