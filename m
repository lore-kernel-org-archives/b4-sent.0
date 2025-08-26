From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:14 +0300
Subject: [PATCH 08/12] bcachefs: Fix progress reporting for unknown btrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-8-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=698; i=himikof@gmail.com;
 h=from:subject:message-id; bh=xGkyrAFw+BdX/Ys6wNZqMpzMb7Z1sVfbEKCODOS+HVs=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5KZxPJC5/+Jthmykf9Ol2T2Rm1Zcsz3meNZ15yg2
 fnh/PF/O0pZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBEtAQZ/umqJ83y+NfK82xO
 0bPw3z+2Xdi6WSIoJUhlk/TR6TbRZ3YzMvy7OqG+LIv/9BErlfd+0gpv0r417i28u+bkdoc8F8Y
 3e9kB
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/progress.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/bcachefs/progress.c b/fs/bcachefs/progress.c
index 013eca7d6017a81390001519f20bfc4d0c6bc173..7cc16490ffa98fec34ff228cb56bd1af0f42da3d 100644
--- a/fs/bcachefs/progress.c
+++ b/fs/bcachefs/progress.c
@@ -19,7 +19,7 @@ void bch2_progress_init_inner(struct progress_indicator_state *s,
 
 	const u64 btree_id_mask = leaf_btree_id_mask | inner_btree_id_mask;
 
-	for (unsigned i = 0; i < BTREE_ID_NR; i++) {
+	for (unsigned i = 0; i < btree_id_nr_alive(c); i++) {
 		if (!(btree_id_mask & BIT_ULL(i)))
 			continue;
 

-- 
2.50.1

