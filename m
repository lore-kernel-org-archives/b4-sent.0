From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:11:02 +0200
Subject: [PATCH v3 08/15] test: check which files fuservicemount3 opens for
 the server
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-8-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=13099; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=tZ22sDzRbuMGZdIUiv7oagf4+PlCu92ZmPDqBMc1lME=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cuVcVT/8dIvkncy7yxbfWld6sier74Zenoyb9oNZF
 2Z4/u9l7ShlYRDjYJAVU2TpkthjO+Ufn6za1/XXYeawMoEMYeDiFICJTD7B8D9uJ3dF97bHbP8r
 F7522VT+dsn8b89v7zWcxTe992RBTtQaRob92sUr4tfHaW30fHGfde/Onmg++fXytrF+15NOvIs
 wKGIDAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No test covered the OPEN and OPEN_BDEV commands of fuservicemount3.
test_service is a fuse server that sends one request and prints the
errno it got back. socket_activate.py starts it the way a systemd
socket unit does, so the tests do not depend on systemd.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 .gitignore                             |   1 +
 test/cases/lib/service.sh              |  83 ++++++++++++++++
 test/cases/lib/socket_activate.py      |  42 ++++++++
 test/cases/mount/service-open-bound.sh |  61 ++++++++++++
 test/meson.build                       |   6 ++
 test/test_service.c                    | 176 +++++++++++++++++++++++++++++++++
 6 files changed, 369 insertions(+)

diff --git a/.gitignore b/.gitignore
index 99b486d69169..4e560aa473b6 100644
--- a/.gitignore
+++ b/.gitignore
@@ -43,6 +43,7 @@ TAGS
 /test/test_api_30
 /test/test_fuser_conf
 /test/test_deferred_reply_teardown
+/test/test_service
 /test/hello_ll
 /build/
 # run-tests.py output, when pointed at the source tree with --run-dir
diff --git a/test/cases/lib/service.sh b/test/cases/lib/service.sh
new file mode 100644
index 000000000000..d0a0fa0183d0
--- /dev/null
+++ b/test/cases/lib/service.sh
@@ -0,0 +1,83 @@
+# lib/service.sh - start a fuse service server the way a systemd socket unit
+# does, for the fuservicemount3 cases.
+#
+# Sourced after common.sh. The socket has to be in the build-time socket
+# directory, so every caller runs as root.
+
+# service_setup <subtype>
+# Set service_sock. At exit remove the socket and any mount on $TEST_MNT.
+service_setup()
+{
+	service_subtype=$1
+	service_runs=0
+	# A case may set it, to add arguments to the helper command line
+	service_helper_args=()
+	service_sock=$("$FUSE_TEST_BIN_DIR/test_service" socket-path "$1")
+	# Every service script binds its own socket here; removing the
+	# directory would break another script's bind()
+	mkdir -p "$(dirname "$service_sock")"
+	_at_exit "rm -f '$service_sock'"
+	_at_exit "umount -l '$TEST_MNT' 2>/dev/null"
+}
+
+# service_start <log> <program> [args...]
+# Listen on service_sock and run <program> for the first connection, with its
+# output in <log>. Sets service_pid.
+service_start()
+{
+	local log=$1; shift
+
+	rm -f "$service_sock"
+	python3 "$TEST_LIB/socket_activate.py" "$service_sock" "$@" \
+		>"$log" 2>&1 &
+	service_pid=$!
+	_wait_for 10 "grep -q '^listening' '$log'" ||
+		_fail "$service_sock never listened"
+}
+
+# service_wait_exit
+# Reap the server and set service_rc to its exit status. A helper that never
+# connected leaves the activator in accept(), which is a failure.
+service_wait_exit()
+{
+	_wait_for 10 "! kill -0 $service_pid 2>/dev/null" || {
+		kill "$service_pid" 2>/dev/null || true
+		_fail "server (pid $service_pid) did not exit"
+	}
+	service_rc=0
+	wait "$service_pid" || service_rc=$?
+}
+
+# service_mount <source> <mountpoint> <case> [args...]
+# Run fuservicemount3 once against test_service <case> [args...] and reap the
+# server. Sets service_log.
+service_mount()
+{
+	local source=$1 mnt=$2; shift 2
+
+	service_log=$TEST_LOGDIR/fs-$service_runs-$1.out
+	service_runs=$((service_runs + 1))
+	service_start "$service_log" "$FUSE_TEST_BIN_DIR/test_service" "$@"
+
+	# Its exit status depends on the case; the server's line is the verdict.
+	"$FUSE_UTIL_DIR/fuservicemount3" "$source" "$mnt" \
+		-t "fuse.$service_subtype" "${service_helper_args[@]}" || true
+
+	service_wait_exit
+}
+
+# service_result <what>
+# The last server prints one "<what> result: <value>" line, for example
+# "request result: EPERM". Echo <value>; fail on no such line or several.
+service_result()
+{
+	local count
+
+	count=$(grep -c "^$1 result: " "$service_log") || true
+	if [ "$count" != 1 ]; then
+		cat "$service_log" >&2
+		_fail "$service_log: $count \"$1 result:\" lines, want 1"
+	fi
+	# -n and p: print only the line the substitution matched
+	sed -n "s/^$1 result: //p" "$service_log"
+}
diff --git a/test/cases/lib/socket_activate.py b/test/cases/lib/socket_activate.py
new file mode 100755
index 000000000000..c33ca3a61ff2
--- /dev/null
+++ b/test/cases/lib/socket_activate.py
@@ -0,0 +1,42 @@
+#!/usr/bin/env python3
+"""socket_activate.py <socket-path> <program> [args...]
+
+Listen on a SOCK_SEQPACKET socket, accept one connection and exec <program>
+with it, the way systemd starts a socket unit with Accept=yes: the connection
+is fd 3, LISTEN_FDS=1 and LISTEN_PID is the pid that runs <program>.
+
+Prints "listening" once a connect() can succeed.
+"""
+
+import os
+import socket
+import sys
+
+SD_LISTEN_FDS_START = 3
+
+
+def main():
+    if len(sys.argv) < 3:
+        sys.exit(__doc__)
+    path = sys.argv[1]
+    program = sys.argv[2:]
+
+    listener = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
+    listener.bind(path)
+    listener.listen(1)
+    print('listening', flush=True)
+
+    conn, _ = listener.accept()
+    listener.close()
+
+    # conn itself is close-on-exec and goes away with the exec
+    os.dup2(conn.fileno(), SD_LISTEN_FDS_START)
+    os.set_inheritable(SD_LISTEN_FDS_START, True)
+    os.environ['LISTEN_FDS'] = '1'
+    # exec keeps the pid
+    os.environ['LISTEN_PID'] = str(os.getpid())
+    os.execv(program[0], program)
+
+
+if __name__ == '__main__':
+    main()
diff --git a/test/cases/mount/service-open-bound.sh b/test/cases/mount/service-open-bound.sh
new file mode 100755
index 000000000000..3ef3690a42e9
--- /dev/null
+++ b/test/cases/mount/service-open-bound.sh
@@ -0,0 +1,61 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# fuservicemount3 opens a file for the fuse server only if the path is on its
+# command line.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+_require_linux "fuservicemount3"
+_require_root
+_require_fuse_device
+_require_binary util/fuservicemount3
+_require_binary test/test_service
+
+. "$TEST_LIB/service.sh"
+
+# One socket per run, so a parallel run does not connect to this one
+subtype=test-open-$$
+img=$TEST_SRC/img
+
+touch "$img"
+service_setup "$subtype"
+
+# service_open_request <case> <path> <expected errno name, or 0>
+# Mount $img through fuservicemount3 with the server started for <case>.
+service_open_request()
+{
+	local case=$1 path=$2 expected=$3
+
+	service_mount "$img" "$TEST_MNT" "$case" "$path"
+	_assert_eq "$(service_result request)" "$expected" "$case $path"
+}
+
+# $img is on the command line
+service_open_request open "$img" 0
+# Root can read /etc/passwd, so EPERM comes from the command line check
+service_open_request open /etc/passwd EPERM
+# Passes the command line check, fails the block device check
+service_open_request open-bdev "$img" ENOTBLK
+# Not ENOTBLK: OPEN_BDEV gets the command line check first
+service_open_request open-bdev /etc/passwd EPERM
+
+# A path in an option value, as the server's option parser splits it
+journal=$TEST_SRC/journal,img
+touch "$journal"
+service_helper_args=(-o "ro,journal_dev=${journal//,/\\,}")
+service_open_request open "$journal" 0
+# The directory of an option value is not a path the user named
+service_open_request open "$TEST_SRC" EPERM
+service_helper_args=("-J$journal")
+service_open_request open "$journal" 0
+service_helper_args=()
+
+# After MNTPT the helper runs inside $TEST_MNT. A relative path must still
+# resolve in the directory the helper started in.
+cd "$TEST_SRC"
+service_mount img "$TEST_MNT" open-after-mount img
+cd "$OLDPWD"
+_assert_eq "$(service_result request)" 0 "open-after-mount img"
+umount "$TEST_MNT"
diff --git a/test/meson.build b/test/meson.build
index 477b7bf59005..a8518c314804 100644
--- a/test/meson.build
+++ b/test/meson.build
@@ -58,6 +58,12 @@ if build_utils
                    c_args: '-DFUSE_CONF="fuse.conf"',
                    install: false)
 endif
+if private_cfg.get('HAVE_SERVICEMOUNT', false)
+  td += executable('test_service', 'test_service.c',
+                   include_directories: include_dirs,
+                   link_with: [ libfuse ],
+                   install: false)
+endif
 
 if meson.is_subproject()
 	# Skipped rather than run: the tests mount filesystems, which is not
diff --git a/test/test_service.c b/test/test_service.c
new file mode 100644
index 000000000000..0d54df3427a9
--- /dev/null
+++ b/test/test_service.c
@@ -0,0 +1,176 @@
+/*
+ * FUSE: Filesystem in Userspace
+ *
+ * This program can be distributed under the terms of the GNU GPLv2.
+ * See the file GPL2.txt.
+ *
+ * A fuse service server for the service mount tests. Each mode takes one
+ * step against fuservicemount3 and prints the name of the errno that came
+ * back, 0 for success.
+ *
+ *   test_service socket-path <subtype>
+ *   test_service open <path>
+ *   test_service open-bdev <path>
+ *   test_service open-after-mount <path>
+ */
+
+#define FUSE_USE_VERSION FUSE_MAKE_VERSION(3, 19)
+
+/* strerrorname_np() */
+#ifndef _GNU_SOURCE
+#define _GNU_SOURCE
+#endif
+
+#include "fuse_config.h"
+#include <fuse_lowlevel.h>
+#include <fuse_service.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <fcntl.h>
+#include <unistd.h>
+#include <sys/stat.h>
+
+static const struct fuse_lowlevel_ops test_service_oper = { };
+
+/* @return "EPERM" and so on, "0" for no error */
+static const char *errno_name(int error)
+{
+	const char *name;
+
+	if (!error)
+		return "0";
+
+	name = strerrorname_np(error);
+	return name ? name : "unknown errno";
+}
+
+/* The first non-option argument is the mount source, not the mountpoint */
+static int skip_source(void *data, const char *arg, int key,
+		       struct fuse_args *outargs)
+{
+	bool *source_seen = data;
+
+	(void)arg;
+	(void)outargs;
+
+	if (key == FUSE_OPT_KEY_NONOPT && !*source_seen) {
+		*source_seen = true;
+		return 0;
+	}
+	return 1;
+}
+
+/*
+ * Mount through the helper so that it has a mount point when the file is
+ * requested.
+ *
+ * @return the mounted session, or NULL on failure
+ */
+static struct fuse_session *session_mounted(struct fuse_service *service,
+					    const char *argv0)
+{
+	struct fuse_args args = FUSE_ARGS_INIT(0, NULL);
+	struct fuse_cmdline_opts opts = { };
+	struct fuse_session *se = NULL;
+	bool source_seen = false;
+
+	if (fuse_opt_add_arg(&args, argv0) ||
+	    fuse_service_append_args(service, &args) ||
+	    fuse_opt_parse(&args, &source_seen, NULL, skip_source) ||
+	    fuse_service_parse_cmdline_opts(&args, &opts))
+		goto out;
+
+	se = fuse_session_new(&args, &test_service_oper,
+			      sizeof(test_service_oper), NULL);
+	if (!se)
+		goto out;
+
+	if (fuse_service_session_mount(service, se, S_IFDIR, &opts)) {
+		fuse_session_destroy(se);
+		se = NULL;
+	}
+
+out:
+	free(opts.mountpoint);
+	fuse_opt_free_args(&args);
+	return se;
+}
+
+/* @return 0 when the result was printed, negative errno otherwise */
+static int request_printed(const struct fuse_service *service,
+			   const char *path, bool blockdev)
+{
+	int fd;
+	int ret;
+
+	if (blockdev)
+		ret = fuse_service_request_blockdev(service, path, O_RDONLY,
+						    0, 0, 0);
+	else
+		ret = fuse_service_request_file(service, path, O_RDONLY, 0, 0);
+	if (ret)
+		return ret;
+
+	/* A refusal by the helper is a success return, with -errno in fd */
+	ret = fuse_service_receive_file(service, path, &fd);
+	if (ret)
+		return ret;
+
+	if (fd >= 0) {
+		close(fd);
+		printf("request result: 0\n");
+	} else {
+		printf("request result: %s\n", errno_name(-fd));
+	}
+	fflush(stdout);
+	return 0;
+}
+
+int main(int argc, char *argv[])
+{
+	struct fuse_service *service = NULL;
+	struct fuse_session *se = NULL;
+	bool blockdev = false;
+	int ret = 1;
+
+	if (argc != 3) {
+		fprintf(stderr, "usage: %s socket-path <subtype>\n", argv[0]);
+		fprintf(stderr, "       %s open|open-bdev|open-after-mount <path>\n",
+			argv[0]);
+		return 1;
+	}
+
+	if (!strcmp(argv[1], "socket-path")) {
+		printf("%s/%s\n", FUSE_SERVICE_SOCKET_DIR, argv[2]);
+		return 0;
+	}
+
+	if (fuse_service_accept(&service) || !fuse_service_accepted(service)) {
+		fprintf(stderr, "%s: not started as a fuse service\n", argv[0]);
+		return 1;
+	}
+
+	if (!strcmp(argv[1], "open-after-mount")) {
+		se = session_mounted(service, argv[0]);
+		if (!se)
+			goto out;
+	} else if (!strcmp(argv[1], "open-bdev")) {
+		blockdev = true;
+	} else if (strcmp(argv[1], "open")) {
+		fprintf(stderr, "%s: unknown case %s\n", argv[0], argv[1]);
+		goto out;
+	}
+
+	if (request_printed(service, argv[2], blockdev))
+		goto out;
+
+	ret = 0;
+out:
+	fuse_service_send_goodbye(service, ret);
+	fuse_service_destroy(&service);
+	/* Closes /dev/fuse; the test script unmounts */
+	if (se)
+		fuse_session_destroy(se);
+	return ret;
+}

-- 
2.53.0

