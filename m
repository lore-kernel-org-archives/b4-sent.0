From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:11:03 +0200
Subject: [PATCH v3 09/15] test: check what fuservicemount3 refuses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-9-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=14199; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=36QwPDfeDF0EZbBuBQjWvfv3F7J82LYfh/Dt/aLjlvA=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cuXyrXyxfsYLreqKpD1cx3TYjXelnX8SfIUrR2PLj
 rbZ3DIrO0pZGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAiLhKMDDeybTtOMhZWXP/2
 0zenMZg1ZU/ZogO3C3Ksq4x2XGrxkGNk2NS6Wa3b5TBHjYOhlMnq/E8Nu8tulb8zz3Sr+Zjm/zi
 DCwA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fuservicemount3 runs setuid root and acts on requests from a fuse
server it does not trust. No test covered its checks on the subtype,
the mount point and its file type, fuseblk for a user who is not root,
or a server that exits before its goodbye.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 test/cases/lib/service.sh               |  20 ++++--
 test/cases/mount/service-caps.sh        |  20 ++++++
 test/cases/mount/service-check.sh       |  38 ++++++++++++
 test/cases/mount/service-mountpoint.sh  |  36 +++++++++++
 test/cases/mount/service-nonroot.sh     |  54 +++++++++++++++++
 test/cases/mount/service-server-exit.sh |  22 +++++++
 test/test_service.c                     | 104 ++++++++++++++++++++++++--------
 7 files changed, 266 insertions(+), 28 deletions(-)

diff --git a/test/cases/lib/service.sh b/test/cases/lib/service.sh
index d0a0fa0183d0..60c6c72820ef 100644
--- a/test/cases/lib/service.sh
+++ b/test/cases/lib/service.sh
@@ -10,6 +10,8 @@ service_setup()
 {
 	service_subtype=$1
 	service_runs=0
+	# A case may prefix it, to run the helper as another user
+	service_helper=("$FUSE_UTIL_DIR/fuservicemount3")
 	# A case may set it, to add arguments to the helper command line
 	service_helper_args=()
 	service_sock=$("$FUSE_TEST_BIN_DIR/test_service" socket-path "$1")
@@ -33,6 +35,16 @@ service_start()
 	service_pid=$!
 	_wait_for 10 "grep -q '^listening' '$log'" ||
 		_fail "$service_sock never listened"
+	# connect() needs write permission, and a case may run as another user
+	chmod 0666 "$service_sock"
+}
+
+# service_stop
+# Kill an activator that no helper connected to.
+service_stop()
+{
+	kill "$service_pid" 2>/dev/null || true
+	wait "$service_pid" 2>/dev/null || true
 }
 
 # service_wait_exit
@@ -50,7 +62,7 @@ service_wait_exit()
 
 # service_mount <source> <mountpoint> <case> [args...]
 # Run fuservicemount3 once against test_service <case> [args...] and reap the
-# server. Sets service_log.
+# server. Sets service_log and service_helper_rc.
 service_mount()
 {
 	local source=$1 mnt=$2; shift 2
@@ -59,9 +71,9 @@ service_mount()
 	service_runs=$((service_runs + 1))
 	service_start "$service_log" "$FUSE_TEST_BIN_DIR/test_service" "$@"
 
-	# Its exit status depends on the case; the server's line is the verdict.
-	"$FUSE_UTIL_DIR/fuservicemount3" "$source" "$mnt" \
-		-t "fuse.$service_subtype" "${service_helper_args[@]}" || true
+	service_helper_rc=0
+	"${service_helper[@]}" "$source" "$mnt" -t "fuse.$service_subtype" \
+		"${service_helper_args[@]}" || service_helper_rc=$?
 
 	service_wait_exit
 }
diff --git a/test/cases/mount/service-caps.sh b/test/cases/mount/service-caps.sh
new file mode 100755
index 000000000000..69bc2bdbef8d
--- /dev/null
+++ b/test/cases/mount/service-caps.sh
@@ -0,0 +1,20 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# fuservicemount3 run by root offers the fuse server allow_other and fuseblk.
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
+service_setup "test-caps-$$"
+
+service_mount "$service_subtype" "$TEST_MNT" caps
+_assert_eq "$(service_result caps)" "allow_other=1 fuseblk=1" "caps as root"
diff --git a/test/cases/mount/service-check.sh b/test/cases/mount/service-check.sh
new file mode 100755
index 000000000000..ec30031d039e
--- /dev/null
+++ b/test/cases/mount/service-check.sh
@@ -0,0 +1,38 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# fuservicemount3 --check succeeds only for a socket named after the subtype,
+# and never for a subtype that is a path.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+_require_linux "fuservicemount3"
+_require_root
+_require_binary util/fuservicemount3
+_require_binary test/test_service
+
+. "$TEST_LIB/service.sh"
+
+subtype=test-check-$$
+service_setup "$subtype"
+
+# check_rc <fstype>
+check_rc()
+{
+	local rc=0
+
+	"$FUSE_UTIL_DIR/fuservicemount3" -t "$1" --check || rc=$?
+	echo "$rc"
+}
+
+_assert_eq "$(check_rc "fuse.$subtype")" 1 "no socket"
+
+touch "$service_sock"
+_assert_eq "$(check_rc "fuse.$subtype")" 1 "regular file"
+
+service_start "$TEST_LOGDIR/fs-check.out" "$FUSE_TEST_BIN_DIR/test_service" caps
+_assert_eq "$(check_rc "fuse.$subtype")" 0 "listening socket"
+# The same socket, named through a path
+_assert_eq "$(check_rc "fuse../$subtype")" 1 "subtype ./$subtype"
+service_stop
diff --git a/test/cases/mount/service-mountpoint.sh b/test/cases/mount/service-mountpoint.sh
new file mode 100755
index 000000000000..0df4733389e0
--- /dev/null
+++ b/test/cases/mount/service-mountpoint.sh
@@ -0,0 +1,36 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# The fuse server names the mount point, so fuservicemount3 has to refuse one
+# that is not on its command line, and one of the wrong file type.
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
+file=$TEST_SRC/file
+
+touch "$file"
+service_setup "test-mntpt-$$"
+
+service_mount "$service_subtype" "$TEST_MNT" mount dir
+_assert_eq "$(service_result mount)" 0 "mount dir on a directory"
+_assert_fstype "$TEST_MNT" "fuse.$service_subtype" fuse
+umount "$TEST_MNT"
+
+service_mount "$service_subtype" "$TEST_MNT" mount-elsewhere "$TEST_SRC"
+_assert_eq "$(service_result mount)" EINVAL \
+	"mount point not on the command line"
+
+service_mount "$service_subtype" "$TEST_MNT" mount file
+_assert_eq "$(service_result mount)" EISDIR "mount file on a directory"
+
+service_mount "$service_subtype" "$file" mount dir
+_assert_eq "$(service_result mount)" ENOTDIR "mount dir on a regular file"
diff --git a/test/cases/mount/service-nonroot.sh b/test/cases/mount/service-nonroot.sh
new file mode 100755
index 000000000000..0c211d0a9965
--- /dev/null
+++ b/test/cases/mount/service-nonroot.sh
@@ -0,0 +1,54 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# fuservicemount3 installed setuid and run by an unprivileged user mounts only
+# on a directory that user can write, and never offers fuseblk.
+
+_fuse_no_mount_needed=1
+. "$TEST_LIB/common.sh"
+
+_require_linux "fuservicemount3"
+# Root installs the setuid copy and the socket
+_require_root
+_require_fuse_device
+_require_binary util/fuservicemount3
+_require_binary test/test_service
+_require_prog setpriv
+_require_prog findmnt
+
+user=nobody
+uid=$(id -u "$user") || _notrun "no user $user"
+gid=$(id -g "$user")
+run_as=(setpriv --reuid="$uid" --regid="$gid" --clear-groups)
+
+helper=$TEST_WORKDIR/fuservicemount3
+case ",$(findmnt -n -o OPTIONS -T "$TEST_WORKDIR")," in
+*,nosuid,*) _notrun "$TEST_WORKDIR is on a nosuid mount" ;;
+esac
+cp "$FUSE_UTIL_DIR/fuservicemount3" "$helper"
+_at_exit "rm -f '$helper'"
+chmod 4755 "$helper"
+"${run_as[@]}" test -x "$helper" || _notrun "$user cannot reach $helper"
+
+. "$TEST_LIB/service.sh"
+
+service_setup "test-nonroot-$$"
+service_helper=("${run_as[@]}" "$helper")
+root_dir=$TEST_WORKDIR/root-mnt
+mkdir -m 0755 "$root_dir"
+
+chown "$uid" "$TEST_MNT"
+service_mount "$service_subtype" "$TEST_MNT" mount dir
+_assert_eq "$(service_result mount)" 0 "mount on a directory $user owns"
+umount "$TEST_MNT"
+
+service_mount "$service_subtype" "$root_dir" mount dir
+_assert_eq "$(service_result mount)" EPERM \
+	"mount on a directory owned by root"
+
+# allow_other depends on user_allow_other in the system fuse.conf
+service_mount "$service_subtype" "$TEST_MNT" caps
+case $(service_result caps) in
+*" fuseblk=0") ;;
+*) _fail "caps as $user: $(service_result caps)" ;;
+esac
diff --git a/test/cases/mount/service-server-exit.sh b/test/cases/mount/service-server-exit.sh
new file mode 100755
index 000000000000..6304f20ff2cb
--- /dev/null
+++ b/test/cases/mount/service-server-exit.sh
@@ -0,0 +1,22 @@
+#!/usr/bin/env bash
+# GROUP: mount
+#
+# A fuse server that exits without a goodbye makes fuservicemount3 fail, and
+# leaves nothing mounted.
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
+service_setup "test-exit-$$"
+
+service_mount "$service_subtype" "$TEST_MNT" exit-early
+_assert_ne "$service_helper_rc" 0 "fuservicemount3 exit status"
+_assert_eq "$(mountinfo_field "$TEST_MNT" fstype)" "" "$TEST_MNT mounted"
diff --git a/test/test_service.c b/test/test_service.c
index 0d54df3427a9..7bbd14e2650d 100644
--- a/test/test_service.c
+++ b/test/test_service.c
@@ -12,6 +12,10 @@
  *   test_service open <path>
  *   test_service open-bdev <path>
  *   test_service open-after-mount <path>
+ *   test_service mount dir|file
+ *   test_service mount-elsewhere <mountpoint>
+ *   test_service caps
+ *   test_service exit-early
  */
 
 #define FUSE_USE_VERSION FUSE_MAKE_VERSION(3, 19)
@@ -62,18 +66,25 @@ static int skip_source(void *data, const char *arg, int key,
 }
 
 /*
- * Mount through the helper so that it has a mount point when the file is
- * requested.
+ * Mount through the helper. On success *sep is the mounted session, which
+ * keeps /dev/fuse open until it is destroyed.
  *
- * @return the mounted session, or NULL on failure
+ * @param fmt         mount point type the helper has to find
+ * @param mountpoint  sent in place of the one on the command line, or NULL
+ * @return 0 when the result was printed, -1 otherwise
  */
-static struct fuse_session *session_mounted(struct fuse_service *service,
-					    const char *argv0)
+static int mount_printed(struct fuse_service *service, const char *argv0,
+			 mode_t fmt, const char *mountpoint,
+			 struct fuse_session **sep)
 {
 	struct fuse_args args = FUSE_ARGS_INIT(0, NULL);
 	struct fuse_cmdline_opts opts = { };
-	struct fuse_session *se = NULL;
+	struct fuse_session *se;
 	bool source_seen = false;
+	int printed = -1;
+	int ret;
+
+	*sep = NULL;
 
 	if (fuse_opt_add_arg(&args, argv0) ||
 	    fuse_service_append_args(service, &args) ||
@@ -81,20 +92,30 @@ static struct fuse_session *session_mounted(struct fuse_service *service,
 	    fuse_service_parse_cmdline_opts(&args, &opts))
 		goto out;
 
+	if (mountpoint) {
+		free(opts.mountpoint);
+		opts.mountpoint = strdup(mountpoint);
+		if (!opts.mountpoint)
+			goto out;
+	}
+
 	se = fuse_session_new(&args, &test_service_oper,
 			      sizeof(test_service_oper), NULL);
 	if (!se)
 		goto out;
 
-	if (fuse_service_session_mount(service, se, S_IFDIR, &opts)) {
+	ret = fuse_service_session_mount(service, se, fmt, &opts);
+	if (ret)
 		fuse_session_destroy(se);
-		se = NULL;
-	}
+	else
+		*sep = se;
 
+	printf("mount result: %s\n", errno_name(-ret));
+	printed = 0;
 out:
 	free(opts.mountpoint);
 	fuse_opt_free_args(&args);
-	return se;
+	return printed;
 }
 
 /* @return 0 when the result was printed, negative errno otherwise */
@@ -127,22 +148,40 @@ static int request_printed(const struct fuse_service *service,
 	return 0;
 }
 
+/* @return S_IFDIR or S_IFREG, 0 for an unknown name */
+static mode_t mount_format(const char *name)
+{
+	if (!strcmp(name, "dir"))
+		return S_IFDIR;
+	if (!strcmp(name, "file"))
+		return S_IFREG;
+	return 0;
+}
+
 int main(int argc, char *argv[])
 {
 	struct fuse_service *service = NULL;
 	struct fuse_session *se = NULL;
-	bool blockdev = false;
+	const char *mode;
+	const char *arg;
 	int ret = 1;
 
-	if (argc != 3) {
+	if (argc != 2 && argc != 3) {
 		fprintf(stderr, "usage: %s socket-path <subtype>\n", argv[0]);
 		fprintf(stderr, "       %s open|open-bdev|open-after-mount <path>\n",
 			argv[0]);
+		fprintf(stderr, "       %s mount dir|file\n", argv[0]);
+		fprintf(stderr, "       %s mount-elsewhere <mountpoint>\n",
+			argv[0]);
+		fprintf(stderr, "       %s caps|exit-early\n", argv[0]);
 		return 1;
 	}
+	mode = argv[1];
+	/* argv[argc] is NULL */
+	arg = argv[2];
 
-	if (!strcmp(argv[1], "socket-path")) {
-		printf("%s/%s\n", FUSE_SERVICE_SOCKET_DIR, argv[2]);
+	if (!strcmp(mode, "socket-path") && arg) {
+		printf("%s/%s\n", FUSE_SERVICE_SOCKET_DIR, arg);
 		return 0;
 	}
 
@@ -151,19 +190,36 @@ int main(int argc, char *argv[])
 		return 1;
 	}
 
-	if (!strcmp(argv[1], "open-after-mount")) {
-		se = session_mounted(service, argv[0]);
-		if (!se)
-			goto out;
-	} else if (!strcmp(argv[1], "open-bdev")) {
-		blockdev = true;
-	} else if (strcmp(argv[1], "open")) {
-		fprintf(stderr, "%s: unknown case %s\n", argv[0], argv[1]);
-		goto out;
+	if (!strcmp(mode, "exit-early")) {
+		/* No goodbye, the helper only sees the connection close */
+		fuse_service_destroy(&service);
+		return 0;
 	}
 
-	if (request_printed(service, argv[2], blockdev))
+	if (!strcmp(mode, "caps")) {
+		printf("caps result: allow_other=%d fuseblk=%d\n",
+		       fuse_service_can_allow_other(service),
+		       fuse_service_can_fuseblk(service));
+	} else if (!strcmp(mode, "mount") && arg && mount_format(arg)) {
+		if (mount_printed(service, argv[0], mount_format(arg), NULL,
+				  &se))
+			goto out;
+	} else if (!strcmp(mode, "mount-elsewhere") && arg) {
+		if (mount_printed(service, argv[0], S_IFDIR, arg, &se))
+			goto out;
+	} else if (!strcmp(mode, "open-after-mount") && arg) {
+		if (mount_printed(service, argv[0], S_IFDIR, NULL, &se) || !se)
+			goto out;
+		if (request_printed(service, arg, false))
+			goto out;
+	} else if ((!strcmp(mode, "open") || !strcmp(mode, "open-bdev")) &&
+		   arg) {
+		if (request_printed(service, arg, !strcmp(mode, "open-bdev")))
+			goto out;
+	} else {
+		fprintf(stderr, "%s: unknown case %s\n", argv[0], mode);
 		goto out;
+	}
 
 	ret = 0;
 out:

-- 
2.53.0

