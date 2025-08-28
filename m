From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:09 +0300
Subject: [PATCH v2 07/15] bcachefs: Fix missing c->usage updates from early
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-7-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1234; i=himikof@gmail.com;
 h=from:subject:message-id; bh=ANX9w19sEjOEn5vKRZr+Om3Rozy2fcgzJVXQu2XTjfA=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDm4O/qIYmgD049gp+fLf06fr3Poy1MF/pbUnfGXt
 dPmdxqd7yhlYRDjYpAVU2T5sOTrnzWZ1n8shfYawsxhZQIZwsDFKQATqVnB8L8q6cKap3MOpq6Z
 8OPop91KRiYXfr6eHJe+ua0pR2lb5YwcRoaGjBzGk+I7bNdc2bz4EtcjnYzLk3gjTzzU8G24dZw
 l1JwbAA==
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make do_bch2_trans_commit_to_journal_replay apply global FS usage
updates stored in trans->fs_usage_delta, too.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/btree_trans_commit.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/bcachefs/btree_trans_commit.c b/fs/bcachefs/btree_trans_commit.c
index 5fa7f2f9f1e9d0ddd1d4675774321b519313f477..e3f069ad4002e2b007600fb41cd220d13386d37f 100644
--- a/fs/bcachefs/btree_trans_commit.c
+++ b/fs/bcachefs/btree_trans_commit.c
@@ -970,6 +970,7 @@ do_bch2_trans_commit_to_journal_replay(struct btree_trans *trans,
 
 	struct bkey_i *accounting;
 retry:
+	memset(&trans->fs_usage_delta, 0, sizeof(trans->fs_usage_delta));
 	percpu_down_read(&c->mark_lock);
 	for (accounting = btree_trans_subbuf_base(trans, &trans->accounting);
 	     accounting != btree_trans_subbuf_top(trans, &trans->accounting);
@@ -981,6 +982,8 @@ do_bch2_trans_commit_to_journal_replay(struct btree_trans *trans,
 		if (ret)
 			goto revert_fs_usage;
 	}
+	/* Only fatal errors are possible later, so no need to revert this */
+	bch2_trans_account_disk_usage_change(trans);
 	percpu_up_read(&c->mark_lock);
 
 	trans_for_each_update(trans, i) {

-- 
2.50.1

