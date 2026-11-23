From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:35:12 -0500
Subject: [PATCH v2 1/2] sched/wait: Queue non-exclusive waiters at the head
 in do_wait_intr*()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-sched-wait-intr-head-v2-1-4a764b64e8ce@columbia.edu>
References: <20261122-b4-sched-wait-intr-head-v2-0-4a764b64e8ce@columbia.edu>
In-Reply-To: <20261122-b4-sched-wait-intr-head-v2-0-4a764b64e8ce@columbia.edu>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>
Cc: Oleg Nesterov <oleg@redhat.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Michal Nazarewicz <mina86@mina86.com>, Wen Yang <wen.yang@linux.dev>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394112; l=2797;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=t/EKiWQssfQXpF3qKY+ICig437H7rd2qHOCQVtDp+ik=;
 b=hi28efIN5xw0rW8lQiQmA2+zT+36chA36KU7jbGMXczzHAIy4UrZqhhw3fCp1sc48I4ucPyEe
 13y386I3s5/ATqO3+fGstJNOY5FgHx+57ZWo4tav9uDc5o0l1U6Fqiq
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

Fixes: 22c43c81a51e ("wait_event_interruptible_locked() interface")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
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

-- 
2.53.0

