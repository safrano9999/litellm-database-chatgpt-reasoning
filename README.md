# litellm-database-chatgpt-reasoning

Minimal overlay for the official LiteLLM Database image. It backports the
runtime fix from [LiteLLM PR #31332](https://github.com/BerriAI/litellm/pull/31332)
onto LiteLLM `v1.101.0` to recover ChatGPT Responses output from streamed
`response.output_item.done` / `response.output_text.done` events.

The final image is the unchanged official image plus three patched Python files.
Patch tooling is removed from the image in the same build step.

## Try it now

For an existing ephemeral `litellm-database` Podman Quadlet, replace the image
and persist the ChatGPT authentication directory with one named volume:

```ini
Image=ghcr.io/safrano9999/litellm-database-chatgpt-reasoning:latest
Volume=litellm-chatgpt-auth.volume:/root/.config/litellm/chatgpt:Z
```

Keep the existing LiteLLM database configuration and environment unchanged.
No wrapper is required.

## Fixed inputs

- Base: `ghcr.io/berriai/litellm-database:v1.101.0`
- Base index digest: `sha256:070df884f52600352a4aedda059180be141f3645c61c59b89b0ee35c17a4ea84`
- Upstream fix commit: `f8126c76748498ba08f40df9f71fbebe84cf2387`
- Unmodified upstream patch SHA-256: `355b2ea1ba72b77461d372c2f372decc03c9a7fcc1eec5b157ae57e5378d2009`

`patches/v1.101.0-pr31332.patch` is the explicit v1.101.0 backport.
The upstream recovery and accumulation methods are unchanged. Adaptations are
the import context and insertion into v1.101.0's terminal-response handling:
raw dictionary responses are normalized, recovered output is returned in a copy,
and v1.101.0's existing usage accounting is retained. The newer upstream usage
estimator is not imported. Failed responses are never backfilled.

`patches/manifest.json` records source identities and test hashes. The build
checks the SHA-256 of every original runtime file and applies with zero fuzz.
The 15 recovery regressions are unchanged from the pinned upstream commit.
The transformation tests use v1.101.0's test file with that commit's test updates.
GitHub Actions first reproduces the recovery failure on the official image,
then runs the tests inside the patched image without network access.
`:latest` is promoted only after those checks pass.

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
