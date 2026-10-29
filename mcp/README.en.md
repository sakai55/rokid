# mcp/ — MCP Registry for the Rokid Project

[中文](README.md) | English | [日本語](README.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

This directory is the registry for the Model Context Protocol servers this project actually uses: what each one is for and how it connects. Register every MCP as it comes into use — don't let them scatter across per-machine local configs.

## In Use

| MCP | Purpose | How it connects | Status |
|---|---|---|---|
| GitHub official MCP server | Repo read/write (files, branches, commit lookups) | GitHub connector (OAuth, account `sakai55`) | In use (read-only queries and text-file work) |

> Note: day-to-day GitHub work — binary .aix / PNG files, branch cleanup, all of it — goes through the **terminal `gh` / `git`** as the standard route (signed in as sakai55; see "Maintenance Conventions" in the root README). The GitHub MCP stays available as a connector capability and is a good fit for quick read-only lookups. Both operate on the same repo, `sakai55/rokid` — just keep the provenance of a commit straight.

## Planned / Placeholder

| MCP | Intended purpose | Status |
|---|---|---|
| (To be built) AIUI Docs MCP | Turn the official AIUI documentation (API contracts, events, components) into a locally searchable MCP, so capability boundaries can be checked while developing each Agent | Not built; for now, use the references in `skills/aiui-dev` |

## Adding an MCP

1. Create a `<name>/` subdirectory here and give that MCP its own `README.md`: the server's provenance (official repo / package name), how to start it, where the credentials it needs live (**storage location only** — e.g. Secure Vault, an environment variable name — **never the credential values**), the tools it exposes, and typical usage.
2. Add a row to the table above.
3. If credentials have to be entered, use the Secure Vault secure-entry flow — never chat, never the repo.
