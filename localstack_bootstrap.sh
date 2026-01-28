#!/usr/bin/env bash
set -euo pipefail

# Standard Notes uses SNS/SQS inside localstack for async jobs.
# Create the topics/queues required by the server.

awslocal sns create-topic --name events || true
awslocal sns create-topic --name auth || true

awslocal sqs create-queue --queue-name events || true
awslocal sqs create-queue --queue-name auth || true

# Subscribe queues to topics (best-effort)
EVENTS_TOPIC_ARN="$(awslocal sns list-topics --query "Topics[?ends_with(TopicArn, ':events')].TopicArn" --output text || true)"
AUTH_TOPIC_ARN="$(awslocal sns list-topics --query "Topics[?ends_with(TopicArn, ':auth')].TopicArn" --output text || true)"

EVENTS_QUEUE_URL="$(awslocal sqs get-queue-url --queue-name events --query "QueueUrl" --output text || true)"
AUTH_QUEUE_URL="$(awslocal sqs get-queue-url --queue-name auth --query "QueueUrl" --output text || true)"

EVENTS_QUEUE_ARN="$(awslocal sqs get-queue-attributes --queue-url "$EVENTS_QUEUE_URL" --attribute-names QueueArn --query "Attributes.QueueArn" --output text || true)"
AUTH_QUEUE_ARN="$(awslocal sqs get-queue-attributes --queue-url "$AUTH_QUEUE_URL" --attribute-names QueueArn --query "Attributes.QueueArn" --output text || true)"

if [[ -n "${EVENTS_TOPIC_ARN:-}" && -n "${EVENTS_QUEUE_ARN:-}" ]]; then
  awslocal sns subscribe --topic-arn "$EVENTS_TOPIC_ARN" --protocol sqs --notification-endpoint "$EVENTS_QUEUE_ARN" || true
fi

if [[ -n "${AUTH_TOPIC_ARN:-}" && -n "${AUTH_QUEUE_ARN:-}" ]]; then
  awslocal sns subscribe --topic-arn "$AUTH_TOPIC_ARN" --protocol sqs --notification-endpoint "$AUTH_QUEUE_ARN" || true
fi

echo "Localstack bootstrap done."
