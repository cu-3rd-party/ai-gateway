# ai-gateway

LiteLLM Proxy поверх общего аккаунта OpenRouter: `https://ai.cu3rd.ru`.
Разворачивается через [self-service](https://git.cu3rd.ru/cu3rd/self-service),
проект `projects/ai-gateway.yaml`, окружение `prod`, приложение `litellm`, зона `grm`.

- `Dockerfile` — официальный non-root образ LiteLLM, закреплённый по digest, и `config.yaml`.
- `config.yaml` — любая модель OpenRouter по её id, метрики Prometheus, без хранения промптов.
- CI: на PR собирает образ, на push в `master` публикует его и открывает PR доставки.

## Как сервису получить ключ

В `projects/<проект>.yaml` self-service добавьте окружению `ai: {enabled: true}`
(лимиты и список моделей — в README self-service). После merge в контейнере появятся
`AI_API_KEY`, `AI_BASE_URL` и, если задан `model`, `AI_MODEL`.

```sh
curl "$AI_BASE_URL/chat/completions" -H "Authorization: Bearer $AI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model": "openai/gpt-4o-mini", "messages": [{"role": "user", "content": "ping"}]}'
```

Ключи для людей выдаются вручную в `https://ai.cu3rd.ru/ui` (вход: `admin` + master key).

## Настройка репозитория

Settings → Actions → Secrets:

| Secret | Значение |
|---|---|
| `OPENROUTER_API_KEY` | Ключ OpenRouter организации (с лимитом расходов в кабинете OpenRouter) |
| `LITELLM_MASTER_KEY` | `sk-` + случайная строка; тот же ключ — `TF_VAR_litellm_master_key` в runtime.env на nxs |
| `LITELLM_SALT_KEY` | Случайная строка; **не менять** после первого запуска |
| `SELF_SERVICE_DELIVERY_TOKEN` | Токен доставки self-service |

Сгенерировать: `python3 -c "import secrets; print('sk-' + secrets.token_urlsafe(32))"`.

## Обновление LiteLLM

Поменяйте тег и digest в `Dockerfile`, прочитайте release notes, откройте PR.
Миграции базы выполняются при старте пода. База бэкапится вместе с `pg-grm`.
Если база потеряна без бэкапа, self-service при следующем apply выпустит сервисам
новые ключи (новые значения, нужен rollout подов); ключи людей придётся выдать заново.
