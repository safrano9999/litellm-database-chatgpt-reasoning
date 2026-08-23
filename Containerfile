FROM ghcr.io/berriai/litellm-database@sha256:5ead13edd4efd89f32dab349c1f19447d395affca53f3aeae00f5e6e01b8c08d AS patched

RUN apk add --no-cache patch
COPY patches/base-v1.98.0.sha256 /tmp/base.sha256
COPY patches/v1.98.0-pr31332.patch /tmp/reasoning.patch
WORKDIR /app/.venv/lib/python3.13/site-packages
RUN sha256sum -c /tmp/base.sha256 \
    && patch --batch --forward -p1 < /tmp/reasoning.patch \
    && python3 -m py_compile \
       litellm/responses/mcp/mcp_streaming_iterator.py \
       litellm/responses/sse_output_recovery.py \
       litellm/responses/streaming_iterator.py \
       litellm/router.py \
    && mkdir -p /patched/litellm/responses/mcp \
    && cp litellm/router.py /patched/litellm/router.py \
    && cp litellm/responses/streaming_iterator.py /patched/litellm/responses/streaming_iterator.py \
    && cp litellm/responses/sse_output_recovery.py /patched/litellm/responses/sse_output_recovery.py \
    && cp litellm/responses/mcp/mcp_streaming_iterator.py /patched/litellm/responses/mcp/mcp_streaming_iterator.py

FROM ghcr.io/berriai/litellm-database@sha256:5ead13edd4efd89f32dab349c1f19447d395affca53f3aeae00f5e6e01b8c08d

ARG SOURCE_REVISION=unknown
ARG BUILD_VERSION=v1.98.0-pr31332.1
ARG CONTAINERFILE_SHA256=unverified
ARG BACKPORT_PATCH_SHA256=unverified

LABEL org.opencontainers.image.title="LiteLLM Database ChatGPT Reasoning" \
      org.opencontainers.image.description="LiteLLM Database v1.98.0 with the focused ChatGPT Responses output recovery from PR 31332" \
      org.opencontainers.image.source="https://github.com/safrano9999/litellm-database-chatgpt-reasoning" \
      org.opencontainers.image.revision="$SOURCE_REVISION" \
      org.opencontainers.image.version="$BUILD_VERSION" \
      org.opencontainers.image.base.name="ghcr.io/berriai/litellm-database:v1.98.0" \
      org.opencontainers.image.base.digest="sha256:5ead13edd4efd89f32dab349c1f19447d395affca53f3aeae00f5e6e01b8c08d" \
      io.github.safrano9999.containerfile.sha256="$CONTAINERFILE_SHA256" \
      io.github.safrano9999.backport-patch.sha256="$BACKPORT_PATCH_SHA256" \
      io.github.safrano9999.upstream-pr="https://github.com/BerriAI/litellm/pull/31332" \
      io.github.safrano9999.upstream-commit="755a8b1e26224ae13cbf244bfe1b4b6077b98b61" \
      io.github.safrano9999.upstream-patch.sha256="a3e0327491d7373ca08643dda6d6f38bf6365fa47d572b70d57546726ec19e7d"

COPY --from=patched /patched/ /app/.venv/lib/python3.13/site-packages/
