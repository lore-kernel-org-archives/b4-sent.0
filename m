From: Mani Tofigh <mt4022@columbia.edu>
Date: Thu, 05 Nov 2026 15:32:12 -0500
Subject: [PATCH v2 1/3] kprobes: Disarm disabled optprobe on forced
 unoptimization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-kprobes-optprobe-state-v2-1-7a2f5290baa0@columbia.edu>
References: <20261105-kprobes-optprobe-state-v2-0-7a2f5290baa0@columbia.edu>
In-Reply-To: <20261105-kprobes-optprobe-state-v2-0-7a2f5290baa0@columbia.edu>
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793910731; l=2758;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=P+y8hEYt4+rURc1WfT56NFQrukM5dnD5O1ElqHoK6k4=;
 b=g4Vej81DGMv71RaTmwcVscVn0Tsi4i01sNGwRqDTpHJhsCLaooLn9V5Hn8rhjAV55Fu49N1Bg
 y15Kl1B+rhcARZalbXqs/cIhsuEja57c5W4JBZVFO6GVhOpD4vMY704
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A disabled optimized probe can be freed with its int3 still in the
text.  It waits on the unoptimizing list for the optimizer to remove its
jump.  If another probe is armed on one of the bytes that jump replaced,
unoptimize_kprobe() forces the unoptimization and moves the disabled
probe straight to a cooling list without removing its int3:

  Task A (tracefs)                       Task B (optimizer)
  disable k1
    /* k1 queued to unoptimize */
                                         /* still on an earlier batch */
  enable k2 on a byte k1's jump replaced
    unoptimize_kprobe(k1, true)
      /* int3 back, k1 on a cooling list */
  remove k1
    /* k1 freed, int3 left in the text */

The next call into the function then oopses:

  [    9.924313] Oops: int3: 0000 [#1] SMP KASAN NOPTI
  [    9.925627] CPU: 0 UID: 0 PID: 68 Comm: kprobeopt Tainted: G        W            7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [    9.930933] RIP: 0010:__do_sys_sysinfo+0x8/0xe0
  ...
  [    9.949348] Call Trace:
  [    9.949890]  <TASK>
  [    9.950404]  do_syscall_64+0xfb/0x590
  [    9.952027]  entry_SYSCALL_64_after_hwframe+0x77/0x7f
  ...
  [    9.966436]  </TASK>
  ...
  [    9.968009] Kernel panic - not syncing: Fatal exception in interrupt

Disarm a disabled probe on that path before it goes to the freeing or
cooling list, like do_unoptimize_kprobes() does.  With the fix, the int3
is gone by the time the probe is freed.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 10s.

Fixes: 06e0d3b89da1 ("kprobes: Make optprobe optimizer multi-generational and asynchronous")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v2:
- Disarm a disabled probe before choosing the freeing or cooling list (Masami)

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/kprobeopt.c
---
 kernel/kprobes.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 11add929ea16..809ed63d6dd8 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -1000,9 +1000,10 @@ static void unoptimize_kprobe(struct kprobe *p, bool force)
 				 * for cooling down (or freeing if unused).
 				 */
 				force_unoptimize_kprobe(op);
+				/* Disarm probes if marked disabled and not gone */
+				if (kprobe_disabled(&op->kp) && !kprobe_gone(&op->kp))
+					arch_disarm_kprobe(&op->kp);
 				if (kprobe_unused(&op->kp)) {
-					if (!kprobe_gone(&op->kp))
-						arch_disarm_kprobe(&op->kp);
 					hlist_del_init_rcu(&op->kp.hlist);
 					list_move(&op->list, &cur->freeing_list);
 				} else {

-- 
2.53.0

