From: "Christoph Lameter (Ampere)" <cl@gentwo.org>
Date: Wed, 02 Jul 2025 12:42:00 -0700
Subject: [PATCH] Skew tick for systems with a large number of processors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-tick_skew-v1-1-ff8d73035b02@gentwo.org>
X-B4-Tracking: v=1; b=H4sIAIeLZWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwMj3ZLM5Oz44uzUcl2DVHMLU4tkQwMjEzMloPqCotS0zAqwWdGxtbU
 AxXCWRVsAAAA=
To: Anna-Maria Behnsen <anna-maria@linutronix.de>, 
 Frederic Weisbecker <frederic@kernel.org>, Ingo Molnar <mingo@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, sh@gentwo.org, 
 Darren Hart <dvhart@infradead.org>, 
 "Christoph Lameter (Ampere)" <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751485333; l=2920;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=mEaXrgWVXMVIAxP7Q84RMJ+OwIeyomVfgVzW4N0MT4E=;
 b=2AYl5EUugdW/v8u1pbUcoYBfQ9I+PSRag4ISQvJfh69fvIZcVJ+jx1B2XIzXC+CZTqg3g9cqh
 bLRSsyBQrWnDD6bfaFXPywKA2+6y50ataeDkou12LfHQoNYMxpJwP1o
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Synchronized ticks mean that all processors will simultaneously process
ticks and enter the scheduler. So the contention increases as the number
of cpu increases. The contention causes latency jitter that scales with
the number of processors.

Staggering the timer interrupt also helps mitigate voltage droop related
issues that may be observed in SOCs with large core counts.
See https://semiengineering.com/mitigating-voltage-droop/ for a more
detailed explanation.

Switch to skewed tick for systems with more than 64 processors.

Signed-off-by: Christoph Lameter (Ampere) <cl@gentwo.org>
---
 kernel/Kconfig.hz        | 10 ++++++++++
 kernel/time/tick-sched.c | 16 ++++++++++++++--
 2 files changed, 24 insertions(+), 2 deletions(-)

diff --git a/kernel/Kconfig.hz b/kernel/Kconfig.hz
index ce1435cb08b1..245d938d446b 100644
--- a/kernel/Kconfig.hz
+++ b/kernel/Kconfig.hz
@@ -57,3 +57,13 @@ config HZ
 
 config SCHED_HRTICK
 	def_bool HIGH_RES_TIMERS
+
+config TICK_SKEW_LIMIT
+	int
+	default 64
+	help
+	  If the kernel is booted on systems with a large number of cpus then the
+	  concurrent execution of timer ticks causes long holdoffs due to
+	  serialization. Synchrononous executions of interrupts can also cause
+	  voltage droop in SOCs. So switch to skewed mode. This mechanism
+	  can be overridden by specifying "tick_skew=x" on the kernel command line.
diff --git a/kernel/time/tick-sched.c b/kernel/time/tick-sched.c
index c527b421c865..aab7a1cc25c7 100644
--- a/kernel/time/tick-sched.c
+++ b/kernel/time/tick-sched.c
@@ -1554,7 +1554,7 @@ void tick_irq_enter(void)
 	tick_nohz_irq_enter();
 }
 
-static int sched_skew_tick;
+static int sched_skew_tick = -1;
 
 static int __init skew_tick(char *str)
 {
@@ -1572,6 +1572,16 @@ void tick_setup_sched_timer(bool hrtimer)
 {
 	struct tick_sched *ts = this_cpu_ptr(&tick_cpu_sched);
 
+	/* Figure out if we should skew the tick */
+	if (sched_skew_tick < 0) {
+		if (num_possible_cpus() >= CONFIG_TICK_SKEW_LIMIT) {
+			sched_skew_tick = 1;
+			pr_info("Tick skewed mode enabled. Possible cpus %u > %u\n",
+				num_possible_cpus(), CONFIG_TICK_SKEW_LIMIT);
+		} else
+			sched_skew_tick = 0;
+	}
+
 	/* Emulate tick processing via per-CPU hrtimers: */
 	hrtimer_setup(&ts->sched_timer, tick_nohz_handler, CLOCK_MONOTONIC, HRTIMER_MODE_ABS_HARD);
 
@@ -1587,7 +1597,9 @@ void tick_setup_sched_timer(bool hrtimer)
 		do_div(offset, num_possible_cpus());
 		offset *= smp_processor_id();
 		hrtimer_add_expires_ns(&ts->sched_timer, offset);
-	}
+	} else
+		pr_info("Tick operating in synchronized mode.\n");
+
 
 	hrtimer_forward_now(&ts->sched_timer, TICK_NSEC);
 	if (IS_ENABLED(CONFIG_HIGH_RES_TIMERS) && hrtimer)

---
base-commit: 66701750d5565c574af42bef0b789ce0203e3071
change-id: 20250702-tick_skew-0e7858c10246

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

