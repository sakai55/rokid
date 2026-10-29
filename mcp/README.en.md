# mcp/ — MCP Registry for the Rokid Project

[中文](README.md) | English | [日本語](README.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

A registry directory for Model Context Protocol servers and connection methods: the MCPs actually in use in this project,
their purposes, and how to connect to them are all recorded here. Register each new one as it is added, to avoid scattering them across local configurations on individual machines.

## In Use

| MCP | Purpose | Connection Method | Status |
|---|---|---|---|
| GitHub Official MCP Server | Repository read/write (files, branches, commit queries) | GitHub connector (OAuth, account `sakai55`) | In use (read-only query and text-file scenarios) |

> Note: Daily GitHub operations (including binary .aix / PNG files, branch cleanup, etc.) now follow the **terminal `gh` / `git`**
> as the standard route (logged in as sakai55, see the root README's "Maintenance Conventions"); the GitHub MCP is retained as a connector capability,
> suited to quick read-only queries. Both operate on the same repository, `sakai55/rokid`; just do not confuse the source of a commit.

## Planned / Placeholder

| MCP | Intended Purpose | Status |
|---|---|---|
| (To be built) AIUI Docs MCP | Turn the official AIUI documentation (API contracts, events, components) into a locally searchable MCP, for checking capability boundaries when developing each Agent | Not built; at this stage, use the references in `skills/aiui-dev` instead |

## When Adding an MCP

1. Create a `<name>/` subdirectory in this directory and put that MCP's `README.md` in it: write clearly the server's source (official repository / package name),
   how to start it, and where the credentials it needs are **stored** (write only the storage location, e.g. Secure Vault / an environment variable name, **never write credential values**),
   along with the list of tools it exposes and typical usage.
2. Register one row in the table above.
3. If credentials need to be entered, go through the Secure Vault secure entry flow; do not put them in chat or in the repository.
