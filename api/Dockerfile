# Pythonの公式イメージをベースにする
FROM python:3.10-slim-buster
WORKDIR /app

# poetryのバージョンを指定
ARG POETRY_VERSION=1.5.1

# 環境変数の設定
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100
ENV PATH $POETRY_HOME/bin:$PATH

# 必要なパッケージのインストール
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    curl \
    build-essential

# poetryのインストール
RUN curl -sSL https://install.python-poetry.org | python -
# 仮想環境を作成しない設定(コンテナ前提のため，仮想環境を作らない)
RUN poetry config virtualenvs.create false

COPY pyproject.toml poetry.lock ./
RUN poetry install --no-dev

COPY . .

CMD ["./scripts/entrypoint.sh"]
