From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:32 +0300
Subject: [PATCH v3 1/7] bcachefs: Fix missing c->usage updates from early
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-1-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1278; i=himikof@gmail.com;
 h=from:subject:message-id; bh=362Enryjr7PcDprx4tSSxevQeeNm3RQLlhblMoU/MBg=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPzxzoXv15EX2omTtz4T52pgSZ7iGlFjlWoz66CuR
 NMvroxdHaUsDGJcDLJiiiwflnz9sybT+o+l0F5DmDmsTCBDGLg4BWAiWhIMfwU+BKzTsdRKjF+/
 RvNy4dwfh7PuGWx+JbP4oZloodl+0y6Gf3oJ2bdPvzp4bIalvssDnvzLYo2ydwUs9IW7nh77aPl
 2JTcA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make do_bch2_trans_commit_to_journal_replay apply global FS usage
updates stored in trans->fs_usage_delta, too.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/btree_trans_commit.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/fs/bcachefs/btree_trans_commit.c b/fs/bcachefs/btree_trans_commit.c
index 5fa7f2f9f1e9d0ddd1d4675774321b519313f477..2966971ee43eee913676e5e4203733c5c52a2678 100644
--- a/fs/bcachefs/btree_trans_commit.c
+++ b/fs/bcachefs/btree_trans_commit.c
@@ -970,6 +970,7 @@ do_bch2_trans_commit_to_journal_replay(struct btree_trans *trans,
 
 	struct bkey_i *accounting;
 retry:
+	memset(&trans->fs_usage_delta, 0, sizeof(trans->fs_usage_delta));
 	percpu_down_read(&c->mark_lock);
 	for (accounting = btree_trans_subbuf_base(trans, &trans->accounting);
 	     accounting != btree_trans_subbuf_top(trans, &trans->accounting);
@@ -983,6 +984,9 @@ do_bch2_trans_commit_to_journal_replay(struct btree_trans *trans,
 	}
 	percpu_up_read(&c->mark_lock);
 
+	/* Only fatal errors are possible later, so no need to revert this */
+	bch2_trans_account_disk_usage_change(trans);
+
 	trans_for_each_update(trans, i) {
 		ret = bch2_journal_key_insert(c, i->btree_id, i->level, i->k);
 		if (ret)

-- 
2.50.1

