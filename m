From: Mayank Rungta <mrungta@google.com>
Date: Thu, 12 Mar 2026 16:22:02 -0700
Subject: [PATCH v2 1/5] watchdog: Return early in
 watchdog_hardlockup_check()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-hardlockup-watchdog-fixes-v2-1-45bd8a0cc7ed@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773357752; l=5437;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=/gmGbSYfq0uL3jFNpI3ejNjGlNROGDfe6h8BWDUCdcs=;
 b=HQzF2MlIsRSuZGZCoBBHHUHE0LnOCFLTKwDzHh7aXPJMLq192jyuitITA7uKVL+uLOB7DMUHR
 xkMy50bkDXSB0PzgpgywZ8SeScifNZ4R3sKJqyvZctb9P4s0AQEspxX
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Invert the `is_hardlockup(cpu)` check in `watchdog_hardlockup_check()`
to return early when a hardlockup is not detected. This flattens the
main logic block, reducing the indentation level and making the code
easier to read and maintain.

This refactoring serves as a preparation patch for future hardlockup
changes.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 kernel/watchdog.c | 117 +++++++++++++++++++++++++++---------------------------
 1 file changed, 59 insertions(+), 58 deletions(-)

diff --git a/kernel/watchdog.c b/kernel/watchdog.c
index 7d675781bc91..4c5b47495745 100644
--- a/kernel/watchdog.c
+++ b/kernel/watchdog.c
@@ -187,6 +187,8 @@ static void watchdog_hardlockup_kick(void)
 void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 {
 	int hardlockup_all_cpu_backtrace;
+	unsigned int this_cpu;
+	unsigned long flags;
 
 	if (per_cpu(watchdog_hardlockup_touched, cpu)) {
 		per_cpu(watchdog_hardlockup_touched, cpu) = false;
@@ -201,74 +203,73 @@ void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 	 * fired multiple times before we overflow'd. If it hasn't
 	 * then this is a good indication the cpu is stuck
 	 */
-	if (is_hardlockup(cpu)) {
-		unsigned int this_cpu = smp_processor_id();
-		unsigned long flags;
+	if (!is_hardlockup(cpu)) {
+		per_cpu(watchdog_hardlockup_warned, cpu) = false;
+		return;
+	}
 
 #ifdef CONFIG_SYSFS
-		++hardlockup_count;
+	++hardlockup_count;
 #endif
-		/*
-		 * A poorly behaving BPF scheduler can trigger hard lockup by
-		 * e.g. putting numerous affinitized tasks in a single queue and
-		 * directing all CPUs at it. The following call can return true
-		 * only once when sched_ext is enabled and will immediately
-		 * abort the BPF scheduler and print out a warning message.
-		 */
-		if (scx_hardlockup(cpu))
-			return;
+	/*
+	 * A poorly behaving BPF scheduler can trigger hard lockup by
+	 * e.g. putting numerous affinitized tasks in a single queue and
+	 * directing all CPUs at it. The following call can return true
+	 * only once when sched_ext is enabled and will immediately
+	 * abort the BPF scheduler and print out a warning message.
+	 */
+	if (scx_hardlockup(cpu))
+		return;
 
-		/* Only print hardlockups once. */
-		if (per_cpu(watchdog_hardlockup_warned, cpu))
-			return;
+	/* Only print hardlockups once. */
+	if (per_cpu(watchdog_hardlockup_warned, cpu))
+		return;
 
-		/*
-		 * Prevent multiple hard-lockup reports if one cpu is already
-		 * engaged in dumping all cpu back traces.
-		 */
-		if (hardlockup_all_cpu_backtrace) {
-			if (test_and_set_bit_lock(0, &hard_lockup_nmi_warn))
-				return;
-		}
+	/*
+	 * Prevent multiple hard-lockup reports if one cpu is already
+	 * engaged in dumping all cpu back traces.
+	 */
+	if (hardlockup_all_cpu_backtrace) {
+		if (test_and_set_bit_lock(0, &hard_lockup_nmi_warn))
+			return;
+	}
 
-		/*
-		 * NOTE: we call printk_cpu_sync_get_irqsave() after printing
-		 * the lockup message. While it would be nice to serialize
-		 * that printout, we really want to make sure that if some
-		 * other CPU somehow locked up while holding the lock associated
-		 * with printk_cpu_sync_get_irqsave() that we can still at least
-		 * get the message about the lockup out.
-		 */
-		pr_emerg("CPU%u: Watchdog detected hard LOCKUP on cpu %u\n", this_cpu, cpu);
-		printk_cpu_sync_get_irqsave(flags);
+	/*
+	 * NOTE: we call printk_cpu_sync_get_irqsave() after printing
+	 * the lockup message. While it would be nice to serialize
+	 * that printout, we really want to make sure that if some
+	 * other CPU somehow locked up while holding the lock associated
+	 * with printk_cpu_sync_get_irqsave() that we can still at least
+	 * get the message about the lockup out.
+	 */
+	this_cpu = smp_processor_id();
+	pr_emerg("CPU%u: Watchdog detected hard LOCKUP on cpu %u\n", this_cpu, cpu);
+	printk_cpu_sync_get_irqsave(flags);
 
-		print_modules();
-		print_irqtrace_events(current);
-		if (cpu == this_cpu) {
-			if (regs)
-				show_regs(regs);
-			else
-				dump_stack();
-			printk_cpu_sync_put_irqrestore(flags);
-		} else {
-			printk_cpu_sync_put_irqrestore(flags);
-			trigger_single_cpu_backtrace(cpu);
-		}
+	print_modules();
+	print_irqtrace_events(current);
+	if (cpu == this_cpu) {
+		if (regs)
+			show_regs(regs);
+		else
+			dump_stack();
+		printk_cpu_sync_put_irqrestore(flags);
+	} else {
+		printk_cpu_sync_put_irqrestore(flags);
+		trigger_single_cpu_backtrace(cpu);
+	}
 
-		if (hardlockup_all_cpu_backtrace) {
-			trigger_allbutcpu_cpu_backtrace(cpu);
-			if (!hardlockup_panic)
-				clear_bit_unlock(0, &hard_lockup_nmi_warn);
-		}
+	if (hardlockup_all_cpu_backtrace) {
+		trigger_allbutcpu_cpu_backtrace(cpu);
+		if (!hardlockup_panic)
+			clear_bit_unlock(0, &hard_lockup_nmi_warn);
+	}
 
-		sys_info(hardlockup_si_mask & ~SYS_INFO_ALL_BT);
-		if (hardlockup_panic)
-			nmi_panic(regs, "Hard LOCKUP");
+	sys_info(hardlockup_si_mask & ~SYS_INFO_ALL_BT);
+	if (hardlockup_panic)
+		nmi_panic(regs, "Hard LOCKUP");
 
-		per_cpu(watchdog_hardlockup_warned, cpu) = true;
-	} else {
-		per_cpu(watchdog_hardlockup_warned, cpu) = false;
-	}
+	per_cpu(watchdog_hardlockup_warned, cpu) = true;
 }
 
 #else /* CONFIG_HARDLOCKUP_DETECTOR_COUNTS_HRTIMER */

-- 
2.53.0.851.ga537e3e6e9-goog

