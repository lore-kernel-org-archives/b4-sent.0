From: Mani Tofigh <mt4022@columbia.edu>
Date: Fri, 13 Nov 2026 23:12:13 -0500
Subject: [PATCH v2] clocksource: Use the clocksource under test for the
 skew check timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-clocksource-skew-timeout-v2-1-9361d9a18262@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NTQ6CMBBGr0K6toapoOLKexgWUKYy8lPTaVFDe
 ncBL+DyJe973ywYHSGLSzILhxMx2XEBtUuEbqvxjpKahYVK1REgVVL3Vndsg9MoucOX9DSgDV4
 aVRWYm/pgTrlY5k+Hht5b+lb+mEP9QO3X3mq0xN66z/Y9wer9cTOBBJkZk4Eq4JwXcNW2D0NN1
 R6bIMoY4xcK9MT/1QAAAA==
X-Change-ID: 20261102-clocksource-skew-timeout-f2a9e5fb3f75
To: Thomas Gleixner <tglx@kernel.org>, John Stultz <jstultz@google.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Srikanth Aithal <Srikanth.Aithal@amd.com>, Borislav Petkov <bp@alien8.de>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, Mani Tofigh <mt4022@columbia.edu>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629533; l=5524;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=qa93QCBknsgPMlWtKisZvhE+AO3Pt47PR9ZovD5lOZg=;
 b=N5vm0VGdkSowOxUn5xef9uAmY1tW/5ACA4RREKq2zL+uk7CXgrpBhfyyuVH5olXCmYk+IgE/o
 u93qBaW3zNxD4Ta6vAIZr+5VyKWuEhiaBoJtsrFJwikGQUNnEZl6d6U
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

watchdog_check_skew() waits for the remote CPU with interrupts disabled
and gives up after a timeout measured with ktime_get_raw_fast_ns().
While the clocksource is still jiffies during boot (or with
clocksource=jiffies) that timeout can't expire, because only the boot
CPU's tick advances jiffies and that's the CPU spinning with interrupts
disabled.

The boot then hangs silently when the remote CPU can't answer, e.g., in
the stop_machine() of the switch away from jiffies:

  CPU0                                  CPU1
  multi_cpu_stop()                      multi_cpu_stop()
                                          local_irq_disable()
                                          /* waits for CPU0 */
    <timer interrupt>
      clocksource_watchdog()
        /* sends CSD to CPU1 */
        watchdog_check_skew()
          /* waits for CPU1 forever */

Measure the timeout with the clocksource under test instead, which keeps
counting with interrupts disabled.  Also, when the remote CPU still
hasn't answered by the next watchdog round, report it as stalled and
mark the clocksource unstable instead of retrying forever.

With the fix, the watchdog gives up after the timeout and the boot
continues.

Fixes: 763aacf86f1b ("clocksource: Rewrite watchdog code completely")
Reported-by: Srikanth Aithal <Srikanth.Aithal@amd.com>
Closes: https://lore.kernel.org/all/e4a41d43-4d60-4132-aa2d-70e038a3e9dd@amd.com/
Suggested-by: Thomas Gleixner <tglx@kernel.org>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
Tested-by: Srikanth Aithal <Srikanth.Aithal@amd.com>
Cc: stable@vger.kernel.org
---
The reproducer hits it within about 80s on a kernel booted with
clocksource=jiffies, with both vCPUs of the guest on one host core:
https://github.com/manitofigh/files/blob/main/linux-repros/wdboot.c
---
Changes in v2:
- Fold in the stall check (Thomas)
- Drop the hard lockup backtrace (Thomas)
- Add Srikanth's Reported-by, Closes and Tested-by
- Link to v1: https://patch.msgid.link/20261102-clocksource-skew-timeout-v1-1-4ff412918591@columbia.edu
---
 kernel/time/clocksource.c | 32 ++++++++++++++++++++++++--------
 1 file changed, 24 insertions(+), 8 deletions(-)

diff --git a/kernel/time/clocksource.c b/kernel/time/clocksource.c
index 58c0ca11cdc5..5dfa72a2db68 100644
--- a/kernel/time/clocksource.c
+++ b/kernel/time/clocksource.c
@@ -250,6 +250,7 @@ enum wd_result {
 	WD_FREQ_RESET,
 	WD_FREQ_SKEWED,
 	WD_CPU_TIMEOUT,
+	WD_CPU_STALLED,
 	WD_CPU_SKEWED,
 };
 
@@ -305,11 +306,16 @@ static bool watchdog_wait_seq(struct watchdog_cpu_data *wd, u64 start, int seq)
 		if (READ_ONCE(wd->result) != WD_SUCCESS)
 			return false;
 
-		/* Prevent endless loops if the other CPU does not react. */
+		/*
+		 * Prevent endless loops if the other CPU does not react.  The
+		 * timeout uses the clocksource under test because the timekeeping
+		 * clocksource can be jiffies, which doesn't advance while this CPU
+		 * waits with interrupts disabled.
+		 */
 		if (cnt == 5000) {
-			u64 nsecs = ktime_get_raw_fast_ns();
+			struct clocksource *cs = wd->cs;
 
-			if (nsecs - start >=wd->timeout_ns) {
+			if (cycles_to_nsec_safe(cs, start, cs->read(cs)) >= wd->timeout_ns) {
 				watchdog_set_result(wd, WD_CPU_TIMEOUT);
 				return false;
 			}
@@ -322,12 +328,13 @@ static bool watchdog_wait_seq(struct watchdog_cpu_data *wd, u64 start, int seq)
 
 static void watchdog_check_skew(struct watchdog_cpu_data *wd, int index)
 {
-	u64 prev, now, delta, start = ktime_get_raw_fast_ns();
+	u64 prev, now, delta, start;
 	int local = index, remote = (index + 1) & 0x1;
 	struct clocksource *cs = wd->cs;
 
 	/* Set the local timestamp so that the first iteration works correctly */
-	wd->cpu_ts[local] = cs->read(cs);
+	start = cs->read(cs);
+	wd->cpu_ts[local] = start;
 
 	/* Signal arrival */
 	atomic_inc(&wd->seq);
@@ -392,7 +399,7 @@ static void __watchdog_check_cpu_skew(struct clocksource *cs, unsigned int cpu)
 
 	wd = per_cpu_ptr(&watchdog_cpu_data, cpu);
 	if (atomic_read(&wd->remote_inprogress) || wd_csd_locked(wd)) {
-		watchdog_data.result = WD_CPU_TIMEOUT;
+		watchdog_data.result = WD_CPU_STALLED;
 		return;
 	}
 
@@ -584,11 +591,16 @@ static void watchdog_print_freq_skew(struct clocksource *cs)
 	pr_warn("Clocksource %20s interval: %16lluns\n", cs->name, watchdog_data.cs_delta);
 }
 
-static void watchdog_handle_remote_timeout(struct clocksource *cs)
+static void watchdog_print_remote_timeout(struct clocksource *cs)
 {
 	pr_info_once("Watchdog remote CPU %u read timed out\n", watchdog_data.curr_cpu);
 }
 
+static void watchdog_print_remote_stall(struct clocksource *cs)
+{
+	pr_warn("Watchdog remote CPU %u stalled\n", watchdog_data.curr_cpu);
+}
+
 static void watchdog_print_remote_skew(struct clocksource *cs)
 {
 	pr_warn("Marking clocksource %s unstable due to inter CPU skew\n", cs->name);
@@ -629,9 +641,13 @@ static void watchdog_check_result(struct clocksource *cs)
 
 	case WD_CPU_TIMEOUT:
 		/* Remote check timed out. Try again next cycle. */
-		watchdog_handle_remote_timeout(cs);
+		watchdog_print_remote_timeout(cs);
 		return;
 
+	case WD_CPU_STALLED:
+		watchdog_print_remote_stall(cs);
+		break;
+
 	case WD_CPU_SKEWED:
 		watchdog_print_remote_skew(cs);
 		break;

---
base-commit: c1b96ba87e3caaa701d6dba254e58db7cc3c99be
change-id: 20261102-clocksource-skew-timeout-f2a9e5fb3f75

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

