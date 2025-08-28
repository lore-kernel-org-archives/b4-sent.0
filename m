From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:07 +0300
Subject: [PATCH v2 05/15] bcachefs: Fix progress reporting for unknown
 btrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-5-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=659; i=himikof@gmail.com;
 h=from:subject:message-id; bh=yQihh3I71KBB+2S7ldPtj/JAIwrsppP8EKz4G0R0YM8=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDl4bTHnBpkH6fsChI8IcpTVR1jFxEutnccntdnvk
 87FCbKzOkpZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBEmnMYGW4Fep+8Nf/cok0P
 LJN0V5Uz/Cyw/CL2t6Beo3XyrWmC74sZGV6JTm2dOE1Qnrun98wy2x2Kkqpf8zUe75L/42hoLeF
 ZyAEA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/progress.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/bcachefs/progress.c b/fs/bcachefs/progress.c
index 792fc6fef27018c73168c59857e7f3497c1969f4..541ee951d1c9fc3f11b5a5ac40f1d366829a5c97 100644
--- a/fs/bcachefs/progress.c
+++ b/fs/bcachefs/progress.c
@@ -12,7 +12,7 @@ void bch2_progress_init(struct progress_indicator_state *s,
 
 	s->next_print = jiffies + HZ * 10;
 
-	for (unsigned i = 0; i < BTREE_ID_NR; i++) {
+	for (unsigned i = 0; i < btree_id_nr_alive(c); i++) {
 		if (!(btree_id_mask & BIT_ULL(i)))
 			continue;
 

-- 
2.50.1

