#!/bin/bash

# Get ingress controller IP
IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

# Exit if no IP or pending
if [ -z "$IP" ] || [ "$IP" == "<pending>" ]; then
    # echo "No ingress controller IP found"
    exit 0
fi

# Get all ingress hosts
HOSTS=$(kubectl get ingress -A -o jsonpath='{range .items[*].spec.rules[*]}{.host}{"\n"}{end}' | grep -v '^$' | sort -u)

if [ -z "$HOSTS" ]; then
    # echo "No ingress hosts found"
    exit 0
fi

# Remove existing Devenv section and update hosts file
sudo sed -i '' '/# Added by Devenv/,/# End of section/d' /etc/hosts

# Add new section
{
    echo "# Added by Devenv"
    echo "$HOSTS" | while read -r HOST; do
        echo "$IP $HOST"
    done
    echo "# End of section"
} | sudo tee -a /etc/hosts > /dev/null

# echo "Updated /etc/hosts with $IP"
