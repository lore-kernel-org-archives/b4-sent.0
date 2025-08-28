From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:08 +0300
Subject: [PATCH v2 06/15] bcachefs: Partially fix old device removal with
 unknown btrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-6-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1096; i=himikof@gmail.com;
 h=from:subject:message-id; bh=bg0JYtLQrNAfIJ37svWrnw+bIZLtdUmPleY43qcm2QE=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDloYazxwsX7hNPLm3mnt3n+mPbe5/Gt+f8Tb/Lye
 n+wdfzzrqOUhUGMi0FWTJHlw5Kvf9ZkWv+xFNprCDOHlQlkCAMXpwBMZJY8wz/rX+cWid2xy96/
 wvX5lSxnC54kjqL0CCOPFztKHovNmiTP8D+F7c1r99LlUSZ7yhOW3bPYNeua2Cyj0GP5sR8k9wV
 c+cANAA==
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
index 41657deb0e3807f4968272491faea09d05ec2299..4aa7dd483cab5a400974b5824bfaf0c0af2e9331 100644
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

