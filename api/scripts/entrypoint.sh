#!/usr/bin/env bash

poetry run uvicorn api.main:app --host 0.0.0.0 --port 8080
