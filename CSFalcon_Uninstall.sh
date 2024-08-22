#!/bin/bash

# Define constants
client_id=""
client_secret=""
BASE_URL="https://api.us-2.crowdstrike.com/"

# Echo the variable agentID
echo "DeviceID:$agentID"

token=$(curl -X POST "https://api.us-2.crowdstrike.com/oauth2/token" -H  "accept: application/json" -H  "Content-Type: application/x-www-form-urlencoded" -d "client_id=$client_id&client_secret=$client_secret")

echo Token:$token

bearertoken=$(echo "$token" | awk -F'"access_token": "' '{gsub(/"/,"",$2); split($2,a,","); gsub(/,/,"",a[1]); print a[1]}')

authtoken=$(echo "$bearertoken" | tr -d '\n')

echo Bearer:$authtoken

# Pull agentID from the local machine (DeviceID, SensorID, and AgentID are all the same value)
agentID=$(/Applications/Falcon.app/Contents/Resources/falconctl stats -p | awk -F': ' '/agentID/{print;getline;print;}' | awk '{print tolower($0)}' | sed -e 's/-//g' | grep -oE '[a-f0-9]{32}')

# Echo the variable agentID
echo DeviceID:$agentID

# Make the API call to retrieve the uninstall token
response=$(curl --location 'https://api.us-2.crowdstrike.com/policy/combined/reveal-uninstall-token/v1' --verbose \
--header 'Content-Type: text/plain' \
--header "Authorization: Bearer $authtoken" \
--data "{
	\"audit_message\": \"string\",
	\"device_id\": \"$agentID\"
}")

echo $response

# Extract the uninstall_token value from the response using jq (assuming jq is installed)
Uninstall_token=$(echo $response | awk -F'"' '/"uninstall_token":/{print $20}')

echo Maintanace Token:$Uninstall_token

# Check if main_token is not empty
if [ -z "$Uninstall_token" ]; then
	echo "Failed to extract uninstall_token"
	exit 1
fi

# Invalidate access to the bearer token

b64creds=$( printf "$client_id:$client_secret" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

revoketoken=$(curl -X POST "https://api.us-2.crowdstrike.com/oauth2/revoke" -H  "accept: application/json" -H  "Content-Type: application/x-www-form-urlencoded" -H "authorization: Basic ${b64creds}" -d "token=$authtoken")

echo Revoke Token:$revoketoken

#Execute the uninstall using the acquired maintenance-token
expect <<- DONE
spawn /Applications/Falcon.app/Contents/Resources/falconctl uninstall --maintenance-token
expect "Falcon Maintenance Token:"
send -- "$Uninstall_token"
send -- "\r"
expect eof
DONE

wait 5

#Trigger the reinstall policy
sudo jamf policy -event installFalconSensor