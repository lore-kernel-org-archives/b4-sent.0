From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 02 Nov 2026 16:45:35 -0500
Subject: [PATCH] clocksource: Use the clocksource under test for the skew
 check timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-clocksource-skew-timeout-v1-1-4ff412918591@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTvQRKroVcRFO/7RsdpIJlGh9
 O5GXX6L92YyJIXRvpkp4ammcapwq4bk0k9nsJ6qybd+41zrWW5RRoslCdhGvDjrHbFkDr7foQv
 DOmw7qvkjIej7tz4c/7YyXCH5+6Nl+QBA6AVcfAAAAA==
X-Change-ID: 20261102-clocksource-skew-timeout-f2a9e5fb3f75
To: Thomas Gleixner <tglx@kernel.org>, John Stultz <jstultz@google.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Srikanth Aithal <Srikanth.Aithal@amd.com>, Borislav Petkov <bp@alien8.de>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793655935; l=5072;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=BwOAXMTSmN3S5CdQQNe0kwBbbM0riuH0AkP9PTw3cow=;
 b=X4hBPBJpPywiDSpkFxm5qV4E84jNKzIKZezeqM1NLCPq+buPyTkeybhiCSVmSBIjVpkq3+QEZ
 H63xSgmVSFxASydIlKIHue6PbkZC5vf8sKSYhCeW6fgGeRE1a2zBOt+
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

The boot then hangs when the remote CPU can't answer, eg in the
stop_machine() of the switch away from jiffies:

  CPU0                                  CPU1
  multi_cpu_stop()                      multi_cpu_stop()
                                          local_irq_disable()
                                          /* waits for CPU0 */
    <timer interrupt>
      clocksource_watchdog()
        /* sends CSD to CPU1 */
        watchdog_check_skew()
          /* waits for CPU1 forever */

Nothing gets printed.  With the hard lockup detector on in a KVM guest:

  [    1.554193] watchdog: CPU0: Watchdog detected hard LOCKUP on cpu 0
  [    1.554193] CPU: 0 UID: 0 PID: 18 Comm: migration/0 Not tainted 7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [    1.554193] Stopper: multi_cpu_stop+0x0/0x310 <- __stop_cpus.constprop.0+0xdd/0x150
  [    1.554193] RIP: 0010:watchdog_check_skew+0x12d/0x5a0
  [    1.554193] Call Trace:
  [    1.554193]  <IRQ>
  [    1.554193]  clocksource_watchdog+0x761/0xc90
  [    1.554193]  call_timer_fn+0x154/0x470
  [    1.554193]  __run_timer_base.part.0+0x5d0/0x910
  [    1.554193]  run_timer_softirq+0xc2/0x280
  [    1.554193]  handle_softirqs+0x1f9/0x840
  [    1.554193]  __irq_exit_rcu+0x157/0x210
  [    1.554193]  irq_exit_rcu+0x9/0x20
  [    1.554193]  sysvec_apic_timer_interrupt+0x6b/0x80
  [    1.554193]  </IRQ>
  [    1.554193]  <TASK>
  [    1.554193]  asm_sysvec_apic_timer_interrupt+0x1a/0x20
  [    1.554193] RIP: 0010:multi_cpu_stop+0xf7/0x310
  ...
  [    1.554193]  cpu_stopper_thread+0x1fa/0x3f0
  [    1.554193]  smpboot_thread_fn+0x2fb/0x8a0
  [    1.554193]  kthread+0x300/0x3e0
  [    1.554193]  ret_from_fork+0x4f0/0x6f0
  [    1.554193]  ret_from_fork_asm+0x1a/0x30
  [    1.554193]  </TASK>

Measure the timeout with the clocksource under test instead, which
keeps counting with interrupts disabled.  With the fix, the watchdog
gives up after the timeout and the boot goes on.  A 2-vCPU guest on one
host core hung in 4 of 150 boots without it, and it didn't hang at all
in 400 tests with the fix applied.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 80s on a kernel booted with clocksource=jiffies.

Fixes: 763aacf86f1b ("clocksource: Rewrite watchdog code completely")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Srikanth reported silent early boot hangs of large KVM guests that he
bisected to the same commit [1].  I think it's the same bug but it was
never confirmed.  Srikanth, would you mind giving this a try on your
setup?

[1] https://lore.kernel.org/all/e4a41d43-4d60-4132-aa2d-70e038a3e9dd@amd.com/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/wdboot.c
---
 kernel/time/clocksource.c | 16 +++++++++++-----
 1 file changed, 11 insertions(+), 5 deletions(-)

diff --git a/kernel/time/clocksource.c b/kernel/time/clocksource.c
index 58c0ca11cdc5..fdce67f7c3d1 100644
--- a/kernel/time/clocksource.c
+++ b/kernel/time/clocksource.c
@@ -305,11 +305,16 @@ static bool watchdog_wait_seq(struct watchdog_cpu_data *wd, u64 start, int seq)
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
@@ -322,12 +327,13 @@ static bool watchdog_wait_seq(struct watchdog_cpu_data *wd, u64 start, int seq)
 
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

---
base-commit: f322d7f7ae56bce728ba03a387e35380bc4ad939
change-id: 20261102-clocksource-skew-timeout-f2a9e5fb3f75

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

