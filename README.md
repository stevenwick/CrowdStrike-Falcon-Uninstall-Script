If you have ever tried to uninstall a Crowdstrike Falcon Agent with tamperproof protection enabled, you have probably realized it's not user-friendly. Having to pull the maintenance token from the web console, and then using it to confirm the uninstallation locally on each device is a tedious process. When you spend 5-10 mins removing one computer from the console it makes you question if there is a better way.

This script will perform the following logic to automate the uninstall process

- Pull Bearer Token from Crowdstrike’s API
- Pull agentID from local machine
- Make the API call to retrieve the uninstall token
- Invalidate access to the bearer token
- Execute the uninstall using the acquired maintenance-token
