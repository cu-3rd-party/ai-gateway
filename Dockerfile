# Официальный non-root образ LiteLLM, закреплённый по digest (v1.104.8).
# Обновление: поменять тег и digest, проверить release notes и собрать заново.
FROM ghcr.io/berriai/litellm-non_root:v1.104.8@sha256:754f46a68defdedd0857d84729712367578c559b4d92b216311062168b2f4d70

COPY --chmod=0444 config.yaml /app/config.yaml

ENV LITELLM_MODE=PRODUCTION \
    LITELLM_LOG=ERROR \
    PROMETHEUS_METRICS_PORT=4001

# SSO через Forgejo. GENERIC_CLIENT_ID/SECRET и PROXY_ADMIN_ID приходят из self-service.
ENV PROXY_BASE_URL=https://ai.cu3rd.ru \
    GENERIC_AUTHORIZATION_ENDPOINT=https://git.cu3rd.ru/login/oauth/authorize \
    GENERIC_TOKEN_ENDPOINT=https://git.cu3rd.ru/login/oauth/access_token \
    GENERIC_USERINFO_ENDPOINT=https://git.cu3rd.ru/login/oauth/userinfo \
    GENERIC_SCOPE="openid profile email" \
    GENERIC_USER_ID_ATTRIBUTE=sub \
    GENERIC_USER_EMAIL_ATTRIBUTE=email \
    GENERIC_USER_DISPLAY_NAME_ATTRIBUTE=name \
    GENERIC_CLIENT_USE_PKCE=true \
    AUTO_REDIRECT_UI_LOGIN_TO_SSO=true

# Swagger/ReDoc/openapi.json наружу не отдаём.
ENV NO_DOCS=true \
    NO_REDOC=true \
    NO_OPENAPI=true

# self-service запускает поды с UID/GID 10001.
USER 10001:10001
EXPOSE 4000 4001
CMD ["--config", "/app/config.yaml", "--port", "4000", "--num_workers", "1"]
