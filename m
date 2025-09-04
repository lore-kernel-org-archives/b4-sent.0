From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:36 +0300
Subject: [PATCH v3 5/7] bcachefs: Use explicit node counts in progress
 reporting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-5-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1742; i=himikof@gmail.com;
 h=from:subject:message-id; bh=W0+LRH5XYqdB0aj9wQSy1UVKyJFpf8VMp390jsXj01M=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPzJFvpSQspoUsXMa7FPvsfYctz2FdpybHpoZO/PR
 yaNxv9/dpSyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJrL3F8D/vsq8Z2/mDyrKV
 O86k/W+RV/xnbeZYkVsUFrnrrtqh9a2MDMsKtqlv4ruxIGXGB+n0tRcic7a2/fp59SyrUsDOOaU
 PutkB
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also, consider the metadata_replicas option when better
accounting is not available.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/progress.c | 24 +++++++++++++++++++++---
 1 file changed, 21 insertions(+), 3 deletions(-)

diff --git a/fs/bcachefs/progress.c b/fs/bcachefs/progress.c
index 541ee951d1c9fc3f11b5a5ac40f1d366829a5c97..8181f6d2ca3808f57bef179383bd969d9a375d5f 100644
--- a/fs/bcachefs/progress.c
+++ b/fs/bcachefs/progress.c
@@ -12,6 +12,10 @@ void bch2_progress_init(struct progress_indicator_state *s,
 
 	s->next_print = jiffies + HZ * 10;
 
+	/* This is only an estimation: nodes can have different replica counts */
+	const u32 expected_node_disk_sectors =
+		READ_ONCE(c->opts.metadata_replicas) * btree_sectors(c);
+
 	for (unsigned i = 0; i < btree_id_nr_alive(c); i++) {
 		if (!(btree_id_mask & BIT_ULL(i)))
 			continue;
@@ -19,9 +23,23 @@ void bch2_progress_init(struct progress_indicator_state *s,
 		struct disk_accounting_pos acc;
 		disk_accounting_key_init(acc, btree, .id = i);
 
-		u64 v;
-		bch2_accounting_mem_read(c, disk_accounting_pos_to_bpos(&acc), &v, 1);
-		s->nodes_total += div64_ul(v, btree_sectors(c));
+		struct {
+			u64 disk_sectors;
+			u64 total_nodes;
+			u64 inner_nodes;
+		} v = {0};
+		bch2_accounting_mem_read(c, disk_accounting_pos_to_bpos(&acc),
+			(u64 *)&v, sizeof(v) / sizeof(u64));
+
+		/*
+		 * We check for zeros to degrade gracefully when run
+		 * with un-upgraded accounting info (missing some counters).
+		 */
+
+		if (v.total_nodes != 0)
+			s->nodes_total += v.total_nodes - v.inner_nodes;
+		else
+			s->nodes_total += div_u64(v.disk_sectors, expected_node_disk_sectors);
 	}
 }
 

-- 
2.50.1

