# Async Policy Example

Sanitized excerpt of a policy-service refactor (anonymized): legacy loading replaced with `UserPolicyService` protocol, `async/await` configure, and unit tests.

## Run tests

```bash
cd examples/async-policy
swift test
```

## Highlights

- `configure() async throws` loads server policies once into an in-memory map
- Typed policy keys and value types (`binary`, `limit`, `both`)
- Synchronous read accessors for UI and content services after configure
- Tests cover API errors, invalid rows, unlimited limits (`-1`)

## Related

- ADR: [`docs/decisions/002-user-policy-protocol-extraction.md`](../../docs/decisions/002-user-policy-protocol-extraction.md)
- Feature briefs using policy gating: [`docs/features/`](../../docs/features/)
