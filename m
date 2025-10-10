From: Shubhang Kaushik <shubhang@os.amperecomputing.com>
Date: Fri, 10 Oct 2025 13:38:17 -0700
Subject: [PATCH] sched/fair: Add helper to handle leaf cfs_rq addition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251010-sched-cfs-refactor-propagate-v1-1-b5928aa36771@os.amperecomputing.com>
X-B4-Tracking: v=1; b=H4sIALhu6WgC/x3MQQqEMAxA0atI1gbaOg7MXGVwEWKq2diSiAji3
 S2zfPD5F7iYisO3u8DkUNeyNcS+A15pWwR1boYU0hhDDOi8yoycHU0y8V4Mq5VKC+2C8h5eI6V
 PzANDW9TW6Pnf/6b7fgBmh82IbgAAAA==
X-Change-ID: 20251010-sched-cfs-refactor-propagate-e6345a291f3c
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>
Cc: Shubhang Kaushik <sh@gentwo.org>, Christopher Lameter <cl@gentwo.org>, 
 linux-kernel@vger.kernel.org, 
 Shubhang Kaushik <shubhang@os.amperecomputing.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760128713; l=2865;
 i=shubhang@os.amperecomputing.com; s=20251010; h=from:subject:message-id;
 bh=PoMBnuR5rndeOerIM079JrSnbV5lxjXSoJlYvGNDmFk=;
 b=Pnfun07Y50EISghGQEvlrJChPVOFGksQ6XRZQu0/jfMWv6keif6pHq7dPcfC3QL1n8Bk2BVGB
 kX5ls7ykMs9CF9yDaTgjGVZ7ETv2Nl0RHZLSZC1aNgRC8aZDFV7Frkq
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
Refactor repeated cfs_rq leaf logic in `propagate_entity_cfs_rq()`
into a new helper function, `__cfs_rq_maybe_add_leaf()`, to
remove code duplication and improve readability.
---
 kernel/sched/fair.c | 24 ++++++++++++++----------
 1 file changed, 14 insertions(+), 10 deletions(-)

diff --git a/kernel/sched/fair.c b/kernel/sched/fair.c
index bc0b7ce8a65d6bbe616953f530f7a02bb619537c..fe714c68f0ef52c08c552ce93741f29df95d7d1c 100644
--- a/kernel/sched/fair.c
+++ b/kernel/sched/fair.c
@@ -13159,6 +13159,18 @@ prio_changed_fair(struct rq *rq, struct task_struct *p, int oldprio)
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
@@ -13167,14 +13179,7 @@ static void propagate_entity_cfs_rq(struct sched_entity *se)
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
@@ -13184,8 +13189,7 @@ static void propagate_entity_cfs_rq(struct sched_entity *se)
 
 		update_load_avg(cfs_rq, se, UPDATE_TG);
 
-		if (!cfs_rq_pelt_clock_throttled(cfs_rq))
-			list_add_leaf_cfs_rq(cfs_rq);
+		__cfs_rq_maybe_add_leaf(cfs_rq);
 	}
 }
 #else /* !CONFIG_FAIR_GROUP_SCHED: */

---
base-commit: 0d97f2067c166eb495771fede9f7b73999c67f66
change-id: 20251010-sched-cfs-refactor-propagate-e6345a291f3c

Best regards,
-- 
Shubhang Kaushik <shubhang@os.amperecomputing.com>

