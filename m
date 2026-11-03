From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:19:16 -0500
Subject: [PATCH net] net: cancel napi->timer after the grace period in
 netif_napi_del()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-napi-timer-cancel-v1-1-55c631ad5286@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swtJSqX4K+JhTTe6omtJogil/
 96oxxmYWVAkqxQcugVZ3lr0aQ38rkO8sl2EdGqM4MLee9eT8axU9SGZIluUOyV2HMYhTcPo0bo
 5S9LP73mEScXpL8vrfJNYvzes6waLWeTzegAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793729955; l=5193;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=D3DRGuFE0EATDQVzQQV5RjgLb6ytoSbotejXuz5TFKc=;
 b=ssRhd2VE5LU/8fFDf9oHRD8iJ0XKlAM1RWeKEnlFASOxuU6corXvDu0kFe6ZGsG7EEOSLCpRM
 /EI/Db8vV0yCH1bPZEHjbW0a+Y5tEYG6c1CgdcmpBFzIh3UK5NqKwMz
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

After napi_disable() and a grace period none of the three can reach the
napi anymore.  Two need SCHED, which napi_disable() keeps, and
napi_suspend_irqs() needs the napi hash, which napi_disable() removed it
from.  So cancel the timer again after the grace period that
netif_napi_del() already waits for, and in free_netdev(), where
unregister has already waited for one.  With the fix, debug objects
don't report a freed active timer anymore.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 1s.

Fixes: 6f8b12d661d0 ("net: napi: add hard irqs deferral feature")
Fixes: 3fcbecbdeb04 ("net: Add control functions for irq suspension")
Fixes: 58e2330bd455 ("net: napi: Avoid gro timer misfiring at end of busypoll")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Drivers that call __netif_napi_del{,_locked}() and then their own
synchronize_net() (eg netdevsim on close, veth, virtio_net, bnxt and
gro_cells) need the same cancel.  I can send that separately.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/napitimer.c
---
 include/linux/netdevice.h | 9 +++++++++
 net/core/dev.c            | 5 ++++-
 2 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/include/linux/netdevice.h b/include/linux/netdevice.h
index 435be7880d7e..ad3685caf814 100644
--- a/include/linux/netdevice.h
+++ b/include/linux/netdevice.h
@@ -3013,8 +3013,13 @@ static inline void __netif_napi_del(struct napi_struct *napi)
 
 static inline void netif_napi_del_locked(struct napi_struct *napi)
 {
+	bool listed = test_bit(NAPI_STATE_LISTED, &napi->state);
+
 	__netif_napi_del_locked(napi);
 	synchronize_net();
+	/* napi->timer can be started until a grace period after napi_disable() */
+	if (listed)
+		hrtimer_cancel(&napi->timer);
 }
 
 /**
@@ -3025,8 +3030,12 @@ static inline void netif_napi_del_locked(struct napi_struct *napi)
  */
 static inline void netif_napi_del(struct napi_struct *napi)
 {
+	bool listed = test_bit(NAPI_STATE_LISTED, &napi->state);
+
 	__netif_napi_del(napi);
 	synchronize_net();
+	if (listed)
+		hrtimer_cancel(&napi->timer);
 }
 
 int netif_enable_cpu_rmap(struct net_device *dev, unsigned int num_irqs);
diff --git a/net/core/dev.c b/net/core/dev.c
index f32353b0467c..6d6384522a1b 100644
--- a/net/core/dev.c
+++ b/net/core/dev.c
@@ -12450,9 +12450,12 @@ static void netdev_napi_exit(struct net_device *dev)
 	if (!list_empty(&dev->napi_list)) {
 		struct napi_struct *p, *n;
 
+		/* unregister has waited for a grace period after napi_disable() */
 		netdev_lock(dev);
-		list_for_each_entry_safe(p, n, &dev->napi_list, dev_list)
+		list_for_each_entry_safe(p, n, &dev->napi_list, dev_list) {
+			hrtimer_cancel(&p->timer);
 			__netif_napi_del_locked(p);
+		}
 		netdev_unlock(dev);
 
 		synchronize_net();

---
base-commit: 647b81ddefc6364290e67bf33c89d54971f8995e
change-id: 20261103-napi-timer-cancel-fa0a285fd581

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

