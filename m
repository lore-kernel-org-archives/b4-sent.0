From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Tue, 03 Nov 2026 10:21:38 +0700
Subject: [PATCH bpf-next v3] selftests/bpf: Wait for wq callback before
 checking ok_sleepable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-wq-poll-fix-v3-1-8e7b38f5e71f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMyw6CMBBFf4XM2jF0eIis/A/jopQpNKEPW4Ikh
 H+3ce/y3JtzDkgcDSfoiwMibyYZ7zJUlwLULN3EaMbMQCW1QpSEnzcGvyyozY5c3UvSddsIUpC
 NEDnPv9oThqDR8b7CKz86eovrHFn+r22EAutuuI2COtEM3WOy0ixX5S2c5xdF++irqgAAAA==
X-Change-ID: 20261102-wq-poll-fix-e3902f46512c
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mykyta Yatsenko <yatsenko@meta.com>, 
 qikeyu2017@gmail.com, Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793676107; l=2995;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=gdSS2Zn2Y724+t41UF0QYn1E1bwWRv+MZqExp9d0kLM=;
 b=QzNXJ7/3tjFJT5uXYRsgG7/N2lQpdIxxXgJv9b0ADpCMIAvmXMqkrG42t3cHQktY4J/fsTYVt
 5n6orF1dTy2DiuipA0JGB0f3bFXXaB5keaFRN1GBXIoxOlG7SWuYXZL
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wq test fails with ok_sleepable reading 0 instead of 2 as workqueue
callback hasn't executed before check.

This happens as callback runs later on a kworker and 50us isn't always
enough.

Change from 50us sleep to waiting for callback by polling
ok_sleepable every 1ms for up to 10s. If the callback never runs, the
test fails instead of hanging, similar to ksock_wq.c. If test_run
fails, it skips the wait and goes to clean_up since the callback
was never queued.

Before (usleep(50)): 3 fails out of 5000 runs
Diagnosing issue (usleep(0)): 23 out of 100 runs
After: 0 out of 2000 runs
Tested using vmtest on x86_64, test pinned to one CPU with `yes` load

Link: https://github.com/kernel-patches/vmtest/issues/455
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
Changes in v3:
- Go back to bounded polling on ok_sleepable, similar to
  ksock_wq.c, as unbounded wait in v2 can hang if callback never
  runs (Alexei)
- Skip the wait if test_run fails, and raise limit to 10s (Alexei)
- Drop the wq_cb_run flag and the progs/wq.c changes
- Link to v2: https://lore.kernel.org/r/20261102-wq-poll-fix-v2-1-48b7d12815b8@gmail.com

Changes in v2:
- Wait for callback via a wq_cb_run flag instead of polling with a
  timeout, similar to test_struct_ops_assoc.c (Kumar)
- Link to v1: https://lore.kernel.org/r/20261005-wq-poll-fix-v1-1-99ce4bac59f4@gmail.com
---
 tools/testing/selftests/bpf/prog_tests/wq.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/wq.c b/tools/testing/selftests/bpf/prog_tests/wq.c
index 97926e35aaf2..a4f71bc34fa6 100644
--- a/tools/testing/selftests/bpf/prog_tests/wq.c
+++ b/tools/testing/selftests/bpf/prog_tests/wq.c
@@ -4,10 +4,13 @@
 #include "wq.skel.h"
 #include "wq_failures.skel.h"
 
+#define CALLBACK_WAIT_RETRIES 10000
+#define CALLBACK_WAIT_US 1000
+
 void serial_test_wq(void)
 {
 	struct wq *wq_skel = NULL;
-	int err, prog_fd;
+	int err, prog_fd, i;
 
 	LIBBPF_OPTS(bpf_test_run_opts, topts);
 
@@ -25,11 +28,12 @@ void serial_test_wq(void)
 
 	prog_fd = bpf_program__fd(wq_skel->progs.test_syscall_array_sleepable);
 	err = bpf_prog_test_run_opts(prog_fd, &topts);
-	ASSERT_OK(err, "test_run");
-	ASSERT_EQ(topts.retval, 0, "test_run");
-
-	usleep(50); /* 10 usecs should be enough, but give it extra */
+	if (!ASSERT_OK(err, "test_run") || !ASSERT_EQ(topts.retval, 0, "test_run"))
+		goto clean_up;
 
+	/* wait for wq callback to finish and fail instead of hanging if it never runs */
+	for (i = 0; i < CALLBACK_WAIT_RETRIES && !READ_ONCE(wq_skel->bss->ok_sleepable); i++)
+		usleep(CALLBACK_WAIT_US);
 	ASSERT_EQ(wq_skel->bss->ok_sleepable, (1 << 1), "ok_sleepable");
 clean_up:
 	wq__destroy(wq_skel);

---
base-commit: cd5bc55288d4fd999595c8f2af6a5408cbe92a52
change-id: 20261102-wq-poll-fix-e3902f46512c

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

