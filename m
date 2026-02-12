From: Mayank Rungta <mrungta@google.com>
Date: Thu, 12 Feb 2026 14:12:10 -0700
Subject: [PATCH 1/4] watchdog/hardlockup: Always update saved interrupts
 during check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260212-hardlockup-watchdog-fixes-v1-1-745f1dce04c3@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770930732; l=2116;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=jeXyM9Zz7zH/TkvXATjr1ijroPIgJAbT1ZySlVxvX+0=;
 b=EmrlxcFLuYgP97uSm+OPQWshCcXqiYiX/U9ySJP+u6v+S8ri2MGxrjnlbzHiWziBLLVQq67/z
 PyUOFRmfLP/Bu/cARWpsnG6+ROx7Q8wk3Ov4Zum4cfI4UiAHhwZ5Hts
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, arch_touch_nmi_watchdog() causes an early return that
skips updating hrtimer_interrupts_saved. This leads to stale
comparisons and delayed lockup detection.

Update the saved interrupt count before checking the touched flag
to ensure detection timeliness.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 kernel/watchdog.c | 23 ++++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

diff --git a/kernel/watchdog.c b/kernel/watchdog.c
index 7d675781bc917d709aa3fb499629eeac86934f55..b71aa814edcf9ad8f73644eb5bcd1eeb3264e4ed 100644
--- a/kernel/watchdog.c
+++ b/kernel/watchdog.c
@@ -186,7 +186,21 @@ static void watchdog_hardlockup_kick(void)
 
 void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 {
+	bool is_hl;
 	int hardlockup_all_cpu_backtrace;
+	/*
+	 * Check for a hardlockup by making sure the CPU's timer
+	 * interrupt is incrementing. The timer interrupt should have
+	 * fired multiple times before we overflow'd. If it hasn't
+	 * then this is a good indication the cpu is stuck
+	 *
+	 * Purposely check this _before_ checking watchdog_hardlockup_touched
+	 * so we make sure we still update the saved value of the interrupts.
+	 * Without that we'll take an extra round through this function before
+	 * we can detect a lockup.
+	 */
+
+	is_hl = is_hardlockup(cpu);
 
 	if (per_cpu(watchdog_hardlockup_touched, cpu)) {
 		per_cpu(watchdog_hardlockup_touched, cpu) = false;
@@ -195,13 +209,8 @@ void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 
 	hardlockup_all_cpu_backtrace = (hardlockup_si_mask & SYS_INFO_ALL_BT) ?
 					1 : sysctl_hardlockup_all_cpu_backtrace;
-	/*
-	 * Check for a hardlockup by making sure the CPU's timer
-	 * interrupt is incrementing. The timer interrupt should have
-	 * fired multiple times before we overflow'd. If it hasn't
-	 * then this is a good indication the cpu is stuck
-	 */
-	if (is_hardlockup(cpu)) {
+
+	if (is_hl) {
 		unsigned int this_cpu = smp_processor_id();
 		unsigned long flags;
 

-- 
2.53.0.273.g2a3d683680-goog

