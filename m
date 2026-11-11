From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 11 Nov 2026 13:54:47 +0900
Subject: [PATCH 2/2] selftests/landlock: Test a long executable path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261111-landlock-long-exe-v1-2-588cfd174a10@samsung.com>
References: <20261111-landlock-long-exe-v1-0-588cfd174a10@samsung.com>
In-Reply-To: <20261111-landlock-long-exe-v1-0-588cfd174a10@samsung.com>
To: =?utf-8?q?Micka=C3=ABl_Sala=C3=BCn?= <mic@digikod.net>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack@google.com>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Shuah Khan <shuah@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Dwi Siswanto <me@dw1.io>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack3000@gmail.com>, 
 linux-security-module@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372885; l=7022;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=OzirVeOJ89jJbafOPbrUGRVzZRXpHwdq0W6i1jQaubY=;
 b=ZuA0YAHqz1FopWQX/rsBhX6+b2xW9oOTLvIIrhAwJdXNEVlkgZ5f2uzhnEkvWzTxzGhs91J67
 jdAp/MQtlWqAP/ngeHzoyXQ5YSnJK2WqJ4y8sBuzr1ERW3/vnQPNt8C
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two tests that execute a copy of wait-pipe-sandbox from a path
longer than LANDLOCK_PATH_MAX_SIZE. layout0.long_exe_path checks,
without audit, that the copy can sandbox itself.
audit_layout0.long_exe_path also checks that the copy's domain records
show exe="<too_long>".

Without the get_current_exe() fix, landlock_restrict_self() fails there
with -ENAMETOOLONG.

Also name the right test in the header of wait-pipe-sandbox.c.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 tools/testing/selftests/landlock/fs_test.c         | 175 +++++++++++++++++++++
 .../testing/selftests/landlock/wait-pipe-sandbox.c |   3 +-
 2 files changed, 177 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/landlock/fs_test.c b/tools/testing/selftests/landlock/fs_test.c
index f725882fa4a7..738a7175d94c 100644
--- a/tools/testing/selftests/landlock/fs_test.c
+++ b/tools/testing/selftests/landlock/fs_test.c
@@ -8013,6 +8013,181 @@ TEST_F(audit_layout1, mount)
 	EXPECT_EQ(1, records.domain);
 }
 
+/*
+ * Executes a copy of bin_wait_pipe_sandbox from a path which does not fit in
+ * the kernel buffer for the executable path, and checks that this copy can
+ * sandbox itself. Returns the PID of this copy, once it has exited.
+ */
+static pid_t test_long_exe_path(struct __test_metadata *const _metadata)
+{
+	int pipe_child[2], pipe_parent[2];
+	char name[NAME_MAX + 1];
+	int dir_fd, status, i;
+	char buf_parent;
+	pid_t child;
+
+	/*
+	 * Creates nested directories whose path (17 * 256 bytes) is longer
+	 * than the kernel buffer for the executable path (PATH_MAX + 11
+	 * bytes), whatever the current directory is.
+	 */
+	memset(name, 'd', sizeof(name) - 1);
+	name[sizeof(name) - 1] = '\0';
+	dir_fd = open(TMP_DIR, O_PATH | O_DIRECTORY | O_CLOEXEC);
+	ASSERT_LE(0, dir_fd);
+	for (i = 0; i <= PATH_MAX / sizeof(name); i++) {
+		int fd;
+
+		ASSERT_EQ(0, mkdirat(dir_fd, name, 0700));
+		fd = openat(dir_fd, name, O_PATH | O_DIRECTORY | O_CLOEXEC);
+		ASSERT_LE(0, fd);
+		EXPECT_EQ(0, close(dir_fd));
+		dir_fd = fd;
+	}
+
+	/* Copies bin_wait_pipe_sandbox to the last directory. */
+	create_file(_metadata, TMP_DIR "/f");
+	copy_file(_metadata, bin_wait_pipe_sandbox, TMP_DIR "/f");
+	ASSERT_EQ(0, renameat(AT_FDCWD, TMP_DIR "/f", dir_fd, "f"));
+
+	ASSERT_EQ(0, pipe2(pipe_child, 0));
+	ASSERT_EQ(0, pipe2(pipe_parent, 0));
+
+	child = fork();
+	ASSERT_LE(0, child);
+	if (child == 0) {
+		const struct landlock_ruleset_attr layer1 = {
+			.scoped = LANDLOCK_SCOPE_SIGNAL,
+		};
+		char pipe_child_str[12], pipe_parent_str[12];
+		char *const argv[] = { "f", pipe_child_str, pipe_parent_str,
+				       NULL };
+
+		/* Passes the pipe FDs to the executed binary. */
+		EXPECT_EQ(0, close(pipe_child[0]));
+		EXPECT_EQ(0, close(pipe_parent[1]));
+		snprintf(pipe_child_str, sizeof(pipe_child_str), "%d",
+			 pipe_child[1]);
+		snprintf(pipe_parent_str, sizeof(pipe_parent_str), "%d",
+			 pipe_parent[0]);
+
+		/* The executed binary expects that it cannot send signals. */
+		drop_access_rights(_metadata, &layer1);
+
+		ASSERT_EQ(0, sys_execveat(dir_fd, argv[0], argv, NULL, 0))
+		{
+			TH_LOG("Failed to execute \"%s\": %s", argv[0],
+			       strerror(errno));
+		};
+		_exit(1);
+	}
+
+	EXPECT_EQ(0, close(pipe_child[1]));
+	EXPECT_EQ(0, close(pipe_parent[0]));
+	EXPECT_EQ(0, close(dir_fd));
+
+	/*
+	 * Goes through the three steps of the executed binary: it tries to
+	 * send a signal, sandboxes itself and tries to open a directory, then
+	 * sandboxes itself again and exits.
+	 */
+	for (i = 0; i < 3; i++) {
+		ASSERT_EQ(1, read(pipe_child[0], &buf_parent, 1))
+		{
+			/*
+			 * The child exits when a step fails. Reaps it before
+			 * the teardown, which may fail to unmount TMP_DIR
+			 * while the child still uses it.
+			 */
+			close(pipe_parent[1]);
+			waitpid(child, &status, 0);
+		}
+		ASSERT_EQ(1, write(pipe_parent[1], ".", 1));
+	}
+
+	EXPECT_EQ(0, close(pipe_parent[1]));
+	EXPECT_EQ(0, close(pipe_child[0]));
+	ASSERT_EQ(child, waitpid(child, &status, 0));
+	ASSERT_EQ(1, WIFEXITED(status));
+	EXPECT_EQ(0, WEXITSTATUS(status));
+
+	return child;
+}
+
+/*
+ * Checks that a task can sandbox itself when the path of its executable does
+ * not fit in the kernel buffer.
+ */
+TEST_F(layout0, long_exe_path)
+{
+	test_long_exe_path(_metadata);
+}
+
+static int matches_log_domain_too_long(int audit_fd, pid_t pid)
+{
+	static const char log_template[] = REGEX_LANDLOCK_PREFIX
+		" status=allocated mode=enforcing pid=%d uid=[0-9]\\+"
+		" exe=\"<too_long>\" comm=\"f\"$";
+	char log_match[sizeof(log_template) + 10];
+	int log_match_len;
+
+	log_match_len =
+		snprintf(log_match, sizeof(log_match), log_template, pid);
+	if (log_match_len >= sizeof(log_match))
+		return -E2BIG;
+
+	return audit_match_record(audit_fd, AUDIT_LANDLOCK_DOMAIN, log_match,
+				  NULL);
+}
+
+FIXTURE(audit_layout0)
+{
+	int audit_fd;
+};
+
+FIXTURE_SETUP(audit_layout0)
+{
+	prepare_layout(_metadata);
+
+	/*
+	 * No executable filter: audit_init_with_exe_filter() would only keep
+	 * the records of this test binary, and the path of the executed copy
+	 * is too long for a rule. The test matches its records by PID.
+	 */
+	set_cap(_metadata, CAP_AUDIT_CONTROL);
+	self->audit_fd = audit_init();
+	clear_cap(_metadata, CAP_AUDIT_CONTROL);
+	if (self->audit_fd < 0) {
+		/*
+		 * FIXTURE_TEARDOWN_PARENT() is not called when FIXTURE_SETUP()
+		 * failed, so we need to remove TMP_DIR to avoid cascading
+		 * errors with the next tests.
+		 */
+		cleanup_layout(_metadata);
+	}
+	ASSERT_LE(0, self->audit_fd);
+}
+
+FIXTURE_TEARDOWN_PARENT(audit_layout0)
+{
+	cleanup_layout(_metadata);
+
+	EXPECT_EQ(0, audit_cleanup(-1, NULL));
+}
+
+/*
+ * Checks that the records of the domains created by such a task get a
+ * placeholder instead of the path of its executable.
+ */
+TEST_F(audit_layout0, long_exe_path)
+{
+	const pid_t child = test_long_exe_path(_metadata);
+
+	/* The executed binary created two domains. */
+	EXPECT_EQ(0, matches_log_domain_too_long(self->audit_fd, child));
+	EXPECT_EQ(0, matches_log_domain_too_long(self->audit_fd, child));
+}
+
 static bool debug_quiet_tests;
 
 FIXTURE(audit_quiet_layout1)
diff --git a/tools/testing/selftests/landlock/wait-pipe-sandbox.c b/tools/testing/selftests/landlock/wait-pipe-sandbox.c
index 87dbc9164430..0dfa8e75fc13 100644
--- a/tools/testing/selftests/landlock/wait-pipe-sandbox.c
+++ b/tools/testing/selftests/landlock/wait-pipe-sandbox.c
@@ -2,7 +2,8 @@
 /*
  * Write in a pipe, wait, sandbox itself, test sandboxing, and wait again.
  *
- * Used by audit_exec.flags from audit_test.c
+ * Used by audit_exec.signal_and_open from audit_test.c, and by
+ * layout0.long_exe_path and audit_layout0.long_exe_path from fs_test.c
  *
  * Copyright © 2024-2025 Microsoft Corporation
  */

-- 
2.43.0

