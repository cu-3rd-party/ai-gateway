# ai-gateway

LiteLLM Proxy поверх общего аккаунта OpenRouter: `https://ai.cu3rd.ru`.
Разворачивается через [self-service](https://git.cu3rd.ru/cu3rd/self-service),
проект `projects/ai-gateway.yaml`, окружение `prod`, приложение `litellm`, зона `grm`.

- `Dockerfile` — официальный non-root образ LiteLLM, закреплённый по digest, и `config.yaml`.
- `config.yaml` — любая модель OpenRouter по её id, метрики Prometheus, без хранения промптов.
- CI: на PR собирает образ, на push в `master` публикует его и открывает PR доставки.

## Как вашему сервису получить ключ

### 1. Заказать ключ в self-service

В `projects/<проект>.yaml` добавьте окружению секцию `ai`. Минимальный вариант:

```yaml
name: my-service
team: members
envs:
  prod:
    zone: grm
    ai:
      enabled: true
    apps:
      api:
        repo: cu3rd/my-service
        image: git.cu3rd.ru/cu3rd/my-service
        tag: initial
        port: 8000
```

Вариант с ограничениями (всё, кроме `enabled`, необязательно):

```yaml
    ai:
      enabled: true
      model: openai/gpt-4o-mini        # модель по умолчанию, попадёт в AI_MODEL
      models: [openai/gpt-4o-mini, anthropic/claude-sonnet-4.5]  # разрешённые; без списка — любые
      budgetUsd: 10                    # лимит расходов в $ за период
      budgetPeriod: 30d                # период сброса бюджета
      rpm: 60                          # запросов в минуту
      tpm: 100000                      # токенов в минуту
```

После merge PR в self-service (и apply/Argo sync) в контейнеры всех приложений окружения
появятся переменные:

| Переменная | Значение |
|---|---|
| `AI_API_KEY` | ключ вашего окружения (общий для его приложений) |
| `AI_BASE_URL` | адрес gateway, `https://ai.cu3rd.ru/v1` |
| `AI_MODEL` | модель по умолчанию, только если задан `model` |

Ничего руками создавать и копировать не нужно. Если префикс `AI_` занят, поменяйте его через
`targetEnvPrefix: AI__`. Подробности и все поля — в README self-service.

### 2. Вызвать из Python

API совместим с OpenAI, поэтому используем официальный SDK: `pip install openai`.

```python
import os

from openai import OpenAI

client = OpenAI(
    base_url=os.environ["AI_BASE_URL"],
    api_key=os.environ["AI_API_KEY"],
)

response = client.chat.completions.create(
    model=os.environ.get("AI_MODEL", "openai/gpt-4o-mini"),
    messages=[
        {"role": "system", "content": "Отвечай коротко."},
        {"role": "user", "content": "Привет! Что ты умеешь?"},
    ],
)
print(response.choices[0].message.content)
```

Ответ по частям (streaming):

```python
stream = client.chat.completions.create(
    model=os.environ.get("AI_MODEL", "openai/gpt-4o-mini"),
    messages=[{"role": "user", "content": "Расскажи анекдот"}],
    stream=True,
)
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

Асинхронно (FastAPI и т. п.) — `from openai import AsyncOpenAI`, остальное то же самое
с `await`. Модели называются как в [OpenRouter](https://openrouter.ai/models):
`provider/model`, например `google/gemini-2.5-flash`. Если модель не входит в `models`
вашего ключа или упёрлись в бюджет/лимиты, gateway вернёт ошибку 400/401/429.

Проверка из shell без Python:

```sh
curl "$AI_BASE_URL/chat/completions" -H "Authorization: Bearer $AI_API_KEY"   -H 'Content-Type: application/json'   -d '{"model": "openai/gpt-4o-mini", "messages": [{"role": "user", "content": "ping"}]}'
```

Ключи для людей(или внешних сервисов вне нашей инфрастуктуры) выдаются вручную в `https://ai.cu3rd.ru/ui`. Нужно зайти к @xfx1337 или @pxc1984


## Обновление LiteLLM

Поменяйте тег и digest в `Dockerfile`, прочитайте release notes, откройте PR.
Миграции базы выполняются при старте пода. База бэкапится вместе с `pg-grm`.
Если база потеряна без бэкапа, self-service при следующем apply выпустит сервисам
новые ключи (новые значения, нужен rollout подов); ключи людей придётся выдать заново.
