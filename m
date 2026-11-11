From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 16:10:18 -0500
Subject: [PATCH] sched/wait: Queue non-exclusive waiters at the head in
 do_wait_intr*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-b4-sched-wait-intr-head-v1-1-17cf2af5b964@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOw7CMBCE4atEW7NSHDkIcRVE4ccYL4VBXvOQo
 twdh0z3FfMvpKgCpfOwUMVbVB6lwxwGCtmVG1hiN03jdDR97C1ryIj8cdJYSquc4SKHGac0+tm
 aZKm/nxVJvv/y5bpbX/6O0LYcresPfOz7DXsAAAA=
X-Change-ID: 20261111-b4-sched-wait-intr-head-c5e8f0b541f4
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>
Cc: Oleg Nesterov <oleg@redhat.com>, Christian Brauner <brauner@kernel.org>, 
 Michal Nazarewicz <mina86@mina86.com>, Wen Yang <wen.yang@linux.dev>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794431418; l=3328;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=aBf1tiVmoERImLGkIeTudmuMhxlNlGR/QO90qjNZf4c=;
 b=0J3ROETF5fxEF0iC8HWrpHh6eAV/x7d2MVrYq/bu3LA5m0ULolawd1s+PMuZ1vwHvoj/C/nNo
 yyNhK7kPb+7APywjUL4k3ZtYbz2cKxN49bGso7QvmFHlvHiQSFv8STj
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task blocked in read() on an eventfd or timerfd can sleep forever
while the file is readable, if an epoll(EPOLLEXCLUSIVE) watcher of the
same file was added before it.

eventfd and timerfd wait with wait_event_interruptible_locked_irq().
do_wait_intr_irq() adds the reader at the tail, behind the exclusive
epoll entry, and __wake_up_common() stops after waking that entry.  If
the woken epoll task is killed or leaves without reading, nothing wakes
the reader:

  Task E                   Task A                 Task C
  epoll_wait(ep, -1)
    /* EPOLLEXCLUSIVE */
                           read(efd)
                             /* queued after E */
                                                  write(efd, 1)
                                                    /* wakes E, stops */
                                                  kill(E, SIGKILL)
                           /* still asleep, efd is readable */

A periodic timerfd doesn't wake A either, since the timer is restarted
only by a read.

prepare_to_wait_event() and add_wait_queue() add non-exclusive waiters
at the head, which is what __wake_up_common() relies on.  eventfd did
the same itself before it switched to these helpers.

Do the same in do_wait_intr() and do_wait_intr_irq().  This only changes
the order in which non-exclusive waiters are woken.  Each of them still
gets every wakeup.  With the fix, A is woken by the write.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 2s.

Fixes: 22c43c81a51e ("wait_event_interruptible_locked() interface")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/evexcl.c

gpiolib-cdev and cros_ec_chardev use the same helpers and can be
polled too, so this fixes them as well.
---
 kernel/sched/wait.c | 16 ++++++++++++----
 1 file changed, 12 insertions(+), 4 deletions(-)

diff --git a/kernel/sched/wait.c b/kernel/sched/wait.c
index f8d6d8b9d03e..342dec5fd937 100644
--- a/kernel/sched/wait.c
+++ b/kernel/sched/wait.c
@@ -319,8 +319,12 @@ EXPORT_SYMBOL(prepare_to_wait_event);
  */
 int do_wait_intr(wait_queue_head_t *wq, wait_queue_entry_t *wait)
 {
-	if (likely(list_empty(&wait->entry)))
-		__add_wait_queue_entry_tail(wq, wait);
+	if (likely(list_empty(&wait->entry))) {
+		if (wait->flags & WQ_FLAG_EXCLUSIVE)
+			__add_wait_queue_entry_tail(wq, wait);
+		else
+			__add_wait_queue(wq, wait);
+	}
 
 	set_current_state(TASK_INTERRUPTIBLE);
 	if (signal_pending(current))
@@ -336,8 +340,12 @@ EXPORT_SYMBOL(do_wait_intr);
 
 int do_wait_intr_irq(wait_queue_head_t *wq, wait_queue_entry_t *wait)
 {
-	if (likely(list_empty(&wait->entry)))
-		__add_wait_queue_entry_tail(wq, wait);
+	if (likely(list_empty(&wait->entry))) {
+		if (wait->flags & WQ_FLAG_EXCLUSIVE)
+			__add_wait_queue_entry_tail(wq, wait);
+		else
+			__add_wait_queue(wq, wait);
+	}
 
 	set_current_state(TASK_INTERRUPTIBLE);
 	if (signal_pending(current))

---
base-commit: d7e670601af6c564ccf6d3b2ddf70ee4f41a6d1c
change-id: 20261111-b4-sched-wait-intr-head-c5e8f0b541f4

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

