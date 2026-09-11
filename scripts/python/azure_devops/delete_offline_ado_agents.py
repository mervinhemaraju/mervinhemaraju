#!/usr/bin/env python3
"""Delete offline agents from an Azure DevOps self-hosted agent pool.

Stale one-shot agent registrations (e.g. from replaced/preempted VMs) pile
up as "offline" entries that never get cleaned up automatically. This
removes them so the pool's Agents tab reflects reality.

Usage:
    AZURE_DEVOPS_EXT_PAT=*** python delete_offline_ado_agents.py [--pool NAME] [--dry-run]
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import TypedDict

import requests
import structlog

ORGANIZATION = "duokeych"
DEFAULT_POOL_NAME = "dke-prod-gcp-agent"
API_VERSION = "7.1"
BASE_URL = f"https://dev.azure.com/{ORGANIZATION}/_apis/distributedtask/pools"
REQUEST_TIMEOUT_SECONDS = 30

log = structlog.get_logger()


class MissingPatError(Exception):
    """Raised when AZURE_DEVOPS_EXT_PAT is not set."""


class PoolNotFoundError(Exception):
    """Raised when the target agent pool cannot be found in the organization."""


class Agent(TypedDict):
    id: int
    name: str
    status: str
    enabled: bool


def get_pat() -> str:
    pat = os.environ.get("AZURE_DEVOPS_EXT_PAT")
    if not pat:
        raise MissingPatError("AZURE_DEVOPS_EXT_PAT environment variable is not set.")
    return pat


def get_pool_id(session: requests.Session, pool_name: str) -> int:
    response = session.get(
        BASE_URL,
        params={"poolName": pool_name, "api-version": API_VERSION},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    pools = response.json()["value"]
    if not pools:
        raise PoolNotFoundError(f"No agent pool named {pool_name!r} found in org {ORGANIZATION!r}.")
    return int(pools[0]["id"])


def list_agents(session: requests.Session, pool_id: int) -> list[Agent]:
    response = session.get(
        f"{BASE_URL}/{pool_id}/agents",
        params={"api-version": API_VERSION},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return response.json()["value"]


def delete_agent(session: requests.Session, pool_id: int, agent: Agent) -> None:
    response = session.delete(
        f"{BASE_URL}/{pool_id}/agents/{agent['id']}",
        params={"api-version": API_VERSION},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    log.info("agent_deleted", agent_id=agent["id"], agent_name=agent["name"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pool", default=DEFAULT_POOL_NAME, help="Agent pool name.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List what would be deleted without deleting anything.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    pat = get_pat()

    session = requests.Session()
    session.auth = ("", pat)

    pool_id = get_pool_id(session, args.pool)
    agents = list_agents(session, pool_id)
    offline_agents = [agent for agent in agents if agent["status"] == "offline"]

    log.info(
        "offline_agents_found",
        pool=args.pool,
        offline=len(offline_agents),
        total=len(agents),
        dry_run=args.dry_run,
    )

    for agent in offline_agents:
        if args.dry_run:
            log.info("would_delete", agent_id=agent["id"], agent_name=agent["name"])
            continue
        delete_agent(session, pool_id, agent)

    log.info("done", deleted=0 if args.dry_run else len(offline_agents))
    return 0


if __name__ == "__main__":
    sys.exit(main())
