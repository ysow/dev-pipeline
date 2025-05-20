#!/usr/bin/env python3
import os
import requests

SECRET_KEY = os.environ['SCW_SECRET_KEY']
ZONE = "fr-par-1"
GROUP_NAME = "demo-group"

headers = {
    "X-Auth-Token": SECRET_KEY,
    "Content-Type": "application/json"
}

# Fetch all instance groups
groups = requests.get(f"https://api.scaleway.com/autoscaling/v1alpha1/zones/{ZONE}/instance-groups", headers=headers).json()

group_id = None
for g in groups.get("groups", []):
    if g["name"] == GROUP_NAME:
        group_id = g["id"]
        break

if not group_id:
    raise Exception("Group not found")

# Fetch instances
instances = requests.get(f"https://api.scaleway.com/instance/v1/zones/{ZONE}/servers", headers=headers).json()
hosts = []

for inst in instances.get("servers", []):
    if group_id in (inst.get("tags") or []) and inst.get("public_ip"):
        hosts.append(inst["public_ip"]["address"])

# Output Ansible inventory
print("[all]")
for ip in hosts:
    print(ip)
