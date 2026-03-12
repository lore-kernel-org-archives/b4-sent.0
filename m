From: Mayank Rungta <mrungta@google.com>
Date: Thu, 12 Mar 2026 16:22:05 -0700
Subject: [PATCH v2 4/5] watchdog/hardlockup: improve buddy system detection
 timeliness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-hardlockup-watchdog-fixes-v2-4-45bd8a0cc7ed@google.com>
References: <20260312-hardlockup-watchdog-fixes-v2-0-45bd8a0cc7ed@google.com>
In-Reply-To: <20260312-hardlockup-watchdog-fixes-v2-0-45bd8a0cc7ed@google.com>
To: Petr Mladek <pmladek@suse.com>, Jinchao Wang <wangjinchao600@gmail.com>, 
 Yunhui Cui <cuiyunhui@bytedance.com>, Stephane Eranian <eranian@google.com>, 
 Ian Rogers <irogers@google.com>, Li Huafei <lihuafei1@huawei.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, 
 Max Kellermann <max.kellermann@ionos.com>, Jonathan Corbet <corbet@lwn.net>, 
 Douglas Anderson <dianders@chromium.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Florian Delizy <fdelizy@google.com>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773357752; l=5127;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=5wYvVIHfFCgN5ygcPFtvVUMvQnV/JrQ6DexOgbq9zes=;
 b=Ve4A5fVpXCjy0qR9OOgYTqE82VOOLfn2r8KcluiT8/2Cov4UiiiRegO9i3eZdiUXoCJdtOIim
 fATQ3YWZMPRA2wEEp6DeaTkjR6ADfJm0Dnb1vm+4fnAzjtL4iTc8r4x
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

Reviewed-by: Douglas Anderson <dianders@chromium.org>
Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 include/linux/nmi.h     |  1 +
 kernel/watchdog.c       | 19 ++++++++++++++++---
 kernel/watchdog_buddy.c |  9 +--------
 3 files changed, 18 insertions(+), 11 deletions(-)

diff --git a/include/linux/nmi.h b/include/linux/nmi.h
index 207156f2143c..bc1162895f35 100644
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
index 431c540bd035..87dd5e0f6968 100644
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
@@ -159,7 +167,7 @@ void watchdog_hardlockup_touch_cpu(unsigned int cpu)
 	per_cpu(watchdog_hardlockup_touched, cpu) = true;
 }
 
-static void watchdog_hardlockup_update(unsigned int cpu)
+static void watchdog_hardlockup_update_reset(unsigned int cpu)
 {
 	int hrint = atomic_read(&per_cpu(hrtimer_interrupts, cpu));
 
@@ -169,6 +177,7 @@ static void watchdog_hardlockup_update(unsigned int cpu)
 	 * written/read by a single CPU.
 	 */
 	per_cpu(hrtimer_interrupts_saved, cpu) = hrint;
+	per_cpu(hrtimer_interrupts_missed, cpu) = 0;
 }
 
 static bool is_hardlockup(unsigned int cpu)
@@ -176,10 +185,14 @@ static bool is_hardlockup(unsigned int cpu)
 	int hrint = atomic_read(&per_cpu(hrtimer_interrupts, cpu));
 
 	if (per_cpu(hrtimer_interrupts_saved, cpu) != hrint) {
-		watchdog_hardlockup_update(cpu);
+		watchdog_hardlockup_update_reset(cpu);
 		return false;
 	}
 
+	per_cpu(hrtimer_interrupts_missed, cpu)++;
+	if (per_cpu(hrtimer_interrupts_missed, cpu) % watchdog_hardlockup_miss_thresh)
+		return false;
+
 	return true;
 }
 
@@ -198,7 +211,7 @@ void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 	unsigned long flags;
 
 	if (per_cpu(watchdog_hardlockup_touched, cpu)) {
-		watchdog_hardlockup_update(cpu);
+		watchdog_hardlockup_update_reset(cpu);
 		per_cpu(watchdog_hardlockup_touched, cpu) = false;
 		return;
 	}
diff --git a/kernel/watchdog_buddy.c b/kernel/watchdog_buddy.c
index ee754d767c21..3a1e57080c1c 100644
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
2.53.0.851.ga537e3e6e9-goog

