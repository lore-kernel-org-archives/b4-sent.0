From: Nikhil Jha <njha@janestreet.com>
Date: Wed, 11 Jun 2025 15:46:39 -0400
Subject: [PATCH] sunrpc: fix loop in gss seqno cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-fix-loop-in-seqno-cache-v1-1-9f9214d60dbf@janestreet.com>
X-B4-Tracking: v=1; b=H4sIAB7dSWgC/x2MSwqAMBDFriKzdsCKH/Qq4qKMTx2QVlsQoXh3i
 8tAkkQRQRFpLBIF3BrVuwymLEh26zawLpmpruq26ozhVR8+vD9ZHUdczrNY2cGdrL2RxmKApVy
 fAVn9z9P8vh/ZbBoTaQAAAA==
X-Change-ID: 20250611-fix-loop-in-seqno-cache-6cf71c4ae9ea
To: Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, Nikhil Jha <njha@janestreet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749671220; l=1544;
 i=njha@janestreet.com; s=20250314; h=from:subject:message-id;
 bh=9sWz8NPFHiKr5lOYqBHxNwkYPRmoCG3mDz0qaSDWR0w=;
 b=5JfBNmFl00aFr2bigOweLPqYoaLoGSSxsYkIHnxGUMfe2YfbJrflSJfBxrGXHSY0dc1piph2Y
 vzhcaadtJIVBMmJy554OOcuMOdHbUKFh8QdJ9z/7/8JHbbrq/yMlrHj
X-Developer-Key: i=njha@janestreet.com; a=ed25519;
 pk=92gWYi0ImmcatlW+pFEFh9viqpRf/PE8phYeWuNeGaA=
X-Endpoint-Received: by B4 Relay for njha@janestreet.com/20250314 with auth_id=360
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There was a silly bug in the initial implementation where a loop
variable was not incremented. This commit increments the loop variable.

This bug is somewhat tricky to catch because it can only happen on loops
of two or more. If it is hit, it locks up a kernel thread in an infinite
loop.

Signed-off-by: Nikhil Jha <njha@janestreet.com>
Tested-by: Nikhil Jha <njha@janestreet.com>
---
 net/sunrpc/auth_gss/auth_gss.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/sunrpc/auth_gss/auth_gss.c b/net/sunrpc/auth_gss/auth_gss.c
index 0fa244f16876f3c434fd507b4d53c5eefd748ce4..7b943fbafcc38ba79a685589d696017e8cdc694a 100644
--- a/net/sunrpc/auth_gss/auth_gss.c
+++ b/net/sunrpc/auth_gss/auth_gss.c
@@ -1724,7 +1724,7 @@ gss_validate(struct rpc_task *task, struct xdr_stream *xdr)
 	maj_stat = gss_validate_seqno_mic(ctx, task->tk_rqstp->rq_seqnos[0], seq, p, len);
 	/* RFC 2203 5.3.3.1 - compute the checksum of each sequence number in the cache */
 	while (unlikely(maj_stat == GSS_S_BAD_SIG && i < task->tk_rqstp->rq_seqno_count))
-		maj_stat = gss_validate_seqno_mic(ctx, task->tk_rqstp->rq_seqnos[i], seq, p, len);
+		maj_stat = gss_validate_seqno_mic(ctx, task->tk_rqstp->rq_seqnos[i++], seq, p, len);
 	if (maj_stat == GSS_S_CONTEXT_EXPIRED)
 		clear_bit(RPCAUTH_CRED_UPTODATE, &cred->cr_flags);
 	if (maj_stat)

---
base-commit: 488ef3560196ee10fc1c5547e1574a87068c3494
change-id: 20250611-fix-loop-in-seqno-cache-6cf71c4ae9ea

Best regards,
-- 
Nikhil Jha <njha@janestreet.com>

