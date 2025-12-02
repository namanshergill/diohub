#!/bin/bash

# GitHub GraphQL Schema Downloader
# Usage: ./download_schema.sh YOUR_GITHUB_TOKEN

if [ -z "$1" ]; then
  echo "Usage: ./download_schema.sh YOUR_GITHUB_TOKEN"
  exit 1
fi

TOKEN=$1

echo "Downloading GitHub GraphQL schema..."

npx --yes get-graphql-schema https://api.github.com/graphql \
  --header "Authorization: token $TOKEN" \
  > lib/graphql/schema.graphql

if [ $? -eq 0 ]; then
  echo "Schema downloaded successfully to lib/graphql/schema.graphql"
else
  echo "Failed to download schema. Please check your token and try again."
  exit 1
fi

