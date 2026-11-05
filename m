From: Mani Tofigh <mt4022@columbia.edu>
Date: Thu, 05 Nov 2026 15:32:14 -0500
Subject: [PATCH v2 3/3] kprobes: Arm reused optprobe on cooling list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-kprobes-optprobe-state-v2-3-7a2f5290baa0@columbia.edu>
References: <20261105-kprobes-optprobe-state-v2-0-7a2f5290baa0@columbia.edu>
In-Reply-To: <20261105-kprobes-optprobe-state-v2-0-7a2f5290baa0@columbia.edu>
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793910731; l=2160;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=/HCAv1Fv22PKOX1Qzyg9tXxCq5Zh9hIH5VnZqnVHksw=;
 b=ftE/orfEOyDjW80q5zI9iiCT+8OyojyN8qC5+QqeNDmikou06iUZOqX1EUfK+MCZdeqhsGSqC
 lNfP//+EoNCABHJJ/XqJqKnqiTeGJuhQ0JUzVLKZR+GYU1DpuQF63VJ
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A new probe that reuses an unused probe still on a cooling list doesn't
fire.  reuse_unused_kprobe() clears DISABLED, so register_aggr_kprobe()
doesn't arm it and the probe has no int3 until it's optimized again, or
ever if it can't be (e.g., it has a post_handler).

Keep a reused cooling probe disabled instead, so register_aggr_kprobe()
arms it if the new probe is enabled, or enable_kprobe() does it later.
The probe is then still unused when add_new_kprobe() force-unoptimizes
it for a new probe with a post_handler, which would unhash it and queue
it for freeing.  Skip that since a cooling probe is already unoptimized.
With the fix, the new probe fires.

Fixes: 06e0d3b89da1 ("kprobes: Make optprobe optimizer multi-generational and asynchronous")
Suggested-by: Masami Hiramatsu (Google) <mhiramat@kernel.org>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v2:
- Keep a reused cooling probe disabled so register_aggr_kprobe() arms it
  only for an enabled new probe (Masami, Sashiko)
- Skip the forced unoptimization in add_new_kprobe() for a cooling probe
---
 kernel/kprobes.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 099a38ca146a..5f8ce6892bd1 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -1059,6 +1059,10 @@ static int reuse_unused_kprobe(struct kprobe *ap)
 	 */
 	op = container_of(ap, struct optimized_kprobe, kp);
 	WARN_ON_ONCE(list_empty(&op->list));
+	/* Already disarmed, the caller arms it only for an enabled probe */
+	if (optprobe_queued_cooling(op))
+		return 0;
+
 	/* Enable the probe again */
 	ap->flags &= ~KPROBE_FLAG_DISABLED;
 	/* Optimize it again. (remove from 'op->list') */
@@ -1571,7 +1575,8 @@ void kprobe_busy_end(void)
 /* Add the new probe to 'ap->list'. */
 static int add_new_kprobe(struct kprobe *ap, struct kprobe *p)
 {
-	if (p->post_handler)
+	/* A reused cooling probe is already unoptimized */
+	if (p->post_handler && !kprobe_unused(ap))
 		unoptimize_kprobe(ap, true);	/* Fall back to normal kprobe */
 
 	list_add_rcu(&p->list, &ap->list);

-- 
2.53.0

