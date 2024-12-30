FROM python:3.12-slim as build

ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=1.8.5 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    \
    # paths
    # this is where our requirements + virtual environment will live
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Install system deps
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -qq curl  && \
    curl -sSL https://install.python-poetry.org | python3 -

WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./
# install runtime deps - uses $POETRY_VIRTUALENVS_IN_PROJECT internally
RUN poetry install --no-root

WORKDIR /usr/src/app
COPY . ./
RUN poetry run nikola build


# Final image. Everything is static, let's use nginx
FROM nginx:latest as prod

EXPOSE 80

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /usr/src/app/output /var/www/website

## Labels
LABEL maintainer="etapres@pygillier.me"
LABEL org.label-schema.name='et-apres.pygillier.me'
LABEL org.label-schema.description="Et Apres, a website on death and digital legacy"

