From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:34 +0300
Subject: [PATCH v3 3/7] bcachefs: Relax restrictions on the number of
 accounting counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-3-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2585; i=himikof@gmail.com;
 h=from:subject:message-id; bh=JMDEcithTuURriAZkZpWhj4DluVxVEk4bXfsykzSmkQ=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPyx8+Dkpv6j3NskEso2ZDAxZN0Uf1G153Gmo8V2N
 Y97dzp/dZSyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJyO1mZHh77m3Zj8trHBaf
 Cfb5lbhj2/YncpdKM3QdjQX0QjJ4XD4xMtxNkJmdljNpLd+F0AqdAMu3sm1Lfu8qP2M/7V3Hj9+
 38tgA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make adding/removing accounting counters easier when upgrading by
removing their exact number from bch_accounting key validity invariants.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/disk_accounting.c | 11 ++++++++---
 fs/bcachefs/disk_accounting.h |  4 ++--
 2 files changed, 10 insertions(+), 5 deletions(-)

diff --git a/fs/bcachefs/disk_accounting.c b/fs/bcachefs/disk_accounting.c
index f09e43f78f13fc424d9bf22d94566d4961c8ca8e..738678362c65df6de45ef685ddb97a7d1dbd2a08 100644
--- a/fs/bcachefs/disk_accounting.c
+++ b/fs/bcachefs/disk_accounting.c
@@ -239,10 +239,12 @@ int bch2_accounting_validate(struct bch_fs *c, struct bkey_s_c k,
 			 c, accounting_key_junk_at_end,
 			 "junk at end of accounting key");
 
-	bkey_fsck_err_on(bch2_accounting_counters(k.k) != bch2_accounting_type_nr_counters[acc_k.type],
+	const unsigned nr_counters = bch2_accounting_counters(k.k);
+
+	bkey_fsck_err_on(!nr_counters || nr_counters > BCH_ACCOUNTING_MAX_COUNTERS,
 			 c, accounting_key_nr_counters_wrong,
 			 "accounting key with %u counters, should be %u",
-			 bch2_accounting_counters(k.k), bch2_accounting_type_nr_counters[acc_k.type]);
+			 nr_counters, bch2_accounting_type_nr_counters[acc_k.type]);
 fsck_err:
 	return ret;
 }
@@ -359,10 +361,13 @@ static int __bch2_accounting_mem_insert(struct bch_fs *c, struct bkey_s_c_accoun
 			    accounting_pos_cmp, &a.k->p) < acc->k.nr)
 		return 0;
 
+	struct disk_accounting_pos acc_k;
+	bpos_to_disk_accounting_pos(&acc_k, a.k->p);
+
 	struct accounting_mem_entry n = {
 		.pos		= a.k->p,
 		.bversion	= a.k->bversion,
-		.nr_counters	= bch2_accounting_counters(a.k),
+		.nr_counters	= bch2_accounting_type_nr_counters[acc_k.type],
 		.v[0]		= __alloc_percpu_gfp(n.nr_counters * sizeof(u64),
 						     sizeof(u64), GFP_KERNEL),
 	};
diff --git a/fs/bcachefs/disk_accounting.h b/fs/bcachefs/disk_accounting.h
index c3f2dc5d0c14241f3c0ae2d367d6da504df2e1ab..c0d3d7e8fda6172eb04c8b0d9cd4cd879090e480 100644
--- a/fs/bcachefs/disk_accounting.h
+++ b/fs/bcachefs/disk_accounting.h
@@ -216,9 +216,9 @@ static inline int bch2_accounting_mem_mod_locked(struct btree_trans *trans,
 
 	struct accounting_mem_entry *e = &acc->k.data[idx];
 
-	EBUG_ON(bch2_accounting_counters(a.k) != e->nr_counters);
+	const unsigned nr = min_t(unsigned, bch2_accounting_counters(a.k), e->nr_counters);
 
-	for (unsigned i = 0; i < bch2_accounting_counters(a.k); i++)
+	for (unsigned i = 0; i < nr; i++)
 		this_cpu_add(e->v[gc][i], a.v->d[i]);
 	return 0;
 }

-- 
2.50.1

