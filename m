From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:46:00 -0500
Subject: [PATCH 2/3] kprobes: Do not disarm unhashed optprobe on dispatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-kprobes-optprobe-state-v1-2-6aaac612abe6@columbia.edu>
References: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
In-Reply-To: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793731559; l=1584;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=Om3AtKcwPFWlxp01iOZS0Qnp5RPyFOsMjUmMCXTC9sk=;
 b=1mdCWbPBhnKiRso1MCKdtJtHCkzmU3TM5i/hj61G24x3drWztp65eK3l8QVJDc8KSnZUQYBVc
 sgkk/8Jc9MgB/2y4/yBoQOhs73Zz33TfD9en9LJ5JGmL/a+ZWmdFyhj
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A new probe at the address of a force-unoptimized probe can stop
firing.  When unoptimize_kprobe() force-unoptimizes an unused probe it
disarms and unhashes it, but the next dispatch disarms it again.  If a
new probe was registered at the same address in the meantime, the
second disarm clears the new probe's int3.  For a module address the
same disarm would write to freed module text after rmmod.

Skip the disarm for unhashed probes since they're always disarmed before
they're unhashed.  With the fix, the new probe fires.

Fixes: 06e0d3b89da1 ("kprobes: Make optprobe optimizer multi-generational and asynchronous")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 kernel/kprobes.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 4c35cc24aadc..84a5f68476eb 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -631,8 +631,12 @@ static void do_unoptimize_kprobes(struct list_head *unopt_list,
 	list_for_each_entry_safe(op, tmp, free_list, list) {
 		/* Switching from detour code to origin */
 		op->kp.flags &= ~KPROBE_FLAG_OPTIMIZED;
-		/* Disarm probes if marked disabled and not gone */
-		if (kprobe_disabled(&op->kp) && !kprobe_gone(&op->kp))
+		/*
+		 * Disarm probes if marked disabled and not gone. Unhashed probes
+		 * were disarmed before they were unhashed.
+		 */
+		if (kprobe_disabled(&op->kp) && !kprobe_gone(&op->kp) &&
+		    !hlist_unhashed(&op->kp.hlist))
 			arch_disarm_kprobe(&op->kp);
 		if (kprobe_unused(&op->kp)) {
 			/*

-- 
2.53.0

