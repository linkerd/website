load 'helpers/bats-detik/lib/detik'

RUNME_REMOVE_FLAGS="--chdir ../../linkerd.io/content/2.12/tasks --filename uninstall.md"
RUNME_REMOVE_CMD="runme run $RUNME_REMOVE_FLAGS"

DETIK_CLIENT_NAME="kubectl"

setup_suite() {
    return 0
}

linkerd_uninstall_viz() {
    echo 'Uninstalling linkerd viz' >&3
    bash -c "$RUNME_REMOVE_CMD uninstall-viz"
}

linkerd_uninject_emojivoto() {
    echo 'Uninjecting emojivoto' >&3
    DETIK_CLIENT_NAMESPACE="emojivoto"
    bash -c "$RUNME_REMOVE_CMD kubectl-get"
    sleep 5
    try "at most 2 times every 30s to find 1 pods named 'emoji' with 'status' being 'running'"
    try "at most 2 times every 30s to find 1 pods named 'vote-bot' with 'status' being 'running'"
    try "at most 2 times every 30s to find 1 pods named 'voting' with 'status' being 'running'"
    try "at most 2 times every 30s to find 1 pods named 'web' with 'status' being 'running'"
}

linkerd_uninstall_emojivoto() {
    echo 'Uninstalling emojivoto' >&3
    DETIK_CLIENT_NAMESPACE="emojivoto"
    bash -c "$RUNME_REMOVE_CMD curl-proto"
    try "at most 10 times every 30s to find 0 pods named 'emoji' with 'status' being 'running'"
    try "at most 10 times every 30s to find 0 pods named 'vote-bot' with 'status' being 'running'"
    try "at most 10 times every 30s to find 0 pods named 'voting' with 'status' being 'running'"
    try "at most 10 times every 30s to find 0 pods named 'web' with 'status' being 'running'"
}

linkerd_uninstall() {
    echo 'Uninstalling linkerd' >&3
    bash -c "$RUNME_REMOVE_CMD linkerd-uninstall"
}

teardown_suite() {
    echo 'Tearing down' >&3
    linkerd_uninstall_viz
    linkerd_uninject_emojivoto
    linkerd_uninstall_emojivoto
    linkerd_uninstall
}