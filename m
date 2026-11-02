From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Mon, 02 Nov 2026 09:36:01 +0700
Subject: [PATCH bpf-next v2] selftests/bpf: Wait for wq callback before
 checking ok_sleepable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-wq-poll-fix-v2-1-48b7d12815b8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6DIBBEf8XsuduARRt76n80HgAX3UTFgrE2x
 n8v4dzjzMu8OSBSYIrwKA4ItHFkP6dQXgqwg557Qu5ShlKUtRSiws8bFz+O6HhHp2qr7p3RTtw
 gLZZAqc62F5jF4Uz7Cm0iA8fVh2++2WTmf42bRIlNY0kZbavGqWc/aR6v1k/Qnuf5A9N5ZsawA
 AAA
X-Change-ID: 20261005-wq-poll-fix-f46c47dbaf03
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793587005; l=2820;
 i=thamrinjonathan@gmail.com; s=20261005; h=from:subject:message-id;
 bh=hj1bolorYbBPrCihpIUsWO5AkHVCWxDBPFRwoFbNmSE=;
 b=2qboYx7ki1e6LqE0lhjhrM98EDBq+eZMEpyS8XxWBLu9Cy712OkJLs6X2eAh+pHcSfsen8tu9
 hnzvV2sXU3eBpNnqYwlHmZ9beozVU9HkH1aam4rdDat+z8buLX+3kiO
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=QU907bIMYty/tEI/iJF2SrD1lqOf/+2B1MI1zwJ5cBw=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261005 with auth_id=1114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wq test fails with ok_sleepable reading 0 instead of 2 as workqueue
callback hasn't executed before check.

This happens as callback runs later on a kworker and 50us isn't always
enough.

Change from 50us sleep to waiting for callback by checking wq_cb_run.
wq_cb_sleepable() now increments wq_cb_run after setting ok_sleepable
and test loops with sched_yield() until wq_cb_run is set before
checking.

Before (usleep(50)): 3 fails out of 5000 runs
Diagnosing issue (usleep(0)): 23 out of 100 runs
After: 0 out of 2000 runs
Tested using vmtest on x86_64, test pinned to one CPU with `yes` load

Link: https://github.com/kernel-patches/vmtest/issues/455
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
Changes in v2:
- Wait for callback via a wq_cb_run flag instead of polling with a
  timeout, similar to test_struct_ops_assoc.c (Kumar)
- Link to v1: https://lore.kernel.org/r/20261005-wq-poll-fix-v1-1-99ce4bac59f4@gmail.com
---
 tools/testing/selftests/bpf/prog_tests/wq.c |  5 +++--
 tools/testing/selftests/bpf/progs/wq.c      | 10 ++++++----
 2 files changed, 9 insertions(+), 6 deletions(-)

diff --git a/tools/testing/selftests/bpf/prog_tests/wq.c b/tools/testing/selftests/bpf/prog_tests/wq.c
index 97926e35aaf2..95ed4b69c0f5 100644
--- a/tools/testing/selftests/bpf/prog_tests/wq.c
+++ b/tools/testing/selftests/bpf/prog_tests/wq.c
@@ -28,8 +28,9 @@ void serial_test_wq(void)
 	ASSERT_OK(err, "test_run");
 	ASSERT_EQ(topts.retval, 0, "test_run");
 
-	usleep(50); /* 10 usecs should be enough, but give it extra */
-
+	/* wait for wq callback to finish */
+	while (!READ_ONCE(wq_skel->bss->wq_cb_run))
+		sched_yield();
 	ASSERT_EQ(wq_skel->bss->ok_sleepable, (1 << 1), "ok_sleepable");
 clean_up:
 	wq__destroy(wq_skel);
diff --git a/tools/testing/selftests/bpf/progs/wq.c b/tools/testing/selftests/bpf/progs/wq.c
index 25be2cd9d42c..8148db35effe 100644
--- a/tools/testing/selftests/bpf/progs/wq.c
+++ b/tools/testing/selftests/bpf/progs/wq.c
@@ -52,6 +52,7 @@ struct {
 
 __u32 ok;
 __u32 ok_sleepable;
+__u32 wq_cb_run;
 
 static int test_elem_callback(void *map, int *key,
 		int (callback_fn)(void *map, int *key, void *value))
@@ -130,11 +131,12 @@ static int wq_cb_sleepable(void *map, int *key, void *value)
 	struct elem *data = (struct elem *)value;
 	int offset = data->ok_offset;
 
-	if (*key != offset)
-		return 0;
+	if (*key == offset) {
+		bpf_kfunc_call_test_sleepable();
+		ok_sleepable |= (1 << offset);
+	}
 
-	bpf_kfunc_call_test_sleepable();
-	ok_sleepable |= (1 << offset);
+	wq_cb_run++;
 	return 0;
 }
 

---
base-commit: a30c772627b2ef4bc715332b1b04938a914556cd
change-id: 20261005-wq-poll-fix-f46c47dbaf03

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

