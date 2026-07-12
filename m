From: Northernside <git@northernsi.de>
Date: Sun, 12 Jul 2026 15:39:28 +0200
Subject: [PATCH RFC net-next] tls: sw: coalesce records in
 tls_sw_splice_read()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-tls-splice-coalesce-v1-1-03e073c96719@northernsi.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFrxJm7UATaQW3ggdwW1ykk6mOhLRko
 hRK796ou//4vLeCchZWOJsVMn9EZUoV7MEAPX16MEqoDK5xXXOyDktU1DkKMdLkI2sdIdghtKP
 v3JGgmnPmUZZftYfb9WISF0y8FLj/X30PL6byDcO27QtDcV6FAAAA
X-Change-ID: 20260712-tls-splice-coalesce-dd1bd5fa623c
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Northernside <git@northernsi.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783863567; l=6152;
 i=git@northernsi.de; s=20260712; h=from:subject:message-id;
 bh=owDZgaho1ntNrpexIaPlLSnhdvuDcEG4zwQ0wTkpsxA=;
 b=qxNlMZ9xjsK0IzbT0BZc8hCiDKCzcAquUoZwFjLbV7WUeKyUPF2yozsXJybkEWU/MeFjk/lhU
 jFD8M/yE/1sA6t3hni5tkO5Cl5h162AAG2dKN2EplhZssuiZo0prRYQ
X-Developer-Key: i=git@northernsi.de; a=ed25519;
 pk=BMN+nWVka4U/ivwhMm3TeWWdxHstESv4QrGNobOqNaw=
X-Endpoint-Received: by B4 Relay for git@northernsi.de/20260712 with auth_id=867
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tls_sw_splice_read() currently returns a single TLS record per call.
It dequeues (or decrypts) one record, splices it into the pipe and
returns. Draining a stream therefore costs one splice() syscall per
~16KB record, unlike tls_sw_recvmsg() which already coalesces multiple
records into the caller's buffer in a single call.

With this splice_read coalesces the same way by looping over ready
records, splicing each into the pipe, until the requested length is
reached, the pipe cannot take another record or a non DATA record is
hit.

Blocking behaviour is deliberately preserved.
Only the first record may block:

 - data records after the first are fetched with a nonblocking wait
   so a short splice is returned rather than sleeping for more input

 - a further record is only started if it already fits in the pipe, so
   the loop never turns a short read into a blocking
   skb_splice_bits() where the original single record path would not
   have blocked

A non DATA record met mid batch is left on rx_list and returned on the
next call. The copied ?: err return masks the -EINVAL exactly as
tls_sw_recvmsg() does for mid batch errors. When it is the first
record the -EINVAL behaviour is unchanged.

Since the loop can decrypt many records under a single reader lock,
the socket backlog is flushed periodically between records via
tls_read_flush_backlog(), like tls_sw_recvmsg() and tls_sw_read_sock()
already do and the released state is fed back into the next
tls_rx_rec_wait() call. Waits after the first record pass has_copied
so a pending sk_err is preserved rather than consumed by a short
splice.

Measured on a single stream (TLS 1.3, AES-128-GCM, loopback, 16KB
records), draining an upload dropped from 64 splice syscalls per MiB
(one per record) to ~12/MiB and throughput rose from ~2.2 to
~2.8 GiB/s, reaching parity with what tls_sw_recvmsg() achieves on
the same workload.

read()/recvmsg() users should see no change. This only brings the
zerocopy splice path (e.g. a proxy splicing a TLS socket to a backend
fd) to parity.

Signed-off-by: Northernside <git@northernsi.de>
---
 net/tls/tls_sw.c | 101 +++++++++++++++++++++++++++++++++++++------------------
 1 file changed, 69 insertions(+), 32 deletions(-)

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index d4afc90fd796..8bc0361e3bf4 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -1986,8 +1986,11 @@ ssize_t tls_sw_splice_read(struct socket *sock,  loff_t *ppos,
 {
 	struct tls_context *tls_ctx = tls_get_ctx(sock->sk);
 	struct tls_sw_context_rx *ctx = tls_sw_ctx_rx(tls_ctx);
+	struct tls_prot_info *prot = &tls_ctx->prot_info;
 	struct strp_msg *rxm = NULL;
 	struct sock *sk = sock->sk;
+	size_t flushed_at = 0;
+	bool released = true;
 	struct tls_msg *tlm;
 	struct sk_buff *skb;
 	ssize_t copied = 0;
@@ -1998,47 +2001,81 @@ ssize_t tls_sw_splice_read(struct socket *sock,  loff_t *ppos,
 	if (err < 0)
 		return err;
 
-	if (!skb_queue_empty(&ctx->rx_list)) {
-		skb = __skb_dequeue(&ctx->rx_list);
-	} else {
-		struct tls_decrypt_arg darg;
+	/* Coalesce successive DATA records into the pipe, the way
+	 * tls_sw_recvmsg() coalesces into the msg buffer, instead of
+	 * returning one record per call. Only the first record may block.
+	 */
+	while (copied < len) {
+		bool first = !copied;
 
-		err = tls_rx_rec_wait(sk, flags & SPLICE_F_NONBLOCK,
-				      true, false);
-		if (err <= 0)
-			goto splice_read_end;
+		if (!skb_queue_empty(&ctx->rx_list)) {
+			skb = __skb_dequeue(&ctx->rx_list);
+		} else {
+			struct tls_decrypt_arg darg;
 
-		memset(&darg.inargs, 0, sizeof(darg.inargs));
+			err = tls_rx_rec_wait(sk,
+					      first ? (flags & SPLICE_F_NONBLOCK) : true,
+					      released, !first);
+			if (err <= 0)
+				goto splice_read_end;
 
-		err = tls_rx_one_record(sk, NULL, &darg);
-		if (err < 0)
-			goto splice_read_end;
+			memset(&darg.inargs, 0, sizeof(darg.inargs));
 
-		tls_rx_rec_done(ctx);
-		skb = darg.skb;
-	}
+			err = tls_rx_one_record(sk, NULL, &darg);
+			if (err < 0)
+				goto splice_read_end;
 
-	rxm = strp_msg(skb);
-	tlm = tls_msg(skb);
+			released = tls_read_flush_backlog(sk, prot,
+							  len - copied, 0,
+							  copied, &flushed_at);
+			tls_rx_rec_done(ctx);
+			skb = darg.skb;
+		}
 
-	/* splice does not support reading control messages */
-	if (tlm->control != TLS_RECORD_TYPE_DATA) {
-		err = -EINVAL;
-		goto splice_requeue;
-	}
+		rxm = strp_msg(skb);
+		tlm = tls_msg(skb);
 
-	chunk = min_t(unsigned int, rxm->full_len, len);
-	copied = skb_splice_bits(skb, sk, rxm->offset, pipe, chunk, flags);
-	if (copied < 0)
-		goto splice_requeue;
+		/* splice does not support reading control messages
+		 * mid batch the record is left on rx_list for the next call
+		 */
+		if (tlm->control != TLS_RECORD_TYPE_DATA) {
+			err = -EINVAL;
+			goto splice_requeue;
+		}
 
-	if (copied < rxm->full_len) {
-		rxm->offset += copied;
-		rxm->full_len -= copied;
-		goto splice_requeue;
-	}
+		/* Records after the first must not block on pipe space,
+		 * stop if this one does not already fit
+		 */
+		if (!first) {
+			unsigned int need = DIV_ROUND_UP(rxm->full_len,
+							 PAGE_SIZE);
+
+			if (pipe_occupancy(pipe->head, pipe->tail) + need >
+			    pipe->max_usage) {
+				__skb_queue_head(&ctx->rx_list, skb);
+				goto splice_read_end;
+			}
+		}
+
+		chunk = min_t(unsigned int, rxm->full_len, len - copied);
+		chunk = skb_splice_bits(skb, sk, rxm->offset, pipe, chunk,
+					flags);
+		if (chunk < 0) {
+			err = chunk;
+			goto splice_requeue;
+		}
 
-	consume_skb(skb);
+		copied += chunk;
+
+		/* pipe full, requeue the remainder */
+		if (chunk < rxm->full_len) {
+			rxm->offset += chunk;
+			rxm->full_len -= chunk;
+			goto splice_requeue;
+		}
+
+		consume_skb(skb);
+	}
 
 splice_read_end:
 	tls_rx_reader_unlock(sk, ctx);

---
base-commit: f6f3b36c15ed44de1fbb44e645e4fae8c4a4453e
change-id: 20260712-tls-splice-coalesce-dd1bd5fa623c

Best regards,
--  
Northernside <git@northernsi.de>

