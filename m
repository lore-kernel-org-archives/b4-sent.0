From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Mon, 16 Nov 2026 01:10:10 +0700
Subject: [PATCH sched_ext for-7.4-fixes v3] selftests/sched_ext: Reduce
 rt_stall measurement noise
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-scx-rt-stall-v3-1-8dd2d150c4aa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22N0QqDIBiFXyW83h/95tTtau8xxjCzEiqHSjSid
 5+4mxi7/DjnO2cjwXhrArkWG/FmscG6OUF9Koge1NwbsG1iQivKEZFB0Cv4CCGqcQStUHChpGp
 YR5Ly8qaza567k6AH0z7NGovOeRAlg2/2SMXBhuj8O98umOv/HxYEBIZSqkstZMXFrZ+UHUvtp
 jy00KN8/pFpki+UcyEbikzzo7zv+wfN417d/gAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794766228; l=8589;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=6uCViknxMn4SrDjPmOXFqAYya15FnrezGCtK+2yoHMA=;
 b=NfCYDx534xD9205/wu4rNGlvRVc2Bf5eZ4Lq1VR2ZeAl0t2tPKi2fFUuysgCNH77SKBt9WpQu
 MKvwgtKOJi5BMY9sdDU3eea/TXT3dN4A/pKDoJnYQ4smEVqPpWR43/6
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In sched_stress_test(), the DL server budget on CORE_ID is shared with
other FAIR/EXT tasks, including the parent task when unpinned. The
parent can also be slow to start as it has to wait for the DL server
before reaching sleep() while the RT task still runs. The runtime of
each task is read as a total since fork instead of during sleep() and
is measured in USER_HZ units (10ms). These 3 factors add noise to the
measurement and contribute to the CI flakes. An EXT task got as little
as ~0.18s on CI, which is a 3.0-3.9% share against a minimum 4%.

With the parent pinned to CORE_ID, the RT task had already run for
~0.95s before sleep(), so it was measured at 5.69s in a 5s window and
the EXT share dropped to ~4.2% against the 4% threshold.

Measure CPU time using per-task CPU clocks via clock_getcpuclockid()
with deltas before and after sleep to get an accurate measurement
window while also pinning the parent off CORE_ID. With the parent
pinned to another CPU, RT measures ~4.75s and EXT share stays between
4.86% and 5.10% over 20 runs.

Per-CPU kthreads on CORE_ID can still consume part of the DL server
budget, so this reduces the measurement noise rather than fully fixing
the flakes. The threshold can be lowered later if they persist to
account for this.

Fixes: be621a76341c ("selftests/sched_ext: Add test for sched_ext dl_server")
Link: https://github.com/kernel-patches/vmtest/issues/458
Suggested-by: Andrea Righi <arighi@nvidia.com>
Reviewed-by: Andrea Righi <arighi@nvidia.com>
Cc: Ihor Solodrai <ihor.solodrai@linux.dev>
Cc: Cheng-Yang Chou <yphbchou0911@gmail.com>
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
Hi Andrea, thanks for the quick response! As a possible follow-up for
the kthread noise, I have an idea to change the test to check the RT
task's share of a wall-clock window instead since kthreads wouldn't
affect this check. I'd assert that RT's CPU time <=96% (or <=97% to
allow for the 5s window not aligning with the 1s server period) of
the window as the main check and that the EXT/FAIR task's CPU time
is above a low floor (1-3%) to check that it hasn't stalled. The big
problem with this would be steal time as it would inflate the window
and could hide a broken server. We could subtract the steal time from
the window using /proc/stat but it's only accurate to 10 ms. Would
this be a valid solution and is it worth a follow-up patch?

Changes in v3:
- Reword commit to reduce measurement noise rather than fix flakes
  (Andrea)
- Add comment on DL server budget being shared with other EXT/FAIR
  tasks on CORE_ID (Andrea)
- Link to v2: https://lore.kernel.org/r/20261115-scx-rt-stall-v2-1-926678b214c6@gmail.com

Changes in v2:
- Read CPU time with clock_getcpuclockid() and clock_gettime() instead of
  /proc/<pid>/stat to avoid USER_HZ rounding (Andrea)
- Pin parent off CORE_ID so it doesn't share DL server budget (Andrea)
- Threshold unchanged: 4.86-5.10% over 20 runs, but was unable to 
  reproduce kthreads noise similar to CI, happy to lower threshold to 3%
  if needed
- Link to v1: https://lore.kernel.org/r/20261114-scx-rt-stall-v1-1-4188a9378067@gmail.com
---
 tools/testing/selftests/sched_ext/rt_stall.c | 92 +++++++++++++++++++++-------
 1 file changed, 69 insertions(+), 23 deletions(-)

diff --git a/tools/testing/selftests/sched_ext/rt_stall.c b/tools/testing/selftests/sched_ext/rt_stall.c
index a1552b38a6e8..7be801b1fa2b 100644
--- a/tools/testing/selftests/sched_ext/rt_stall.c
+++ b/tools/testing/selftests/sched_ext/rt_stall.c
@@ -21,6 +21,9 @@
 #define CORE_ID		0	/* CPU to pin tasks to */
 #define RUN_TIME        5	/* How long to run the test in seconds */
 
+static cpu_set_t old_mask;
+static bool affinity_saved;
+
 /* Signal the parent that setup is complete by writing to a pipe */
 static void signal_ready(int fd)
 {
@@ -82,43 +85,57 @@ static void set_sched(int policy, int priority)
 	}
 }
 
-/* Get process runtime from /proc/<pid>/stat */
+/* Get process runtime from CPU clock */
 static float get_process_runtime(int pid)
 {
-	char path[256];
-	FILE *file;
-	long utime, stime;
-	int fields;
-
-	snprintf(path, sizeof(path), "/proc/%d/stat", pid);
-	file = fopen(path, "r");
-	if (file == NULL) {
-		perror("Failed to open stat file");
+	clockid_t clk;
+	struct timespec ts;
+	int err;
+
+	err = clock_getcpuclockid(pid, &clk);
+	if (err) {
+		fprintf(stderr, "Failed to get clock ID: %s\n", strerror(err));
+		return -1;
+	}
+
+	if (clock_gettime(clk, &ts) == -1) {
+		perror("Failed to get clock time");
 		return -1;
 	}
 
-	/* Skip the first 13 fields and read the 14th and 15th */
-	fields = fscanf(file,
-			"%*d %*s %*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %lu %lu",
-			&utime, &stime);
-	fclose(file);
+	return ts.tv_sec + ts.tv_nsec / 1e9;
+}
 
-	if (fields != 2) {
-		fprintf(stderr, "Failed to read stat file\n");
+/* Move parent off of CORE_ID so it doesn't share DL server budget */
+static int pin_parent_off_core(void)
+{
+	if (sched_getaffinity(0, sizeof(old_mask), &old_mask) != 0) {
+		perror("sched_getaffinity");
 		return -1;
 	}
 
-	/* Calculate the total time spent in the process */
-	long total_time = utime + stime;
-	long ticks_per_second = sysconf(_SC_CLK_TCK);
-	float runtime_seconds = total_time * 1.0 / ticks_per_second;
+	for (int cpu = 0; cpu < CPU_SETSIZE; cpu++) {
+		if (CPU_ISSET(cpu, &old_mask) && cpu != CORE_ID) {
+			cpu_set_t mask;
+
+			CPU_ZERO(&mask);
+			CPU_SET(cpu, &mask);
+			if (sched_setaffinity(0, sizeof(mask), &mask)) {
+				perror("sched_setaffinity");
+				return -1;
+			}
+			affinity_saved = true;
+			return 0;
+		}
+	}
 
-	return runtime_seconds;
+	return 1; /* No other CPU available */
 }
 
 static enum scx_test_status setup(void **ctx)
 {
 	struct rt_stall *skel;
+	int err;
 
 	if (!__COMPAT_struct_has_field("rq", "ext_server")) {
 		fprintf(stderr, "SKIP: ext DL server not supported\n");
@@ -132,6 +149,9 @@ static enum scx_test_status setup(void **ctx)
 
 	*ctx = skel;
 
+	err = pin_parent_off_core();
+	SCX_FAIL_IF(err == -1, "Failed to pin parent CPU");
+
 	return SCX_TEST_PASS;
 }
 
@@ -145,11 +165,15 @@ static bool sched_stress_test(bool is_ext)
 	 * that the EXT deadline server is working correctly. A percentage
 	 * less than 4% indicates a bug where RT tasks can potentially
 	 * stall SCHED_EXT tasks, causing the test to fail.
+	 *
+	 * The DL server budget is per-CPU and shared with all other
+	 * EXT/FAIR tasks on CORE_ID (e.g., kthreads, ksoftirqd). The EXT
+	 * task may get slightly less than 5% on a noisy system due to this.
 	 */
 	const float expected_min_ratio = 0.04; /* 4% */
 	const char *class_str = is_ext ? "EXT" : "FAIR";
 
-	float ext_runtime, rt_runtime, actual_ratio;
+	float ext_runtime_start, rt_runtime_start, ext_runtime, rt_runtime, actual_ratio;
 	int ext_pid, rt_pid;
 	int ext_ready[2], rt_ready[2];
 	bool ret = false;
@@ -201,6 +225,23 @@ static bool sched_stress_test(bool is_ext)
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
 
@@ -218,6 +259,8 @@ static bool sched_stress_test(bool is_ext)
 		goto out_kill;
 	}
 
+	ext_runtime = ext_runtime - ext_runtime_start;
+	rt_runtime = rt_runtime - rt_runtime_start;
 	/* Verify that the scx task got enough runtime */
 	actual_ratio = ext_runtime / (ext_runtime + rt_runtime);
 	fprintf(stderr, "%s task ran %.3fs, RT task ran %.3fs (%.2f%% of runtime)\n",
@@ -284,6 +327,9 @@ static void cleanup(void *ctx)
 {
 	struct rt_stall *skel = ctx;
 
+	if (affinity_saved)
+		sched_setaffinity(0, sizeof(old_mask), &old_mask);
+
 	rt_stall__destroy(skel);
 }
 

---
base-commit: 0021f17128de5dc0b19f1a523f448df2440d8088
change-id: 20261114-scx-rt-stall-ca1767a8ab4f

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

