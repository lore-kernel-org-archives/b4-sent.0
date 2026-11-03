From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:46:01 -0500
Subject: [PATCH 3/3] kprobes: Arm reused optprobe on cooling list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-kprobes-optprobe-state-v1-3-6aaac612abe6@columbia.edu>
References: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
In-Reply-To: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793731559; l=1380;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=A4hzeYXnyu4gqCtaHPk+uqW5lGcpJ7XKim4n6VIIG3I=;
 b=WT5Kqr62jfYJJeNpsYt50OGs4bjDsKR9DqcIbR5UvllsI/9clbltJSFOEdzqct1LaUqj0mxzJ
 6o/UqV1tYYzCMRgryOZ2zzE6Y6D8XVTSRatbx2yR1gEM4FH0Kl11UJn
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A new probe that reuses an unused probe still on a cooling list doesn't
fire.  reuse_unused_kprobe() clears DISABLED without arming it, so the
probe has no int3 until it's optimized again, or ever if it can't be
(e.g., it has a post_handler).

Arm a reused cooling probe.  With the fix, it fires.

Fixes: 06e0d3b89da1 ("kprobes: Make optprobe optimizer multi-generational and asynchronous")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 kernel/kprobes.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 84a5f68476eb..59c5689299ce 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -536,6 +536,7 @@ static struct optprobe_generation optprobe_gens[OPTPROBE_GEN_MAX];
 static int optprobe_cur_gen;
 
 static void optimize_kprobe(struct kprobe *p);
+static void __arm_kprobe(struct kprobe *p);
 static struct task_struct *kprobe_optimizer_task;
 static wait_queue_head_t kprobe_optimizer_wait;
 static atomic_t optimizer_state;
@@ -1067,6 +1068,13 @@ static int reuse_unused_kprobe(struct kprobe *ap)
 	if (!kprobe_optready(ap))
 		return -EINVAL;
 
+	if (optprobe_queued_cooling(op)) {
+		/* Already disarmed. It will be optimized again upon finalize */
+		if (!kprobes_all_disarmed)
+			__arm_kprobe(ap);
+		return 0;
+	}
+
 	optimize_kprobe(ap);
 	return 0;
 }

-- 
2.53.0

