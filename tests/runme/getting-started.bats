#!/usr/bin/env bats
load 'helpers/bats-support/load'
load 'helpers/bats-assert/load'
load 'helpers/bats-detik/lib/detik'

RUNME_FLAGS="--chdir ../../linkerd.io/content/2.12/getting-started --filename _index.md"
RUNME_RUN_CMD="runme run $RUNME_FLAGS"

REMOTE="" # set to 'skip' to omit all remote steps (for dev)

DETIK_CLIENT_NAME="kubectl"

@test "Verify kubectl version step" {
  run $RUNME_RUN_CMD kubectl-version
  assert_line -p "Client Version:"
  assert_line -p "Kustomize Version:"
  assert_line -p "Server Version:"
  assert_success
}

@test "Verify install linkerd step" {
  run $RUNME_RUN_CMD curl-proto
  assert_line -p "Checksum valid."
  assert_line -p "Linkerd stable"
  assert_success
}

@test "Verify linkerd version" {
  run $RUNME_RUN_CMD linkerd-version
  assert_line -p "Client version: stable"
  assert_success
}

@test "Verify linkerd pre check" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-check
  assert_line -p "Status check results are √"
  assert_success
}

@test "Verify linkerd install CRDs" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-install
  assert_success
}

@test "Verify linkerd install" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-install-2
  assert_success
}

@test "Verify linkerd check" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-check-2
  assert_success
}

@test "Verify install emojivoto" {
  $REMOTE
  DETIK_CLIENT_NAMESPACE="emojivoto"
  run $RUNME_RUN_CMD curl-proto-2
  assert_line -p "namespace/emojivoto"
  assert_line -p "deployment.apps/emoji"
  assert_line -p "deployment.apps/vote-bot"
  assert_line -p "deployment.apps/voting"
  assert_line -p "deployment.apps/web"
  try "at most 10 times every 30s to get pods named 'emoji' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'vote-bot' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'voting' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'web' and verify that 'status' is 'running'"
  assert_success
}

@test "Verify linkerd injection" {
  $REMOTE
  DETIK_CLIENT_NAMESPACE="emojivoto"
  run $RUNME_RUN_CMD kubectl-get
  assert_line -p "deployment \"emoji\" injected"
  assert_line -p "deployment \"vote-bot\" injected"
  assert_line -p "deployment \"voting\" injected"
  assert_line -p "deployment \"web\" injected"
  try "at most 10 times every 30s to get pods named 'emoji' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'vote-bot' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'voting' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'web' and verify that 'status' is 'running'"
  assert_success
}

@test "Verify emojivoto data plane" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-n
  assert_line -p "Status check results are √"
  assert_success
}

@test "Verify linkerd install control plane" {
  $REMOTE
  DETIK_CLIENT_NAMESPACE="linkerd-viz"
  run $RUNME_RUN_CMD linkerd-viz
  assert_line -p "namespace/linkerd-viz"
  try "at most 10 times every 30s to get pods named 'metrics-api' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'prometheus' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'tap' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'tap-injector' and verify that 'status' is 'running'"
  try "at most 10 times every 30s to get pods named 'web' and verify that 'status' is 'running'"
  assert_success
}

@test "Verify linkerd check control plane" {
  $REMOTE
  run $RUNME_RUN_CMD linkerd-check-3
  assert_line -p "√ viz extension self-check"
  assert_success
}
