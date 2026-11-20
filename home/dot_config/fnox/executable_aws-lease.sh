#!/usr/bin/env bash
# fnox lease: assumes the repository's AWS CI role (AWS_IDENTITY_ROLE_ARN) with the ci-assume Identity Center session.
# Requires `aws sso login --profile ci-assume`; the session is capped at 1 h because the role is chained.
set -euo pipefail

role_arn="$(fnox get AWS_IDENTITY_ROLE_ARN)"

aws sts assume-role --profile ci-assume --role-arn "${role_arn}" --role-session-name fnox \
  --duration-seconds 3600 --output json |
  jq '{
    credentials: {
      AWS_ACCESS_KEY_ID: .Credentials.AccessKeyId,
      AWS_SECRET_ACCESS_KEY: .Credentials.SecretAccessKey,
      AWS_SESSION_TOKEN: .Credentials.SessionToken
    },
    expires_at: .Credentials.Expiration
  }'
