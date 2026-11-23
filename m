From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 23 Nov 2026 15:44:37 -0500
Subject: [PATCH net v2] net: don't leave napi->timer queued when deleting a
 napi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-napi-timer-cancel-v2-1-00e6fc1be30f@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQqDMBBEf0X23BQ3EpGe+h/Fw5qsdYtGSaK0i
 P9etfceZ3jzZoXIQTjCLVsh8CJRRr8HfcnAduSfrMTtGXSuS8S8UJ4mUUkGDsqSt9yrlnLSlWm
 dqRD23RS4lffpfIDnBPWvjHPzYpsO24F1EtMYPufzgif852RBhcoYWxZIzuiqvNuxn4dG6Mpuh
 nrbti+SlICLzAAAAA==
X-Change-ID: 20261103-napi-timer-cancel-fa0a285fd581
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Martin Karsten <mkarsten@uwaterloo.ca>, Joe Damato <joe@dama.to>, 
 Dragos Tatulea <dtatulea@nvidia.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 Stanislav Fomichev <sdf.kernel@gmail.com>, 
 Sridhar Samudrala <sridhar.samudrala@intel.com>, 
 Cosmin Ratiu <cratiu@nvidia.com>, Tariq Toukan <tariqt@nvidia.com>, 
 Wang Zhan <wang.zhan@smartx.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795466676; l=6265;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=DAjbjTcO41LIw37BT4Jor7jRDPzA0lF7xrJx5+OcZXE=;
 b=5MnTtsFeJIO++GpbRtxmiY9d64OSULsDSyYtSBaq3KgNIavxf5oinJpn6SzuZ/Wqp9QpptGRw
 u/az2bOV32EDBgcZ7h1v2rDWyGuLMyE3OZlmeLs4RnhgOi5U6d3rDqW
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A napi can be freed with its timer still queued.  napi_disable()
cancels napi->timer, but napi_complete_done(), busy_poll_stop() and
napi_suspend_irqs() start it without owning the napi and can do so
right after the cancel.  netif_napi_del() only waits for that start to
finish:

  Task A (epoll_wait)                  Task B (queue reset)
  napi_suspend_irqs()
    rcu_read_lock()
    napi = napi_by_id(id)
                                       napi_disable_locked(napi)
                                         hrtimer_cancel(&napi->timer)
                                         napi_hash_del(napi)
                                       netif_napi_del_locked(napi)
                                         synchronize_net()
                                         /* waits for Task A */
    hrtimer_start(&napi->timer)
    rcu_read_unlock()
                                       kfree(rq)
                                         /* timer still queued */

With netdevsim and debug objects:

  [    3.073483] ODEBUG: free active (active state 0) object: 000000001504358f object type: hrtimer hint: napi_watchdog+0x0/0xa0
  [    3.073515] WARNING: lib/debugobjects.c:629 at debug_print_object+0x1a4/0x3b0, CPU#0: napitimer/66
  [    3.079603] CPU: 0 UID: 0 PID: 66 Comm: napitimer Tainted: G        W            7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [    3.084822] RIP: 0010:debug_print_object+0x1ae/0x3b0
  ...
  [    3.103822] Call Trace:
  [    3.104408]  <TASK>
  [    3.105933]  debug_check_no_obj_freed+0x496/0x5f0
  [    3.109988]  kfree+0x33a/0x510
  [    3.110715]  netdev_rx_queue_reconfig+0x357/0x580
  [    3.111780]  netdev_rx_queue_restart+0x8f/0xc0
  [    3.113924]  nsim_qreset_write+0x24d/0x350
  [    3.117832]  full_proxy_write+0x109/0x1d0
  [    3.118741]  vfs_write+0x1e3/0x1250
  [    3.124758]  __x64_sys_pwrite64+0x18c/0x250
  [    3.129645]  do_syscall_64+0xfb/0x590
  [    3.131385]  entry_SYSCALL_64_after_hwframe+0x77/0x7f

Without debug objects, napi_watchdog() later runs on freed memory.

Cancel the timer in __netif_napi_del_locked() right after clearing
NAPI_STATE_LISTED, and start it in the three callers through a helper
that cancels it again if LISTED is already clear.  Either the delete
sees the queued timer or the start sees LISTED cleared.  The helper
uses hrtimer_cancel() since hrtimer_try_to_cancel() doesn't dequeue a
timer that is queued again while napi_watchdog() runs.  This also covers
__netif_napi_del() callers that run their own grace period, and
free_netdev().  With the fix, debug objects don't report a freed active
timer anymore.

Fixes: 6f8b12d661d0 ("net: napi: add hard irqs deferral feature")
Fixes: 3fcbecbdeb04 ("net: Add control functions for irq suspension")
Fixes: 58e2330bd455 ("net: napi: Avoid gro timer misfiring at end of busypoll")
Suggested-by: Eric Dumazet <edumazet@kernel.org>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/napitimer.c
---
Changes in v2:
- Cancel the timer in __netif_napi_del_locked() and re-check LISTED after
  each start, instead of cancelling after the grace period in
  netif_napi_del() and free_netdev() (Eric)
- Use hrtimer_cancel() in the helper, since hrtimer_try_to_cancel()
  doesn't dequeue a timer that is queued again while napi_watchdog() runs
- Martin suggested re-checking NAPI_STATE_DISABLED, which also works and
  is a bit smaller. It needs 8dc87fc5d6a0 though, which stable trees
  before 6.18 don't have, and the bug goes back to 5.8. Happy to switch
  if that's preferred.
- Link to v1: https://patch.msgid.link/20261103-napi-timer-cancel-v1-1-55c631ad5286@columbia.edu
---
 net/core/dev.c | 27 +++++++++++++++++++++------
 1 file changed, 21 insertions(+), 6 deletions(-)

diff --git a/net/core/dev.c b/net/core/dev.c
index cd0796a1dbfd..c39a588d9c0a 100644
--- a/net/core/dev.c
+++ b/net/core/dev.c
@@ -7019,6 +7019,19 @@ void __napi_schedule_irqoff(struct napi_struct *n)
 }
 EXPORT_SYMBOL(__napi_schedule_irqoff);
 
+/* Callers do not own @n, which can be deleted concurrently. */
+static void napi_timer_start(struct napi_struct *n, unsigned long timeout)
+{
+	hrtimer_start(&n->timer, ns_to_ktime(timeout),
+		      HRTIMER_MODE_REL_PINNED);
+	/* Pairs with test_and_clear_bit(NAPI_STATE_LISTED)
+	 * in __netif_napi_del_locked().
+	 */
+	smp_mb();
+	if (unlikely(!test_bit(NAPI_STATE_LISTED, &n->state)))
+		hrtimer_cancel(&n->timer);
+}
+
 bool napi_complete_done(struct napi_struct *n, int work_done)
 {
 	unsigned long flags, val, new, timeout = 0;
@@ -7083,8 +7096,7 @@ bool napi_complete_done(struct napi_struct *n, int work_done)
 	}
 
 	if (timeout)
-		hrtimer_start(&n->timer, ns_to_ktime(timeout),
-			      HRTIMER_MODE_REL_PINNED);
+		napi_timer_start(n, timeout);
 	return ret;
 }
 EXPORT_SYMBOL(napi_complete_done);
@@ -7171,8 +7183,7 @@ static void busy_poll_stop(struct napi_struct *napi, void *have_poll_lock,
 		gro_flush_normal(&napi->gro, HZ >= 1000);
 
 		clear_bit(NAPI_STATE_SCHED, &napi->state);
-		hrtimer_start(&napi->timer, ns_to_ktime(timeout),
-			      HRTIMER_MODE_REL_PINNED);
+		napi_timer_start(napi, timeout);
 	} else {
 		/* Use driver poll to re-enable device interrupts. */
 		rc = napi->poll(napi, budget);
@@ -7309,8 +7320,7 @@ void napi_suspend_irqs(unsigned int napi_id)
 		unsigned long timeout = napi_get_irq_suspend_timeout(napi);
 
 		if (timeout)
-			hrtimer_start(&napi->timer, ns_to_ktime(timeout),
-				      HRTIMER_MODE_REL_PINNED);
+			napi_timer_start(napi, timeout);
 	}
 	rcu_read_unlock();
 }
@@ -7963,6 +7973,11 @@ void __netif_napi_del_locked(struct napi_struct *napi)
 	if (!test_and_clear_bit(NAPI_STATE_LISTED, &napi->state))
 		return;
 
+	/* Full barrier implied by test_and_clear_bit()
+	 * pairs with napi_timer_start().
+	 */
+	hrtimer_cancel(&napi->timer);
+
 	/* Make sure NAPI is disabled (or was never enabled). */
 	WARN_ON(!test_bit(NAPI_STATE_SCHED, &napi->state));
 

---
base-commit: 5677cf0e039b3cabf79d5aa10facbdb54aea93c6
change-id: 20261103-napi-timer-cancel-fa0a285fd581

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

