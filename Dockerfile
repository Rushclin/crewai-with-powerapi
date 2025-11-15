# FROM python:3.12-slim

# RUN apt-get update && apt-get install -y \
#     curl \
#     git \
#     build-essential \
#     && rm -rf /var/lib/apt/lists/*

# WORKDIR /app

# RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# ENV PATH="/root/.local/bin:/root/.cargo/bin:${PATH}"

# RUN uv tool install crewai

# COPY pyproject.toml /app/

# ENV PYTHONPATH="/app/src:${PYTHONPATH}"

# RUN crewai install

# COPY . .
# # COPY . /app


# # EXPOSE 8000

# # WORKDIR /app/src

# # CMD ["crewai", "run"]
# # CMD [""]
#   CMD ["echo", "Hello from Docker!"]









FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies using uv
RUN uv sync --frozen --no-install-project

# Set the PYTHONPATH to include src/
ENV PYTHONPATH=/app/src

# Copy the application code
COPY . .
RUN poetry install
COPY <<EOF /entrypoint.sh
#!/bin/sh

if test -f /run/secrets/openai-api-key; then
    export OPENAI_API_KEY=$(cat /run/secrets/openai-api-key)
fi

if test -n "\${OPENAI_API_KEY}"; then
    echo "Using OpenAI with \${OPENAI_MODEL_NAME}"
else
    echo "Using Docker Model Runner with \${MODEL_RUNNER_MODEL}"
    export OPENAI_BASE_URL=\${MODEL_RUNNER_URL}
    export OPENAI_MODEL_NAME=openai/\${MODEL_RUNNER_MODEL}
    export OPENAI_API_KEY=cannot_be_empty
fi
exec poetry run crewtest
EOF
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]