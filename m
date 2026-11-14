From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Sat, 14 Nov 2026 14:34:26 +0700
Subject: [PATCH sched_ext for-7.4-fixes] selftests/sched_ext: Measure
 rt_stall runtime over sleep window only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-scx-rt-stall-v1-1-4188a9378067@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMAwAf6Xk2YgdZRV/RUSyLnWBsUlSRmHs3
 y3z8TjudjBWYYOH20F5E5N1aeAvDtJEy4dRxsbQ3breex/QUkUtaIXmGRP52Ee60xAytOSrnKW
 euydYmnh8cy0ur4rxGvDvXsfxA+cLDU93AAAA
X-Change-ID: 20261114-scx-rt-stall-ca1767a8ab4f
To: Tejun Heo <tj@kernel.org>, David Vernet <void@manifault.com>, 
 Andrea Righi <arighi@nvidia.com>, Changwoo Min <changwoo@igalia.com>, 
 Shuah Khan <shuah@kernel.org>, Joel Fernandes <joelagnelf@nvidia.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 "Peter Zijlstra (Intel)" <peterz@infradead.org>
Cc: sched-ext@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Cheng-Yang Chou <yphbchou0911@gmail.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794641691; l=3171;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=64ICNfU8iUX1UX4sbMTXozzlz4bDJsKLO9wf23ALotc=;
 b=7es2OxIPB/1qY7wtNWGRVEsLn9zmcDTLh5smtHVSoGjQ0sjYgYAWKrh4J2Ie0dTzNFlcQWw7G
 mKc8sNLNOnfD3v3wSuqake8zPPoh17U4mrikPpmFcwO7CyBcCkARc4u
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In sched_stress_test(), the parent can be slow to start as it has
to wait for the DL server before reaching sleep() while the RT task
still runs. The runtime of each task is read as a total since fork
instead of during sleep(). This adds extra time to RT and makes the
ratio inaccurate which causes flaky failures on CI.

With the parent pinned to CORE_ID, the RT task had already run for
~0.95s before sleep(), so it was measured at 5.69s in a 5s window and
the EXT share dropped to ~4.2% against the 4% threshold. CI has seen
3.0-3.9%.

Measure CPU time right before calling sleep() and use deltas to get
an accurate measurement window. With the parent pinned to CORE_ID, RT
measures 4.75s and EXT share stays between 4.81% and 5.57% over 20
runs.

Fixes: be621a76341c ("selftests/sched_ext: Add test for sched_ext dl_server")
Link: https://github.com/kernel-patches/vmtest/issues/458
Cc: Ihor Solodrai <ihor.solodrai@linux.dev>
Cc: Cheng-Yang Chou <yphbchou0911@gmail.com>
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 tools/testing/selftests/sched_ext/rt_stall.c | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/sched_ext/rt_stall.c b/tools/testing/selftests/sched_ext/rt_stall.c
index a1552b38a6e8..0c6403d25298 100644
--- a/tools/testing/selftests/sched_ext/rt_stall.c
+++ b/tools/testing/selftests/sched_ext/rt_stall.c
@@ -149,7 +149,7 @@ static bool sched_stress_test(bool is_ext)
 	const float expected_min_ratio = 0.04; /* 4% */
 	const char *class_str = is_ext ? "EXT" : "FAIR";
 
-	float ext_runtime, rt_runtime, actual_ratio;
+	float ext_runtime_start, rt_runtime_start, ext_runtime, rt_runtime, actual_ratio;
 	int ext_pid, rt_pid;
 	int ext_ready[2], rt_ready[2];
 	bool ret = false;
@@ -201,6 +201,23 @@ static bool sched_stress_test(bool is_ext)
 	if (!wait_ready(ext_ready[0]) || !wait_ready(rt_ready[0]))
 		goto out_kill;
 
+	/*
+	 * The parent can be delayed before reaching sleep(). Record each task's
+	 * CPU time right before calling sleep() so only time used during the
+	 * measurement window is counted.
+	 */
+	ext_runtime_start = get_process_runtime(ext_pid);
+	if (ext_runtime_start == -1) {
+		fprintf(stderr, "Failed to read %s task runtime\n", class_str);
+		goto out_kill;
+	}
+
+	rt_runtime_start = get_process_runtime(rt_pid);
+	if (rt_runtime_start == -1) {
+		fprintf(stderr, "Failed to read RT task runtime\n");
+		goto out_kill;
+	}
+
 	/* Let the processes run for the specified time */
 	sleep(RUN_TIME);
 
@@ -218,6 +235,8 @@ static bool sched_stress_test(bool is_ext)
 		goto out_kill;
 	}
 
+	ext_runtime = ext_runtime - ext_runtime_start;
+	rt_runtime = rt_runtime - rt_runtime_start;
 	/* Verify that the scx task got enough runtime */
 	actual_ratio = ext_runtime / (ext_runtime + rt_runtime);
 	fprintf(stderr, "%s task ran %.3fs, RT task ran %.3fs (%.2f%% of runtime)\n",

---
base-commit: 0021f17128de5dc0b19f1a523f448df2440d8088
change-id: 20261114-scx-rt-stall-ca1767a8ab4f

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

