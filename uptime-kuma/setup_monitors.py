#!/usr/bin/env python3
"""
Uptime Kuma monitor + status page bootstrap for homelab.
Run after creating your admin account in the web UI.

Usage:
    python3 setup_monitors.py <username> <password>

Reads monitor/status-page config from monitors.json (gitignored — machine-specific).
Copy monitors.json.example to monitors.json and edit before first run.
"""

import json
import sys
from pathlib import Path

from uptime_kuma_api import MonitorType, UptimeKumaApi

KUMA_URL = "http://localhost:3001"

CONFIG_PATH = Path(__file__).parent / "monitors.json"

MONITOR_TYPES = {
    "ping": MonitorType.PING,
    "http": MonitorType.HTTP,
}


def load_config():
    if not CONFIG_PATH.exists():
        print(f"Missing {CONFIG_PATH}")
        print(f"Copy {CONFIG_PATH.with_suffix('.json.example')} to {CONFIG_PATH.name} and edit it first.")
        sys.exit(1)

    with open(CONFIG_PATH) as f:
        config = json.load(f)

    monitors = []
    for m in config["monitors"]:
        m = dict(m)
        m["type"] = MONITOR_TYPES[m["type"]]
        monitors.append(m)

    return monitors, config["status_page"]


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 setup_monitors.py <username> <password>")
        sys.exit(1)

    username, password = sys.argv[1], sys.argv[2]
    monitors, status_page = load_config()

    print(f"Connecting to {KUMA_URL}...")
    api = UptimeKumaApi(KUMA_URL)

    print(f"Logging in as {username}...")
    api.login(username, password)

    # Upsert monitors — update if exists, create if new
    existing = {mon["name"]: mon["id"] for mon in api.get_monitors()}
    monitor_ids = []
    for m in monitors:
        if m["name"] in existing:
            mid = existing[m["name"]]
            print(f"  Updating (exists): {m['name']} -> ID {mid}")
            api.edit_monitor(mid, **m)
            monitor_ids.append(mid)
        else:
            print(f"  Adding monitor: {m['name']}")
            result = api.add_monitor(**m)
            monitor_ids.append(result["monitorID"])
            print(f"    -> ID {result['monitorID']}")

    # Create status page if it doesn't exist yet
    print("\nCreating status page...")
    existing_pages = {p["slug"] for p in api.get_status_pages()}
    if status_page["slug"] not in existing_pages:
        api.add_status_page(slug=status_page["slug"], title=status_page["title"])
    else:
        print(f"  Status page '{status_page['slug']}' already exists, updating...")

    # Add all monitors to status page
    print("Adding monitors to status page...")
    public_group_list = [{
        "name": "Homelab",
        "weight": 1,
        "monitorList": [{"id": mid} for mid in monitor_ids],
    }]
    api.save_status_page(
        slug=status_page["slug"],
        title=status_page["title"],
        description=status_page["description"],
        theme=status_page["theme"],
        published=True,
        showTags=False,
        domainNameList=[],
        customCSS="",
        footerText="",
        showPoweredBy=False,
        publicGroupList=public_group_list,
    )

    print("\nDone.")
    print(f"  Monitors: {KUMA_URL}/dashboard")
    print(f"  Status page: {KUMA_URL}/status/{status_page['slug']}")

    api.disconnect()


if __name__ == "__main__":
    main()
