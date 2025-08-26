From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:17 +0300
Subject: [PATCH 11/12] bcachefs: Fix missing c->usage updates from early
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-11-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1234; i=himikof@gmail.com;
 h=from:subject:message-id; bh=ANX9w19sEjOEn5vKRZr+Om3Rozy2fcgzJVXQu2XTjfA=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5JtuOF94ZD0+bxpO3IMNria/zu89ci7D8lVLLmWs
 72yV8++11HKwiDGxSArpsjyYcnXP2syrf9YCu01hJnDygQyhIGLUwAm0v+dkWHJ3Nvfj1c8Zr39
 6ZHUleV3rD02vX6xTvTclVeCXCwMO7/OYGRoXLjZdI+Alf7C/nM74t2mss9hLIv0D5d8GOYVpGC
 ftoIVAA==
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

