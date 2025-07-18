FROM python:3.12-slim

COPY docker-transfer/sync.py /sync.py

# Transfer
COPY chart /chart
COPY docs /docs

RUN pip install ruamel.yaml && python sync.py chart/helm/trino/release-images.yaml chart/helm/trino/values.yaml
