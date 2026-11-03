From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:45:59 -0500
Subject: [PATCH 1/3] kprobes: Disarm disabled optprobe on forced
 unoptimization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-kprobes-optprobe-state-v1-1-6aaac612abe6@columbia.edu>
References: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
In-Reply-To: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793731559; l=2481;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=O1s7x+S8Y9RffIFDZ2Gdq0pngTBLL9OlQLH23gRHjU0=;
 b=6In0Ln+1sBlRCxdaltggdp9+etXkgvKBsIvLEvYDDDm+3+6RbkcyxKYAkZwZum1rM/KeRedhw
 cPeWIbqJR7lBfKHD2S2s7tGL7fxZ5f9pqw0OG70lE/H0dB+IyAMMs9d
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

Disarm a disabled probe on that path like do_unoptimize_kprobes() does.
With the fix, the int3 is gone by the time the probe is freed.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 10s.

Fixes: 06e0d3b89da1 ("kprobes: Make optprobe optimizer multi-generational and asynchronous")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/kprobeopt.c
---
 kernel/kprobes.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 11add929ea16..4c35cc24aadc 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -1006,6 +1006,9 @@ static void unoptimize_kprobe(struct kprobe *p, bool force)
 					hlist_del_init_rcu(&op->kp.hlist);
 					list_move(&op->list, &cur->freeing_list);
 				} else {
+					/* Disarm probes if marked disabled and not gone */
+					if (kprobe_disabled(&op->kp) && !kprobe_gone(&op->kp))
+						arch_disarm_kprobe(&op->kp);
 					list_move(&op->list, &cur->cooling_list);
 				}
 				kick_kprobe_optimizer();

-- 
2.53.0

