From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Fri, 06 Nov 2026 10:37:08 +0700
Subject: [PATCH v2 1/2] selftests/bpf: Replace d_path CHECK() with
 ASSERT_*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-dpath-memfd-v2-1-1dc0799b4aa6@gmail.com>
References: <20261106-dpath-memfd-v2-0-1dc0799b4aa6@gmail.com>
In-Reply-To: <20261106-dpath-memfd-v2-0-1dc0799b4aa6@gmail.com>
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793936228; l=6246;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=R8N2L4ICFhJmCn73DM3mrKGFj9EOijoslMwaPUaBX3Y=;
 b=TsEjPFItS5HeJbR9f5SIEGE1XlyNYISOO9KRRIGVCp4+eozLSfkUTujmPy08ZGXJt4G6mDhmo
 V6U6jep2ItsBtm+e30DcLnEOvWhZB0sy7/IY5q6g5DV9kN1i/ueTKgv
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CHECK() macro is deprecated so each call is replaced with
ASSERT_*().

Suggested-by: Andrii Nakryiko <andrii@kernel.org>
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 tools/testing/selftests/bpf/prog_tests/d_path.c | 69 +++++++++----------------
 1 file changed, 24 insertions(+), 45 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/d_path.c b/tools/testing/selftests/bpf/prog_tests/d_path.c
index 7665e1d28a64..b7998606aa98 100644
--- a/tools/testing/selftests/bpf/prog_tests/d_path.c
+++ b/tools/testing/selftests/bpf/prog_tests/d_path.c
@@ -23,8 +23,6 @@
 #endif
 #endif
 
-static int duration;
-
 static struct {
 	__u32 cnt;
 	char paths[MAX_FILES][MAX_PATH_LEN];
@@ -55,48 +53,48 @@ static int trigger_fstat_events(pid_t pid)
 	int ret = -1;
 
 	/* unmountable pseudo-filesystems */
-	if (CHECK(pipe(pipefd) < 0, "trigger", "pipe failed\n"))
+	if (!ASSERT_OK(pipe(pipefd), "pipe"))
 		return ret;
 	/* unmountable pseudo-filesystems */
 	sockfd = socket(AF_INET, SOCK_STREAM, 0);
-	if (CHECK(sockfd < 0, "trigger", "socket failed\n"))
+	if (!ASSERT_OK_FD(sockfd, "socket"))
 		goto out_close;
 	/* mountable pseudo-filesystems */
 	procfd = open("/proc/self/comm", O_RDONLY);
-	if (CHECK(procfd < 0, "trigger", "open /proc/self/comm failed\n"))
+	if (!ASSERT_OK_FD(procfd, "open /proc/self/comm"))
 		goto out_close;
 	devfd = open("/dev/urandom", O_RDONLY);
-	if (CHECK(devfd < 0, "trigger", "open /dev/urandom failed\n"))
+	if (!ASSERT_OK_FD(devfd, "open /dev/urandom"))
 		goto out_close;
 	localfd = open("/tmp/d_path_loadgen.txt", O_CREAT | O_RDONLY, 0644);
-	if (CHECK(localfd < 0, "trigger", "open /tmp/d_path_loadgen.txt failed\n"))
+	if (!ASSERT_OK_FD(localfd, "open /tmp/d_path_loadgen.txt"))
 		goto out_close;
 	/* bpf_d_path will return path with (deleted) */
 	remove("/tmp/d_path_loadgen.txt");
 	indicatorfd = open("/tmp/", O_PATH);
-	if (CHECK(indicatorfd < 0, "trigger", "open /tmp/ failed\n"))
+	if (!ASSERT_OK_FD(indicatorfd, "open /tmp/"))
 		goto out_close;
 
 	ret = set_pathname(pipefd[0], pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for pipe[0]\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for pipe[0]"))
 		goto out_close;
 	ret = set_pathname(pipefd[1], pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for pipe[1]\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for pipe[1]"))
 		goto out_close;
 	ret = set_pathname(sockfd, pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for socket\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for socket"))
 		goto out_close;
 	ret = set_pathname(procfd, pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for proc\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for proc"))
 		goto out_close;
 	ret = set_pathname(devfd, pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for dev\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for dev"))
 		goto out_close;
 	ret = set_pathname(localfd, pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for file\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for file"))
 		goto out_close;
 	ret = set_pathname(indicatorfd, pid);
-	if (CHECK(ret < 0, "trigger", "set_pathname failed for dir\n"))
+	if (!ASSERT_GE(ret, 0, "set_pathname for dir"))
 		goto out_close;
 
 	/* triggers vfs_getattr */
@@ -128,11 +126,11 @@ static void attach_and_load(struct test_d_path **skel)
 	int err;
 
 	*skel = test_d_path__open_and_load();
-	if (CHECK(!*skel, "setup", "d_path skeleton failed\n"))
+	if (!ASSERT_OK_PTR(*skel, "d_path skeleton"))
 		goto cleanup;
 
 	err = test_d_path__attach(*skel);
-	if (CHECK(err, "setup", "attach failed: %d\n", err))
+	if (!ASSERT_OK(err, "attach"))
 		goto cleanup;
 
 	(*skel)->bss->my_pid = getpid();
@@ -159,36 +157,18 @@ static void test_d_path_basic(void)
 	if (err < 0)
 		goto cleanup;
 
-	if (CHECK(!bss->called_stat,
-		  "stat",
-		  "trampoline for security_inode_getattr was not called\n"))
+	if (!ASSERT_TRUE(bss->called_stat, "called_stat"))
 		goto cleanup;
 
-	if (CHECK(!bss->called_close,
-		  "close",
-		  "trampoline for filp_close_sync was not called\n"))
+	if (!ASSERT_TRUE(bss->called_close, "called_close"))
 		goto cleanup;
 
 	for (int i = 0; i < MAX_FILES; i++) {
-		CHECK(strncmp(src.paths[i], bss->paths_stat[i], MAX_PATH_LEN),
-		      "check",
-		      "failed to get stat path[%d]: %s vs %s\n",
-		      i, src.paths[i], bss->paths_stat[i]);
-		CHECK(strncmp(src.paths[i], bss->paths_close[i], MAX_PATH_LEN),
-		      "check",
-		      "failed to get close path[%d]: %s vs %s\n",
-		      i, src.paths[i], bss->paths_close[i]);
+		ASSERT_STRNEQ(bss->paths_stat[i], src.paths[i], MAX_PATH_LEN, "stat path");
+		ASSERT_STRNEQ(bss->paths_close[i], src.paths[i], MAX_PATH_LEN, "close path");
 		/* The d_path helper returns size plus NUL char, hence + 1 */
-		CHECK(bss->rets_stat[i] != strlen(bss->paths_stat[i]) + 1,
-		      "check",
-		      "failed to match stat return [%d]: %d vs %zd [%s]\n",
-		      i, bss->rets_stat[i], strlen(bss->paths_stat[i]) + 1,
-		      bss->paths_stat[i]);
-		CHECK(bss->rets_close[i] != strlen(bss->paths_stat[i]) + 1,
-		      "check",
-		      "failed to match stat return [%d]: %d vs %zd [%s]\n",
-		      i, bss->rets_close[i], strlen(bss->paths_close[i]) + 1,
-		      bss->paths_stat[i]);
+		ASSERT_EQ(bss->rets_stat[i], strlen(bss->paths_stat[i]) + 1, "stat return");
+		ASSERT_EQ(bss->rets_close[i], strlen(bss->paths_stat[i]) + 1, "close return");
 	}
 
 cleanup:
@@ -232,15 +212,14 @@ static void test_d_path_mem_access(void)
 	bss = skel->bss;
 
 	localfd = mkstemp(path_template);
-	if (CHECK(localfd < 0, "trigger", "mkstemp failed\n"))
+	if (!ASSERT_OK_FD(localfd, "mkstemp"))
 		goto cleanup;
 
-	if (CHECK(fallocate(localfd, 0, 0, 1024) < 0, "trigger", "fallocate failed\n"))
+	if (!ASSERT_OK(fallocate(localfd, 0, 0, 1024), "fallocate"))
 		goto cleanup;
 	remove(path_template);
 
-	if (CHECK(!bss->path_match_fallocate, "check",
-		  "failed to read fallocate path"))
+	if (!ASSERT_TRUE(bss->path_match_fallocate, "fallocate path"))
 		goto cleanup;
 
 cleanup:

-- 
2.56.0

