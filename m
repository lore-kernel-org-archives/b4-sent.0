From: Mayank Rungta <mrungta@google.com>
Date: Thu, 12 Feb 2026 14:12:12 -0700
Subject: [PATCH 3/4] watchdog/hardlockup: improve buddy system detection
 timeliness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260212-hardlockup-watchdog-fixes-v1-3-745f1dce04c3@google.com>
References: <20260212-hardlockup-watchdog-fixes-v1-0-745f1dce04c3@google.com>
In-Reply-To: <20260212-hardlockup-watchdog-fixes-v1-0-745f1dce04c3@google.com>
To: Jonathan Corbet <corbet@lwn.net>, Petr Mladek <pmladek@suse.com>, 
 Jinchao Wang <wangjinchao600@gmail.com>, 
 Yunhui Cui <cuiyunhui@bytedance.com>, Stephane Eranian <eranian@google.com>, 
 Ian Rogers <irogers@google.com>, Li Huafei <lihuafei1@huawei.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, 
 Max Kellermann <max.kellermann@ionos.com>, Jonathan Corbet <corbet@lwn.net>, 
 Douglas Anderson <dianders@chromium.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770930732; l=4597;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=u/DAjpi2f2lGgrbnQjjFY9XiKDSfKSESiWB7qXT8xhI=;
 b=KpTEJDqImE50mOTCS0QDfLkUhHr5Bd19Yb12yj8rRfQsM0Swv2jtD6wS3WgsKfy+xBK/RaEeb
 PSgEkKo+5YjCh9Kh6giYxa+0RxYt8XDUuAQdC5vO/7sPyIS5SjZTKoO
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the buddy system only performs checks every 3rd sample. With
a 4-second interval. If a check window is missed, the next check occurs
12 seconds later, potentially delaying hard lockup detection for up to
24 seconds.

Modify the buddy system to perform checks at every interval (4s).
Introduce a missed-interrupt threshold to maintain the existing grace
period while reducing the detection window to 8-12 seconds.

Best and worst case detection scenarios:

Before (12s check window):
- Best case: Lockup occurs after first check but just before heartbeat
  interval. Detected in ~8s (8s till next check).
- Worst case: Lockup occurs just after a check.
  Detected in ~24s (missed check + 12s till next check + 12s logic).

After (4s check window with threshold of 3):
- Best case: Lockup occurs just before a check.
  Detected in ~8s (0s till 1st check + 4s till 2nd + 4s till 3rd).
- Worst case: Lockup occurs just after a check.
  Detected in ~12s (4s till 1st check + 4s till 2nd + 4s till 3rd).

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 include/linux/nmi.h     |  1 +
 kernel/watchdog.c       | 18 ++++++++++++++++--
 kernel/watchdog_buddy.c |  9 +--------
 3 files changed, 18 insertions(+), 10 deletions(-)

diff --git a/include/linux/nmi.h b/include/linux/nmi.h
index 207156f2143c5f43e89e81cbf0215331eae9bd49..bc1162895f3558bff178dd6c2c839344162f8adc 100644
--- a/include/linux/nmi.h
+++ b/include/linux/nmi.h
@@ -21,6 +21,7 @@ void lockup_detector_soft_poweroff(void);
 extern int watchdog_user_enabled;
 extern int watchdog_thresh;
 extern unsigned long watchdog_enabled;
+extern int watchdog_hardlockup_miss_thresh;
 
 extern struct cpumask watchdog_cpumask;
 extern unsigned long *watchdog_cpumask_bits;
diff --git a/kernel/watchdog.c b/kernel/watchdog.c
index b71aa814edcf9ad8f73644eb5bcd1eeb3264e4ed..30199eaeb5d7e0fd229657a31ffff4463c97332c 100644
--- a/kernel/watchdog.c
+++ b/kernel/watchdog.c
@@ -60,6 +60,13 @@ unsigned long *watchdog_cpumask_bits = cpumask_bits(&watchdog_cpumask);
 int __read_mostly sysctl_hardlockup_all_cpu_backtrace;
 # endif /* CONFIG_SMP */
 
+/*
+ * Number of consecutive missed interrupts before declaring a lockup.
+ * Default to 1 (immediate) for NMI/Perf. Buddy will overwrite this to 3.
+ */
+int __read_mostly watchdog_hardlockup_miss_thresh = 1;
+EXPORT_SYMBOL_GPL(watchdog_hardlockup_miss_thresh);
+
 /*
  * Should we panic when a soft-lockup or hard-lockup occurs:
  */
@@ -137,6 +144,7 @@ __setup("nmi_watchdog=", hardlockup_panic_setup);
 
 static DEFINE_PER_CPU(atomic_t, hrtimer_interrupts);
 static DEFINE_PER_CPU(int, hrtimer_interrupts_saved);
+static DEFINE_PER_CPU(int, hrtimer_interrupts_missed);
 static DEFINE_PER_CPU(bool, watchdog_hardlockup_warned);
 static DEFINE_PER_CPU(bool, watchdog_hardlockup_touched);
 static unsigned long hard_lockup_nmi_warn;
@@ -163,8 +171,13 @@ static bool is_hardlockup(unsigned int cpu)
 {
 	int hrint = atomic_read(&per_cpu(hrtimer_interrupts, cpu));
 
-	if (per_cpu(hrtimer_interrupts_saved, cpu) == hrint)
-		return true;
+	if (per_cpu(hrtimer_interrupts_saved, cpu) == hrint) {
+		per_cpu(hrtimer_interrupts_missed, cpu)++;
+		if (per_cpu(hrtimer_interrupts_missed, cpu) >= watchdog_hardlockup_miss_thresh)
+			return true;
+
+		return false;
+	}
 
 	/*
 	 * NOTE: we don't need any fancy atomic_t or READ_ONCE/WRITE_ONCE
@@ -172,6 +185,7 @@ static bool is_hardlockup(unsigned int cpu)
 	 * written/read by a single CPU.
 	 */
 	per_cpu(hrtimer_interrupts_saved, cpu) = hrint;
+	per_cpu(hrtimer_interrupts_missed, cpu) = 0;
 
 	return false;
 }
diff --git a/kernel/watchdog_buddy.c b/kernel/watchdog_buddy.c
index ee754d767c2131e3cd34bccf26d8e6cf0e0b5f75..3a1e57080c1c6a645c974b3b6eebec87df9e69e9 100644
--- a/kernel/watchdog_buddy.c
+++ b/kernel/watchdog_buddy.c
@@ -21,6 +21,7 @@ static unsigned int watchdog_next_cpu(unsigned int cpu)
 
 int __init watchdog_hardlockup_probe(void)
 {
+	watchdog_hardlockup_miss_thresh = 3;
 	return 0;
 }
 
@@ -86,14 +87,6 @@ void watchdog_buddy_check_hardlockup(int hrtimer_interrupts)
 {
 	unsigned int next_cpu;
 
-	/*
-	 * Test for hardlockups every 3 samples. The sample period is
-	 *  watchdog_thresh * 2 / 5, so 3 samples gets us back to slightly over
-	 *  watchdog_thresh (over by 20%).
-	 */
-	if (hrtimer_interrupts % 3 != 0)
-		return;
-
 	/* check for a hardlockup on the next CPU */
 	next_cpu = watchdog_next_cpu(smp_processor_id());
 	if (next_cpu >= nr_cpu_ids)

-- 
2.53.0.273.g2a3d683680-goog

