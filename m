From: Shubhang Kaushik <shubhang@os.amperecomputing.com>
Date: Thu, 06 Nov 2025 23:32:02 -0800
Subject: [PATCH RESEND] sched/fair: Add helper to handle leaf cfs_rq
 addition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251106-20251010_shubhang_os_amperecomputing_com-v1-1-7535957d8ac6@os.amperecomputing.com>
X-B4-Tracking: v=1; b=H4sIAHGgDWkC/x2NwQqDMBBEf0X2bGA30CL9FZGgyVr3oAlZLQXx3
 7v19t4wzJygXIUVXs0JlT+ikjcTahuIy7i92UkyB4/+QYRPdwMSBl2O6d8IWcO4Fq4c81qOXSw
 ycp66lOIU584j2FypPMv3vuqH6/oBb0UK2HoAAAA=
X-Change-ID: 20251106-20251010_shubhang_os_amperecomputing_com-218ddcbcf820
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Aaron Lu <ziqianlu@bytedance.com>, Josh Don <joshdon@google.com>, 
 Ben Segall <bsegall@google.com>, Shubhang Kaushik <sh@gentwo.org>, 
 "Christoph Lameter (Ampere)" <cl@gentwo.org>
Cc: linux-kernel@vger.kernel.org, 
 Shubhang Kaushik <shubhang@os.amperecomputing.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762500755; l=2695;
 i=shubhang@os.amperecomputing.com; s=20251010; h=from:subject:message-id;
 bh=aKWrfbrWZwZxexxzXXzIOYzVUS/84glWsxcQQQBhEVQ=;
 b=f7GhnM6dkbGAobj4iPP8Pbqq/tKTG2Le/PfAq2IgU5t8nEwTUwhBeTUpu6ZGpqlZTCQbOy8L8
 1G8L4yN8GFTByz2LYufKFG+++ycr/G9YbuZQ36Oq+yhmsRPMrWZyRTp
X-Developer-Key: i=shubhang@os.amperecomputing.com; a=ed25519;
 pk=jc8YIRvxPSyJaBRe5y+a4N0RXKBUEcAh8+OFhlROXPY=
X-Endpoint-Received: by B4 Relay for shubhang@os.amperecomputing.com/20251010 with auth_id=539
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor the logic for adding a cfs_rq to the leaf list into a helper
function.

The existing code repeated the logic to check if the cfs_rq was
throttled and added it to the leaf list. This change extracts that
logic into the static inline helper `__cfs_rq_maybe_add_leaf()`, which
is a more robust naming convention for an internal helper.

This refactoring removes code duplication and makes the parent function,
`propagate_entity_cfs_rq()`, cleaner and easier to read.

Signed-off-by: Shubhang Kaushik <shubhang@os.amperecomputing.com>
---
 kernel/sched/fair.c | 24 ++++++++++++++----------
 1 file changed, 14 insertions(+), 10 deletions(-)

diff --git a/kernel/sched/fair.c b/kernel/sched/fair.c
index 25970dbbb27959bc130d288d5f80677f75f8db8b..13140fab37ce7870f8079e789ff24c409747e27d 100644
--- a/kernel/sched/fair.c
+++ b/kernel/sched/fair.c
@@ -13169,6 +13169,18 @@ prio_changed_fair(struct rq *rq, struct task_struct *p, int oldprio)
 }
 
 #ifdef CONFIG_FAIR_GROUP_SCHED
+/*
+ * If a task gets attached to this cfs_rq and, before being queued,
+ * it gets migrated to another CPU (e.g., due to reasons like affinity change),
+ * this cfs_rq must remain on leaf cfs_rq list. This allows the
+ * removed load to decay properly; otherwise, it can cause a fairness problem.
+ */
+static inline void __cfs_rq_maybe_add_leaf(struct cfs_rq *cfs_rq)
+{
+	if (!cfs_rq_pelt_clock_throttled(cfs_rq))
+		list_add_leaf_cfs_rq(cfs_rq);
+}
+
 /*
  * Propagate the changes of the sched_entity across the tg tree to make it
  * visible to the root
@@ -13177,14 +13189,7 @@ static void propagate_entity_cfs_rq(struct sched_entity *se)
 {
 	struct cfs_rq *cfs_rq = cfs_rq_of(se);
 
-	/*
-	 * If a task gets attached to this cfs_rq and before being queued,
-	 * it gets migrated to another CPU due to reasons like affinity
-	 * change, make sure this cfs_rq stays on leaf cfs_rq list to have
-	 * that removed load decayed or it can cause faireness problem.
-	 */
-	if (!cfs_rq_pelt_clock_throttled(cfs_rq))
-		list_add_leaf_cfs_rq(cfs_rq);
+	__cfs_rq_maybe_add_leaf(cfs_rq);
 
 	/* Start to propagate at parent */
 	se = se->parent;
@@ -13194,8 +13199,7 @@ static void propagate_entity_cfs_rq(struct sched_entity *se)
 
 		update_load_avg(cfs_rq, se, UPDATE_TG);
 
-		if (!cfs_rq_pelt_clock_throttled(cfs_rq))
-			list_add_leaf_cfs_rq(cfs_rq);
+		__cfs_rq_maybe_add_leaf(cfs_rq);
 	}
 
 	assert_list_leaf_cfs_rq(rq_of(cfs_rq));

---
base-commit: 6146a0f1dfae5d37442a9ddcba012add260bceb0
change-id: 20251106-20251010_shubhang_os_amperecomputing_com-218ddcbcf820

Best regards,
-- 
Shubhang Kaushik <shubhang@os.amperecomputing.com>

