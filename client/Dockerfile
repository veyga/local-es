FROM python:3.13-bookworm
RUN groupadd -g 1000 appuser && \
  useradd -m -u 1000 -g appuser appuser
RUN mkdir /app && chown appuser:appuser /app

RUN apt update -y && apt install -y --no-install-recommends \
  curl

WORKDIR /app
ENV PYTHONPATH="/app/src:${PYTHONPATH}"

COPY --chown=appuser:appuser pyproject.toml uv.lock /app/
ARG IS_LOCAL=false
RUN pip install uv
RUN uv export $(test "$IS_LOCAL" = "true" || echo --no-dev) > requirements.txt
RUN pip uninstall uv -y && \
  pip install --requirement requirements.txt && \
  rm requirements.txt

COPY --chown=appuser:appuser . /app/
RUN rm pyproject.toml uv.lock
USER appuser
RUN ln -sf /app/.bashrc /home/appuser/.bashrc
