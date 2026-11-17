From: Wondertan <hlibwondertan@gmail.com>
Date: Tue, 17 Nov 2026 23:00:03 +0400
Subject: [PATCH] cpuidle: Do not reinstall the idle handler while paused
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-cpuidle-pause-fix-v1-1-b2789fce4c16@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XM2oGmWCP+irjIY7QjGkOmKULpv
 3eiy3PuYwWhwiRw6VYotLDwJymYQwdhculByFEZhn44GWMshlw5vgizq0J45y+ex2OIGvbRWtB
 dLqT693m9/Vmqf1KY21FreKdTX1wKU1NvJzMV2LYd3Br3k44AAAA=
X-Change-ID: 20261117-cpuidle-pause-fix-854cd6110d77
To: "Rafael J. Wysocki" <rafael@kernel.org>, linux-pm@vger.kernel.org
Cc: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Christian Loehle <christian.loehle@arm.com>, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Thorsten Leemhuis <linux@leemhuis.info>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5859;
 i=hlibwondertan@gmail.com; h=from:subject:message-id;
 bh=yzxZl4KPDFCwZKGEVvZatYF9Wv9r4O4+T52r9pIWSHE=;
 b=owGbwMvMwCW230B11izXCXcYT6slMWT9WdKRcFPlaeqtVcvzZ61rmpT7qLWNwVj8fzKnxm7Ta
 VnzfH8ydZSyMIhxMciKKbKwvTBVs2NQkD0zUbQFZg4rE8gQBi5OAZjIaT5Ght+ar1QmH1jKbeje
 YLrwh9FMvgk/ah1i30j+/KvyzePojkZGhrlSAn3elev1DlflXLhf7/l3xtaP+0xqNgsfWqJR/pB
 PjxcA
X-Developer-Key: i=hlibwondertan@gmail.com; a=openpgp;
 fpr=B881FDA34AD04D090E7E995C82711D6CF6F29BEC
X-Endpoint-Received: by B4 Relay for hlibwondertan@gmail.com/default with auth_id=1553
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM core pauses cpuidle before taking secondary CPUs offline during
system-wide transitions and resumes it after bringing them back online
(pm_sleep_disable_secondary_cpus()/pm_sleep_enable_secondary_cpus()), so
that CPUs do not enter cpuidle-managed idle states in that window.

However, with acpi_idle, acpi_soft_cpu_online() calls
acpi_processor_hotplug() for every CPU brought back online, and that
function brackets its update with cpuidle_pause_and_lock() and
cpuidle_resume_and_unlock().  The latter reinstalls the idle handler
unconditionally, so cpuidle is effectively resumed as soon as the first
secondary CPU is back online.  The remaining CPUs are then brought up,
and cache_aps_init() runs stop_machine(), with idle CPUs entering deep
ACPI C-states.  cpuidle_register_device() and cpuidle_switch_governor()
can undo the pause in the same way.

On a Framework Laptop 16 (AMD Ryzen AI 9 HX 370, BIOS 04.01), whose
_CST exposes C2/C3 with the SystemIO entry method, this intermittently
hangs hibernation after the image has been created: a CPU idling in
io_idle() does not respond to an IPI and another CPU soft-locks waiting
for it, either in smp_call_function_many_cond() (text poking from
sched_cpu_activate() while an SMT sibling is onlined) or in
multi_cpu_stop() (the MTRR rendezvous in cache_aps_init()).  The image is
never written and the next boot reports "PM: Image not found (code -22)":

  watchdog: BUG: soft lockup - CPU#12 stuck for 22s! [cpuhp/12:89]
  RIP: 0010:smp_call_function_many_cond+0x147/0x520
   on_each_cpu_cond_mask+0x24/0x40
   smp_text_poke_batch_finish+0xe2/0x380
   arch_jump_label_transform_apply+0x1a/0x30
   static_key_slow_inc_cpuslocked+0x4f/0xa0
   sched_cpu_activate+0x13c/0x150
  ...
   thaw_secondary_cpus.cold+0x5e/0xd2
   hibernation_snapshot+0x231/0x530
  NMI backtrace for cpu 0 skipped: idling at io_idle+0x3/0x30

  watchdog: BUG: soft lockup - CPU#3 stuck for 22s! [migration/3:37]
  Stopper: multi_cpu_stop+0x0/0x140 <- __stop_cpus.constprop.0+0x6d/0xb0
  (23 CPUs in multi_cpu_stop)
  NMI backtrace for cpu 2 skipped: idling at io_idle+0x3/0x30

Online CPUs can only be in io_idle() via cpuidle, so cpuidle was not
paused at that point.  Tracing power:cpu_idle across the transition on
6.18.59 confirms it: while CPUs 1-23 were being brought online (between
the first and the last CPU_ON "end" events, about 35 ms), idle CPUs
entered C2 263 times and C3 305 times on all 24 CPUs, the first C3 entry
coming 0.6 ms after CPU1 was onlined.  The failure rate was about one in
four hibernations, higher on battery; disabling C2/C3 via sysfs around
hibernation made it go away.

Fix this by recording that cpuidle has been paused by cpuidle_pause()
and not reinstalling the idle handler until cpuidle_resume() is called.
All callers of cpuidle_install_idle_handler() hold cpuidle_lock, which
also protects the new flag.

With this change on top of 6.18.62 and 7.3.4, the same trace across a
real hibernation and resume with C2/C3 enabled shows no C2/C3 entries
in that window (only C1), hibernation completes, and C2/C3 are used
again once the transition is over.

The root cause analysis, the fix, the tracing used to verify it and
this changelog were produced with an AI coding assistant (Claude Code,
model claude-opus-5-5), working from pstore dumps, ftrace captures and
the kernel sources.  All builds and tests were run on the affected
machine as described above.

Fixes: 8651f97bd951 ("PM / cpuidle: System resume hang fix with cpuidle")
Cc: stable@vger.kernel.org
Signed-off-by: Wondertan <hlibwondertan@gmail.com>
---
Tested only on the one affected machine (AMD, acpi_idle, BIOS 04.01
and 04.02): built and run-tested on 6.18.62 and 7.3.4 (Arch linux-lts
and linux configs, x86_64).  drivers/cpuidle/cpuidle.c in 7.3.4 is
identical to mainline apart from this change.  On mainline
(141b164bbe18) drivers/cpuidle/ was only built (W=1, no warnings), not
booted.  Not tested with intel_idle or other cpuidle drivers.

Earlier report of the hangs, before the root cause was known:
"[REGRESSION?] hibernation soft lockup in migration/0 after image
creation", linux-pm, 2026-07-09.
---
 drivers/cpuidle/cpuidle.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/cpuidle/cpuidle.c b/drivers/cpuidle/cpuidle.c
index 2d2f40a2c..3e26b1760 100644
--- a/drivers/cpuidle/cpuidle.c
+++ b/drivers/cpuidle/cpuidle.c
@@ -39,6 +39,7 @@ LIST_HEAD(cpuidle_detected_devices);
 static int enabled_devices;
 static int off __read_mostly;
 static int initialized __read_mostly;
+static bool paused;	/* Protected by cpuidle_lock */
 
 int cpuidle_disabled(void)
 {
@@ -465,7 +466,12 @@ __cpuidle u64 cpuidle_poll_time(struct cpuidle_driver *drv,
  */
 void cpuidle_install_idle_handler(void)
 {
-	if (enabled_devices) {
+	/*
+	 * Do not reinstall the idle handler while cpuidle is paused for a
+	 * system transition, even if a nested cpuidle_resume_and_unlock()
+	 * (e.g. from the ACPI processor CPU online callback) asks for it.
+	 */
+	if (enabled_devices && !paused) {
 		/* Make sure all changes finished before we switch to new idle */
 		smp_wmb();
 		initialized = 1;
@@ -515,6 +521,7 @@ EXPORT_SYMBOL_GPL(cpuidle_resume_and_unlock);
 void cpuidle_pause(void)
 {
 	mutex_lock(&cpuidle_lock);
+	paused = true;
 	cpuidle_uninstall_idle_handler();
 	mutex_unlock(&cpuidle_lock);
 }
@@ -523,6 +530,7 @@ void cpuidle_pause(void)
 void cpuidle_resume(void)
 {
 	mutex_lock(&cpuidle_lock);
+	paused = false;
 	cpuidle_install_idle_handler();
 	mutex_unlock(&cpuidle_lock);
 }

---
base-commit: 141b164bbe186423e295b139e40e8e2d11cf1341
change-id: 20261117-cpuidle-pause-fix-854cd6110d77

Best regards,
--  
Wondertan <hlibwondertan@gmail.com>

