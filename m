From: Mani Tofigh <mt4022@columbia.edu>
Date: Fri, 06 Nov 2026 11:13:50 -0500
Subject: [PATCH v3] smpboot: Run the thread function only once before
 parking
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-smpboot-park-once-v3-1-86dadce65c63@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBQE0KuYrq1pPwLFlfcwLkr7kapQ0kKjI
 dzdFjfGGJeTzLyZiUdn0JPDZiYOg/HG9jFk2w1RrewvSI2OmQCDgnMG1HdDbe1IB+lu1PYKaVW
 wshFYlizTJO4Gh415rObp/M5+qq+oxgSlRmv8aN1zPQ089f75gVNOq1gQUGS5BnZU9j51tZE71
 BNJFwE+kf0vBCKCEgSqqtEixy9kWZYXs+xc7AwBAAA=
X-Change-ID: 20261102-smpboot-park-once-9607f8e7703d
To: Thomas Gleixner <tglx@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>
Cc: Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793981630; l=2770;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=hQCHuB1d9BRH2/8dcB77iRnc4fAbW9qf8O+O+kdrRw4=;
 b=POb6tSQ/ejI405B3M4LOQ80NK42gYvLvXTSTzWXlsOnoeevhpP692cq/zUuxtZ1UOKHR7Lod6
 dkPJjgTT5sDAI9iTHU60FYh6YFfIfj9oy/jzIcJnZD/Pirx2KLZKJa2
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 4a3b51aab6e2 ("smpboot: Don't park the thread if work is
pending"), smpboot_thread_fn() parks only once thread_should_run() is
false.  CPU offline waits for that with no timeout and with
cpu_hotplug_lock held for write.

When the outgoing CPU keeps receiving more packets than it can process,
ksoftirqd always has NET_RX pending and never parks.  The offline then
waits for as long as the packets keep coming and everything that takes
cpus_read_lock() waits with it.

That commit only needs the work queued before the park request to run
once on its own CPU.  Softirqs left pending are taken over by the
dead-CPU callbacks as before.  So on a park request, run the thread
function once if there is work and then park.  With the fix, the
offline finishes under the same load.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 25s.

Fixes: 4a3b51aab6e2 ("smpboot: Don't park the thread if work is pending")
Reviewed-by: Sebastian Andrzej Siewior <bigeasy@linutronix.de>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v3:
- Drop the hung task traces (Sebastian)
- Add Sebastian's Reviewed-by
- Link to v2: https://lore.kernel.org/all/20261104-smpboot-park-once-v2-1-ea28ec9fd85e@columbia.edu/

Changes in v2:
- Use Sebastian's comment above the thread function call
- Link to v1: https://lore.kernel.org/all/20261102-smpboot-park-once-v1-1-920282635d20@columbia.edu/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/ksoftpark.c
---
 kernel/smpboot.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/kernel/smpboot.c b/kernel/smpboot.c
index 3f60e8c6dd30..b477267903d7 100644
--- a/kernel/smpboot.c
+++ b/kernel/smpboot.c
@@ -119,9 +119,17 @@ static int smpboot_thread_fn(void *data)
 		}
 
 		should_run = td->status == HP_THREAD_ACTIVE && ht->thread_should_run(td->cpu);
-		if (kthread_should_park() && !should_run) {
+		if (kthread_should_park()) {
 			__set_current_state(TASK_RUNNING);
 			preempt_enable();
+			/*
+			 * Run pending work once to handle queued work prior the
+			 * parking request. Don't try to process everything in case
+			 * new work continues to come and the handler has a hotplug
+			 * notifier for everything that was enqueued later.
+			 */
+			if (should_run)
+				ht->thread_fn(td->cpu);
 			if (ht->park && td->status == HP_THREAD_ACTIVE) {
 				BUG_ON(td->cpu != smp_processor_id());
 				ht->park(td->cpu);

---
base-commit: 006991aa89974378ee579416dba87adc22cd60fd
change-id: 20261102-smpboot-park-once-9607f8e7703d

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

