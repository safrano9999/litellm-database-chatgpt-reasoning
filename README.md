# litellm-database-chatgpt-reasoning

Minimal overlay for the official LiteLLM Database image. It backports the
runtime fix from [LiteLLM PR #31332](https://github.com/BerriAI/litellm/pull/31332)
onto LiteLLM `v1.98.0` to recover ChatGPT Responses output from streamed
`response.output_item.done` / `response.output_text.done` events.

The final image is the unchanged official image plus four patched Python files.
Build tools exist only in the intermediate stage.

## Try it now

For an existing ephemeral `litellm-database` Podman Quadlet, replace the image
and persist the ChatGPT authentication directory with one named volume:

```ini
Image=ghcr.io/safrano9999/litellm-database-chatgpt-reasoning@sha256:b83d7037a3b10f6f75067ae0a8bd164318f12aeefc5f465481f72dcd70dd5bc7
Volume=litellm-chatgpt-auth.volume:/root/.config/litellm/chatgpt:Z
```

Keep the existing LiteLLM database configuration and environment unchanged.
No wrapper is required.

## Fixed inputs

- Base: `ghcr.io/berriai/litellm-database:v1.98.0`
- Base index digest: `sha256:5ead13edd4efd89f32dab349c1f19447d395affca53f3aeae00f5e6e01b8c08d`
- Upstream fix commit: `755a8b1e26224ae13cbf244bfe1b4b6077b98b61`
- Unmodified upstream patch SHA-256: `a3e0327491d7373ca08643dda6d6f38bf6365fa47d572b70d57546726ec19e7d`

`patches/v1.98.0-pr31332.patch` is the explicit v1.98.0 backport. Its only
departure from the upstream patch is rebased context for the relocated
`verbose_logger` import; the functional changes are unchanged. The build first
checks the SHA-256 of every target file and fails closed if the base differs.

## Verifiable build

GitHub Actions publishes:

- OCI labels containing the repository commit, base digest, Containerfile hash,
  backport-patch hash, and upstream patch identity;
- BuildKit `mode=max` provenance and an SPDX SBOM;
- a GitHub artifact attestation bound to the published image digest.

Use the immutable digest shown in the workflow summary:

```bash
gh attestation verify \
  oci://ghcr.io/safrano9999/litellm-database-chatgpt-reasoning@sha256:IMAGE_DIGEST \
  --repo safrano9999/litellm-database-chatgpt-reasoning

skopeo inspect --config \
  docker://ghcr.io/safrano9999/litellm-database-chatgpt-reasoning@sha256:IMAGE_DIGEST \
  | jq '.config.Labels'
```

This is a temporary compatibility image. It should be retired after the fix is
released by LiteLLM and the official image passes the same live request.
