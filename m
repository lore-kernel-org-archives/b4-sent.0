From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:15 +0300
Subject: [PATCH 09/12] bcachefs: Partially fix old device removal with
 unknown btrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-9-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1096; i=himikof@gmail.com;
 h=from:subject:message-id; bh=0parkIXY7SO5IS2HFFMEgzSsAvCaekrT6rPziZOcKFE=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5LJ2nfrztwrf2UK+Ps/lvy6ZqnT9zl6yjPBz6ePC
 N/ZeYJjQ0cpC4MYF4OsmCLLhyVf/6zJtP5jKbTXEGYOKxPIEAYuTgGYyOp8hv/RM9adPRt7c351
 Wl6hj0Sj77S7okpV37d4M/I0WcWHmFxm+O8TPcf0sW7R9Zip+24V2d+qWP88KUEvRf50+rEVwW+
 NQ7gB
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Handle removal of unknown metadata only, data pointed to by unknown
btrees cannot be supported currently.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/migrate.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/bcachefs/migrate.c b/fs/bcachefs/migrate.c
index 0ef576ec45c7310423cf7cdf902cad30dba257db..d67ca56d3f431980b104ea5528cce79be88f93fb 100644
--- a/fs/bcachefs/migrate.c
+++ b/fs/bcachefs/migrate.c
@@ -121,6 +121,7 @@ static int bch2_dev_usrdata_drop(struct bch_fs *c,
 {
 	CLASS(btree_trans, trans)(c);
 
+	/* FIXME: this does not handle unknown btrees with data pointers */
 	for (unsigned id = 0; id < BTREE_ID_NR; id++) {
 		if (!btree_type_has_data_ptrs(id))
 			continue;
@@ -161,7 +162,7 @@ static int bch2_dev_metadata_drop(struct bch_fs *c,
 	bch2_bkey_buf_init(&k);
 	closure_init_stack(&cl);
 
-	for (id = 0; id < BTREE_ID_NR; id++) {
+	for (id = 0; id < btree_id_nr_alive(c); id++) {
 		bch2_trans_node_iter_init(trans, &iter, id, POS_MIN, 0, 0,
 					  BTREE_ITER_prefetch);
 retry:

-- 
2.50.1

