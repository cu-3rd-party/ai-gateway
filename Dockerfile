# Официальный non-root образ LiteLLM, закреплённый по digest (v1.104.8).
# Обновление: поменять тег и digest, проверить release notes и собрать заново.
FROM ghcr.io/berriai/litellm-non_root:v1.104.8@sha256:754f46a68defdedd0857d84729712367578c559b4d92b216311062168b2f4d70

COPY --chmod=0444 config.yaml /app/config.yaml

ENV LITELLM_MODE=PRODUCTION \
    LITELLM_LOG=ERROR \
    PROMETHEUS_METRICS_PORT=4001

# self-service запускает поды с UID/GID 10001.
USER 10001:10001
EXPOSE 4000 4001
CMD ["--config", "/app/config.yaml", "--port", "4000", "--num_workers", "1"]
