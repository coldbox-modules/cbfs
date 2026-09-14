# CBFS Agent Instructions

## Project Overview

CBFS is a ColdBox module that provides a fluent abstraction over local, in-memory, and S3-backed file storage for CFML and BoxLang applications.

- Core module code lives in `models/`.
- Storage providers live in `models/providers/`.
- NIO visitors live in `models/nio/`.
- WireBox integration lives in `dsl/`.
- The integration test harness lives in `test-harness/`.
- The bundled `cbstreams` and `s3sdk` dependencies live in `modules/`.

A more specific `AGENTS.md` under `test-harness/testbox/` applies to work in that subtree.

## Compatibility

Preserve compatibility with the engines configured by this repository:

- BoxLang
- Adobe ColdFusion 2023 and 2025
- Lucee 6

Use cross-engine CFML for shared behavior. If a change is intentionally engine-specific, isolate it clearly and add coverage or guards for the other supported engines.

## Development Workflow

Install the module and test-harness dependencies from the repository root:

```bash
box install
cd test-harness && box install
```

Useful CommandBox scripts from the root:

```bash
box run-script format:check
box run-script format
box run-script build:module
box run-script build:docs
box run-script start:S3Mock
```

`start:S3Mock` requires Docker and starts the S3 mock used by S3 integration tests. Stop the container after testing with:

```bash
docker stop cbfs-s3-mock
```

The test harness is configured to run through TestBox at `http://localhost:60299/tests/runner.cfm`. Start the appropriate server using one of the repository's `server-*.json` configurations, then run the tests through the TestBox runner or the VS Code task `Run TestBox Bundle` for a focused bundle.

## Code Style

- Follow the root `.cfformat.json` configuration.
- Run `box run-script format:check` before finishing a change.
- Use the existing CFML formatting and naming conventions in nearby code.
- Keep public APIs and provider contracts backward-compatible unless the change explicitly requires otherwise.
- Add DocBox-style documentation for public components and functions, consistent with existing module code.
- Keep edits focused; do not reformat unrelated files.

## Testing Expectations

Add or update focused tests under `test-harness/tests/specs/` for behavior changes:

- Provider behavior belongs under `test-harness/tests/specs/providers/`.
- Service behavior belongs under `test-harness/tests/specs/services/`.
- Module lifecycle and integration behavior belongs under `test-harness/tests/specs/integration/`.

Use the existing TestBox patterns and clean up temporary files, sessions, and external resources in teardown code. Run the narrowest relevant test bundle first, then run the broader suite when practical.

## Change Boundaries

- Prefer existing abstractions such as `DiskService`, `AbstractDiskProvider`, `IDisk`, and the provider implementations over introducing parallel APIs.
- Keep filesystem operations portable across supported engines and platforms.
- Treat local paths, disk URLs, streams, and S3 credentials as distinct concerns; do not silently change their meaning.
- Do not commit generated build artifacts, test results, temporary directories, or local server files.
- Do not modify vendored module contents under `modules/` unless the task explicitly targets a bundled dependency.
