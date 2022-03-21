# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE="python:3.9-slim"
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE

# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

ARG PROJECT_NAME

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
ENV TZ Australia/Sydney
ENV SHELL /bin/bash
ENV PROJECT_NAME=$PROJECT_NAME
ENV HOME /home/$PROJECT_NAME

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
        maintainer="Humberto STEIN SHIROMOTO <h.stein.shiromoto@gmail.com>"

# ---
# Set up the necessary Debian packages
# ---
COPY debian-requirements.txt /usr/local/debian-requirements.txt
RUN apt-get update && \
	DEBIAN_PACKAGES=$(egrep -v "^\s*(#|$)" /usr/local/debian-requirements.txt) && \
    apt-get install -f -y $DEBIAN_PACKAGES && \
    apt-get clean

# ---
# Copy Container Setup Scripts
# ---
COPY poetry.lock /usr/local/poetry.lock
COPY pyproject.toml /usr/local/pyproject.toml

# Create the "home" folder
RUN mkdir -p $HOME
WORKDIR $HOME

COPY . $HOME

# Get poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

ENV PATH="${PATH}:$HOME/.poetry/bin"

RUN poetry config virtualenvs.create false \
    && cd /usr/local \
    && poetry install --no-interaction --no-ansi

CMD ["poetry", "run", "python", "src/gluqlo.py"]