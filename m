From: Quanye Yang <quanyeyang@proton.me>
Date: Sat, 10 Oct 2026 07:46:28 -0700
Subject: [PATCH net-next v3 1/2] tls: annotate lockless access to
 sk->sk_err
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-tls-fix-sk-kcsan-err-v3-1-e28aadeb31ad@proton.me>
References: <20261010-tls-fix-sk-kcsan-err-v3-0-e28aadeb31ad@proton.me>
In-Reply-To: <20261010-tls-fix-sk-kcsan-err-v3-0-e28aadeb31ad@proton.me>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 bpf@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791643590; l=4423;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=oyeMQXlYZ5OEpzoZY0Ba7hIry6yUmLmTMWGSVMly/Fw=;
 b=TMsLvdjn/QacxSqsZGsbKF1rS8ehvGN72WoxHJir1whjEPigAhCuu6YlxACj8x4Oqi7fGocpY
 0RLG+rdbfU6BxVG7YBW0U6+djPd/4r3w7Fufbao22bgzjTBh5yOXFgd
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kTLS sits on the same struct sock as TCP. do_recvmmsg() and
getsockopt(SO_ERROR) still call sock_error() without the socket lock
and clear sk_err with xchg().

tls_rx_rec_wait() already peeks when data has been copied and consumes
otherwise, but the outer if (sk_err) is an unmarked load. On the
no-data path that check-then-sock_error() window can return 0 after
another thread consumes the error. Call sock_error() once and only
return when it is non-zero; keep READ_ONCE() on the peek path.

tls_sw_sendmsg_locked(), tls_push_data(), bpf_exec_tx_verdict() and
tls_encrypt_done() read sk_err more than once. Fold those unmarked loads
into one READ_ONCE() and use that value as the returned errno. The field is
still not consumed there.

Link: https://lore.kernel.org/netdev/3d9d442f-f168-43da-87b0-010ad5a78365@redhat.com/
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/tls/tls_device.c |  5 +++--
 net/tls/tls_sw.c     | 54 ++++++++++++++++++++++++++++++++++------------------
 2 files changed, 39 insertions(+), 20 deletions(-)

diff --git a/net/tls/tls_device.c b/net/tls/tls_device.c
index f11d0528fc43..03ce83a9d4e9 100644
--- a/net/tls/tls_device.c
+++ b/net/tls/tls_device.c
@@ -444,8 +444,9 @@ static int tls_push_data(struct sock *sk,
 	if ((flags & (MSG_MORE | MSG_EOR)) == (MSG_MORE | MSG_EOR))
 		return -EINVAL;
 
-	if (unlikely(sk->sk_err))
-		return -sk->sk_err;
+	rc = -READ_ONCE(sk->sk_err);
+	if (unlikely(rc))
+		return rc;
 
 	flags |= MSG_SENDPAGE_DECRYPTED;
 	tls_push_record_flags = flags | MSG_MORE;
diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 312e51270f29..a2be1283ca93 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -473,6 +473,7 @@ static void tls_encrypt_done(void *data, int err)
 	struct scatterlist *sge;
 	struct sk_msg *msg_en;
 	struct sock *sk;
+	int skerr;
 
 	if (err == -EINPROGRESS) /* see the comment in tls_decrypt_done() */
 		return;
@@ -488,13 +489,15 @@ static void tls_encrypt_done(void *data, int err)
 	sge->offset -= prot->prepend_size;
 	sge->length += prot->prepend_size;
 
+	skerr = READ_ONCE(sk->sk_err);
+
 	/* Check if error is previously set on socket */
-	if (err || sk->sk_err) {
+	if (err || skerr) {
 		rec = NULL;
 
 		/* If err is already set on socket, return the same code */
-		if (sk->sk_err) {
-			ctx->async_wait.err = -sk->sk_err;
+		if (skerr) {
+			ctx->async_wait.err = -skerr;
 		} else {
 			ctx->async_wait.err = err;
 			tls_err_abort(sk, err);
@@ -704,10 +707,14 @@ static int bpf_exec_tx_verdict(struct sk_msg *msg, struct sock *sk,
 	int err;
 
 	err = tls_push_record(sk, flags, record_type);
-	if (err && err != -EINPROGRESS && sk->sk_err == EBADMSG) {
-		*copied -= sk_msg_free(sk, msg);
-		tls_free_open_rec(sk);
-		err = -sk->sk_err;
+	if (err && err != -EINPROGRESS) {
+		int skerr = READ_ONCE(sk->sk_err);
+
+		if (skerr == EBADMSG) {
+			*copied -= sk_msg_free(sk, msg);
+			tls_free_open_rec(sk);
+			err = -skerr;
+		}
 	}
 	return err;
 }
@@ -800,10 +807,9 @@ static int tls_sw_sendmsg_locked(struct sock *sk, struct msghdr *msg,
 	}
 
 	while (msg_data_left(msg)) {
-		if (sk->sk_err) {
-			ret = -sk->sk_err;
+		ret = -READ_ONCE(sk->sk_err);
+		if (ret)
 			goto send_end;
-		}
 
 		if (ctx->open_rec)
 			rec = ctx->open_rec;
@@ -1107,10 +1113,16 @@ tls_rx_rec_wait(struct sock *sk, bool nonblock, bool released, bool has_copied)
 	timeo = sock_rcvtimeo(sk, nonblock);
 
 	while (!tls_strp_msg_ready(ctx)) {
-		if (sk->sk_err) {
-			if (has_copied)
-				return -READ_ONCE(sk->sk_err);
-			return sock_error(sk);
+		if (has_copied) {
+			int err = READ_ONCE(sk->sk_err);
+
+			if (err)
+				return -err;
+		} else {
+			int err = sock_error(sk);
+
+			if (err)
+				return err;
 		}
 
 		if (ret < 0)
@@ -1132,10 +1144,16 @@ tls_rx_rec_wait(struct sock *sk, bool nonblock, bool released, bool has_copied)
 		 * sk_err here so a connection abort surfaces as the
 		 * actual error rather than a clean EOF.
 		 */
-		if (sk->sk_err) {
-			if (has_copied)
-				return -READ_ONCE(sk->sk_err);
-			return sock_error(sk);
+		if (has_copied) {
+			int err = READ_ONCE(sk->sk_err);
+
+			if (err)
+				return -err;
+		} else {
+			int err = sock_error(sk);
+
+			if (err)
+				return err;
 		}
 		if (sk->sk_shutdown & RCV_SHUTDOWN)
 			return 0;

-- 
2.55.0

