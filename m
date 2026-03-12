From: Mayank Rungta <mrungta@google.com>
Date: Thu, 12 Mar 2026 16:22:03 -0700
Subject: [PATCH v2 2/5] watchdog: Update saved interrupts during check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-hardlockup-watchdog-fixes-v2-2-45bd8a0cc7ed@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773357752; l=2486;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=M8TFUUsd+x02qNZV27ER4ewjfXgDz4uo0zb2OpCd5AY=;
 b=c1BEltI1CYPBMfFHi5jcw831jLPMgod4QJfhUT9xrFyjz3NldwgfjwNdNDMWxW2HPjQ0sE4J1
 AmprlHBsxMWCOna15znVCFqclrRZKFGioExw5mgmR06dtLbmlgCbqf9
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, arch_touch_nmi_watchdog() causes an early return that
skips updating hrtimer_interrupts_saved. This leads to stale
comparisons and delayed lockup detection.

I found this issue because in our system the serial console is fairly
chatty. For example, the 8250 console driver frequently calls
touch_nmi_watchdog() via console_write(). If a CPU locks up after a
timer interrupt but before next watchdog check, we see the following
sequence:

  * watchdog_hardlockup_check() saves counter (e.g., 1000)
  * Timer runs and updates the counter (1001)
  * touch_nmi_watchdog() is called
  * CPU locks up
  * 10s pass: check() notices touch, returns early, skips update
  * 10s pass: check() saves counter (1001)
  * 10s pass: check() finally detects lockup

This delays detection to 30 seconds. With this fix, we detect the
lockup in 20 seconds.

Reviewed-by: Douglas Anderson <dianders@chromium.org>
Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 kernel/watchdog.c | 18 +++++++++++++-----
 1 file changed, 13 insertions(+), 5 deletions(-)

diff --git a/kernel/watchdog.c b/kernel/watchdog.c
index 4c5b47495745..431c540bd035 100644
--- a/kernel/watchdog.c
+++ b/kernel/watchdog.c
@@ -159,21 +159,28 @@ void watchdog_hardlockup_touch_cpu(unsigned int cpu)
 	per_cpu(watchdog_hardlockup_touched, cpu) = true;
 }
 
-static bool is_hardlockup(unsigned int cpu)
+static void watchdog_hardlockup_update(unsigned int cpu)
 {
 	int hrint = atomic_read(&per_cpu(hrtimer_interrupts, cpu));
 
-	if (per_cpu(hrtimer_interrupts_saved, cpu) == hrint)
-		return true;
-
 	/*
 	 * NOTE: we don't need any fancy atomic_t or READ_ONCE/WRITE_ONCE
 	 * for hrtimer_interrupts_saved. hrtimer_interrupts_saved is
 	 * written/read by a single CPU.
 	 */
 	per_cpu(hrtimer_interrupts_saved, cpu) = hrint;
+}
+
+static bool is_hardlockup(unsigned int cpu)
+{
+	int hrint = atomic_read(&per_cpu(hrtimer_interrupts, cpu));
+
+	if (per_cpu(hrtimer_interrupts_saved, cpu) != hrint) {
+		watchdog_hardlockup_update(cpu);
+		return false;
+	}
 
-	return false;
+	return true;
 }
 
 static void watchdog_hardlockup_kick(void)
@@ -191,6 +198,7 @@ void watchdog_hardlockup_check(unsigned int cpu, struct pt_regs *regs)
 	unsigned long flags;
 
 	if (per_cpu(watchdog_hardlockup_touched, cpu)) {
+		watchdog_hardlockup_update(cpu);
 		per_cpu(watchdog_hardlockup_touched, cpu) = false;
 		return;
 	}

-- 
2.53.0.851.ga537e3e6e9-goog

