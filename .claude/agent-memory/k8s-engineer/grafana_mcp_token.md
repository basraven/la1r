---
name: Grafana MCP server token generation
description: How to create a Grafana service account token for the MCP server when Grafana uses anonymous admin access
type: reference
---

Grafana MCP server (grafana/mcp-grafana:latest) authenticates via GRAFANA_SERVICE_ACCOUNT_TOKEN env var.

When Grafana uses anonymous admin mode (GF_AUTH_ANONYMOUS_ENABLED=true, GF_AUTH_ANONYMOUS_ORG_ROLE=Admin, GF_AUTH_BASIC_ENABLED=false), you can create a service account token via the local Grafana API without any credentials:

1. Exec into the Grafana pod: kubectl exec deploy/grafana -n monitoring -- curl -s -X POST -H 'Content-Type: application/json' -d '{"name":"grafana-mcp", "role":"Admin"}' http://localhost:3000/api/serviceaccounts
2. Create token: curl -s -X POST -H 'Content-Type: application/json' -d '{"name":"grafana-mcp-token"}' http://localhost:3000/api/serviceaccounts/<id>/tokens
3. Store the returned `key` value in the grafana-mcp-secret Secret manifest

Why: Grafana's anonymous admin access allows creating service accounts without authentication, which is the only way to get a token when basic auth is disabled.
How to apply: Use when deploying grafana-mcp alongside a Grafana instance configured for anonymous admin access. The token is created once and stored in the Secret manifest.
