From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Tue, 03 Nov 2026 16:43:29 -0500
Subject: [PATCH net-next v5 5/6] tls: send a KeyUpdate at the record limit
 and on request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-keyupdate-rfc-v5-5-de1ab90a88d5@gmail.com>
References: <20261103-keyupdate-rfc-v5-0-de1ab90a88d5@gmail.com>
In-Reply-To: <20261103-keyupdate-rfc-v5-0-de1ab90a88d5@gmail.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Hannes Reinecke <hare@kernel.org>, Chuck Lever <cel@kernel.org>, 
 kernel-tls-handshake@lists.linux.dev, linux-nvme@lists.infradead.org, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Martin Belanger <martin.nvme.dev@gmail.com>, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793742206; l=13080;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=zZ8XslSIKg7pJFzjGvC+bep8aUoBjQU39xlvvTne8Yc=;
 b=MtQMAwMrdSuM2mlPGG3H94txM/TXkmsmfnjTBRcrA7r7SpUHbKGgt39h8+d3b4FNM4HItrxXC
 ffAXxDpLs2VA9zfeSs5qw8Tdtmn/6bqN8MdjC/+9Lc98jYwx2pXUnqk
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

RFC 9846 section 5.5 requires a key update before the key reaches its
usage limit, 2^24.5 full-size records for AES-GCM. The limit counts
records, and only the record layer knows where records start and end.
Section 4.7.3 also requires a reply to a KeyUpdate with
update_requested, sent before the next Application Data record. Both
need a KeyUpdate at an exact position in the record stream.

For a socket with a registered TX secret, send a KeyUpdate before the
next Application Data record when the key has protected 2^24 records, as
GnuTLS does, or when the peer asked for one. ChaCha20-Poly1305 has no
record limit. The KeyUpdate is sent as a handshake record, which closes
the open data record first. Pending encryptions are then completed, and
only then is the next key installed.

Add TLS_TX_KEY_UPDATE to send a KeyUpdate now, optionally asking the
peer to update too. It can only bring a KeyUpdate forward: the record
limit is enforced either way. Following section 4.7.3, a new request
to the peer waits for the answer to the previous one, and no more than
2^48-1 epochs are used.

Reviewed-by: Hannes Reinecke <hare@kernel.org>
Reviewed-by: Chuck Lever <cel@kernel.org>
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 Documentation/networking/tls.rst |  17 ++++
 include/net/tls.h                |   5 +-
 include/uapi/linux/tls.h         |   1 +
 net/tls/tls.h                    |   1 +
 net/tls/tls_keyupdate.c          |   5 ++
 net/tls/tls_main.c               |  38 ++++++++-
 net/tls/tls_sw.c                 | 163 +++++++++++++++++++++++++++++++++++++++
 7 files changed, 228 insertions(+), 2 deletions(-)

diff --git a/Documentation/networking/tls.rst b/Documentation/networking/tls.rst
index 2e011bd1ce4a..69752a6d67df 100644
--- a/Documentation/networking/tls.rst
+++ b/Documentation/networking/tls.rst
@@ -326,6 +326,23 @@ direction is then left to the application again.
 
 The secrets cannot be read back.
 
+With a registered TX secret, the kernel sends a KeyUpdate before the key
+reaches its record limit (RFC 9846, section 5.5): after 2^24 records, except
+for ChaCha20-Poly1305, which has no limit. It also sends one before the next
+record when a received KeyUpdate asks for it. With a registered RX secret,
+the kernel processes a received KeyUpdate and does not pass the record to
+the application. A peer that sends more than 8 KeyUpdates in one second ends
+the connection.
+
+TLS_TX_KEY_UPDATE
+~~~~~~~~~~~~~~~~~
+
+TLS 1.3 only. Send a KeyUpdate now and install the next TX key. Needs a
+registered TX secret. The value is an ``int``: 0 to send a KeyUpdate, 1 to
+also ask the peer to update its key. Asking the peer needs a registered RX
+secret, and fails with ``EBUSY`` until the peer has answered the previous
+request.
+
 Statistics
 ==========
 
diff --git a/include/net/tls.h b/include/net/tls.h
index a5bc28a7d1f5..d3123b17030c 100644
--- a/include/net/tls.h
+++ b/include/net/tls.h
@@ -282,9 +282,12 @@ struct tls_context {
 	union tls_crypto_context crypto_send;
 	union tls_crypto_context crypto_recv;
 
-	/* Registered for KeyUpdate, protected by the socket lock */
+	/* KeyUpdate state, protected by the socket lock */
 	struct tls_traffic_secret tx_secret;
 	struct tls_traffic_secret rx_secret;
+	u64 tx_key_updates;		/* KeyUpdates sent */
+	bool tx_key_update_reply;	/* peer set update_requested */
+	bool tx_key_update_asked;	/* we set it, no answer yet */
 
 	struct list_head list;
 	refcount_t refcount;
diff --git a/include/uapi/linux/tls.h b/include/uapi/linux/tls.h
index d1b136ecea96..c85408cb6ce7 100644
--- a/include/uapi/linux/tls.h
+++ b/include/uapi/linux/tls.h
@@ -44,6 +44,7 @@
 #define TLS_TX_MAX_PAYLOAD_LEN	5	/* Maximum plaintext size */
 #define TLS_TX_TRAFFIC_SECRET	6	/* TLS 1.3 TX traffic secret */
 #define TLS_RX_TRAFFIC_SECRET	7	/* TLS 1.3 RX traffic secret */
+#define TLS_TX_KEY_UPDATE	8	/* Send a TLS 1.3 KeyUpdate now */
 
 /* Supported versions */
 #define TLS_VERSION_MINOR(ver)	((ver) & 0xFF)
diff --git a/net/tls/tls.h b/net/tls/tls.h
index 63ece8074985..d12c9278c814 100644
--- a/net/tls/tls.h
+++ b/net/tls/tls.h
@@ -151,6 +151,7 @@ int tls_hkdf_expand_label(const u8 *secret, size_t secret_len,
 			  const char *label, u8 *out, size_t out_len);
 int tls_keyupdate_rekey(struct sock *sk, int tx);
 int tls_keyupdate_rx(struct sock *sk, struct sk_buff *skb);
+int tls_sw_key_update(struct sock *sk, int request);
 int tls_set_sw_offload(struct sock *sk, int tx,
 		       struct tls_crypto_info *new_crypto_info);
 void tls_update_rx_zc_capable(struct tls_context *tls_ctx);
diff --git a/net/tls/tls_keyupdate.c b/net/tls/tls_keyupdate.c
index b9e1ecfc59c4..fdd981ad9a40 100644
--- a/net/tls/tls_keyupdate.c
+++ b/net/tls/tls_keyupdate.c
@@ -151,5 +151,10 @@ int tls_keyupdate_rx(struct sock *sk, struct sk_buff *skb)
 	}
 	TLS_INC_STATS(sock_net(sk), LINUX_MIB_TLSRXREKEYOK);
 
+	/* Any KeyUpdate from the peer answers our update_requested */
+	ctx->tx_key_update_asked = false;
+	if (msg[4] == TLS_KEY_UPDATE_REQUESTED)
+		ctx->tx_key_update_reply = true;
+
 	return 0;
 }
diff --git a/net/tls/tls_main.c b/net/tls/tls_main.c
index 3ab71e98527a..b19e6946dbae 100644
--- a/net/tls/tls_main.c
+++ b/net/tls/tls_main.c
@@ -765,10 +765,14 @@ static int do_tls_setsockopt_conf(struct sock *sk, sockptr_t optval,
 		/* The registered secret no longer matches the key. The RX
 		 * secret also needs the TX one, see do_tls_setsockopt_secret().
 		 */
-		if (tx)
+		if (tx) {
 			memzero_explicit(&ctx->tx_secret,
 					 sizeof(ctx->tx_secret));
+			ctx->tx_key_update_reply = false;
+		}
 		memzero_explicit(&ctx->rx_secret, sizeof(ctx->rx_secret));
+		/* the answer now goes to user space */
+		ctx->tx_key_update_asked = false;
 		return 0;
 	}
 
@@ -1004,6 +1008,35 @@ static int do_tls_setsockopt_secret(struct sock *sk, sockptr_t optval,
 	return rc;
 }
 
+static int do_tls_setsockopt_key_update(struct sock *sk, sockptr_t optval,
+					unsigned int optlen)
+{
+	struct tls_context *ctx = tls_get_ctx(sk);
+	int value, rc;
+
+	if (sockptr_is_null(optval) || optlen != sizeof(value))
+		return -EINVAL;
+
+	if (copy_from_sockptr(&value, optval, sizeof(value)))
+		return -EFAULT;
+
+	if (value != 0 && value != 1)
+		return -EINVAL;
+
+	rc = mutex_lock_interruptible(&ctx->tx_lock);
+	if (rc)
+		return rc;
+	lock_sock(sk);
+	if (ctx->tx_conf == TLS_SW)
+		rc = tls_sw_key_update(sk, value);
+	else
+		rc = -EINVAL;
+	release_sock(sk);
+	mutex_unlock(&ctx->tx_lock);
+
+	return rc;
+}
+
 static int do_tls_setsockopt(struct sock *sk, int optname, sockptr_t optval,
 			     unsigned int optlen)
 {
@@ -1044,6 +1077,9 @@ static int do_tls_setsockopt(struct sock *sk, int optname, sockptr_t optval,
 					      optname == TLS_TX_TRAFFIC_SECRET);
 		release_sock(sk);
 		break;
+	case TLS_TX_KEY_UPDATE:
+		rc = do_tls_setsockopt_key_update(sk, optval, optlen);
+		break;
 	default:
 		rc = -ENOPROTOOPT;
 		break;
diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 027c32edaf85..433a43d13a87 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -40,6 +40,7 @@
 #include <linux/module.h>
 #include <linux/kernel.h>
 #include <linux/splice.h>
+#include <linux/unaligned.h>
 #include <crypto/aead.h>
 
 #include <net/strparser.h>
@@ -763,6 +764,8 @@ static int tls_sw_sendmsg_splice(struct sock *sk, struct msghdr *msg,
 	return 0;
 }
 
+static int tls_tx_maybe_update_key(struct sock *sk, int flags);
+
 static int tls_sw_sendmsg_locked(struct sock *sk, struct msghdr *msg,
 				 size_t size)
 {
@@ -805,6 +808,19 @@ static int tls_sw_sendmsg_locked(struct sock *sk, struct msghdr *msg,
 			goto send_end;
 		}
 
+		/* Check before each new record: one call can write many
+		 * records, and a KeyUpdate reply must go before the next
+		 * one. A send that failed before it copied any data leaves
+		 * an empty open record. The KeyUpdate itself is a handshake
+		 * record.
+		 */
+		if ((!ctx->open_rec || !ctx->open_rec->msg_plaintext.sg.size) &&
+		    record_type == TLS_RECORD_TYPE_DATA) {
+			ret = tls_tx_maybe_update_key(sk, msg->msg_flags);
+			if (ret)
+				goto send_end;
+		}
+
 		if (ctx->open_rec)
 			rec = ctx->open_rec;
 		else
@@ -1005,6 +1021,153 @@ static int tls_sw_sendmsg_locked(struct sock *sk, struct msghdr *msg,
 	return copied > 0 ? copied : ret;
 }
 
+/* RFC 9846 section 5.5 allows 2^24.5 full-size records per AES-GCM key.
+ * Send the KeyUpdate a little earlier.
+ */
+#define TLS_KEYUPDATE_TX_RECORDS	BIT_ULL(24)
+
+/* Section 4.7.3: the epoch must not exceed 2^48-1. The application
+ * traffic secrets start at epoch 3.
+ */
+#define TLS_KEYUPDATE_MAX		(BIT_ULL(48) - 4)
+
+/* Send a KeyUpdate with the current key, then install the next key.
+ * Called with tx_lock held and the socket locked.
+ */
+static int tls_tx_key_update(struct sock *sk, u8 request, int flags)
+{
+	u8 body[TLS_KEYUPDATE_MSG_SIZE] = {
+		TLS_HANDSHAKE_KEYUPDATE, 0, 0, 1, request
+	};
+	struct tls_context *tls_ctx = tls_get_ctx(sk);
+	struct tls_sw_context_tx *ctx = tls_sw_ctx_tx(tls_ctx);
+	u8 record_type = TLS_RECORD_TYPE_HANDSHAKE;
+	union {
+		struct cmsghdr cmsg;
+		u8 buf[CMSG_SPACE(sizeof(record_type))];
+	} ctrl = {};
+	struct msghdr msg = {};
+	struct cmsghdr *cmsg;
+	struct kvec iov;
+	int ret;
+
+	msg.msg_control = &ctrl;
+	msg.msg_controllen = sizeof(ctrl);
+	msg.msg_flags = flags & (MSG_DONTWAIT | MSG_NOSIGNAL);
+
+	cmsg = CMSG_FIRSTHDR(&msg);
+	cmsg->cmsg_level = SOL_TLS;
+	cmsg->cmsg_type = TLS_SET_RECORD_TYPE;
+	cmsg->cmsg_len = CMSG_LEN(sizeof(record_type));
+	memcpy(CMSG_DATA(cmsg), &record_type, sizeof(record_type));
+
+	iov.iov_base = body;
+	iov.iov_len = sizeof(body);
+	iov_iter_kvec(&msg.msg_iter, ITER_SOURCE, &iov, 1, sizeof(body));
+
+	/* A control record closes the open record first, so all data
+	 * written so far goes out with the current key, ahead of the
+	 * KeyUpdate.
+	 */
+	ret = tls_sw_sendmsg_locked(sk, &msg, sizeof(body));
+	if (ret < 0)
+		return ret;
+
+	/* Nothing may be encrypted with the next key before the KeyUpdate
+	 * is encrypted with the current one.
+	 */
+	ret = tls_encrypt_async_wait(ctx);
+	if (!ret)
+		ret = tls_keyupdate_rekey(sk, 1);
+	if (ret) {
+		/* The peer expects the next key: the connection is lost */
+		TLS_INC_STATS(sock_net(sk), LINUX_MIB_TLSTXREKEYERROR);
+		tls_err_abort(sk, ret);
+		return ret;
+	}
+
+	TLS_INC_STATS(sock_net(sk), LINUX_MIB_TLSTXREKEYOK);
+	tls_ctx->tx_key_updates++;
+	if (request == TLS_KEY_UPDATE_NOT_REQUESTED)
+		tls_ctx->tx_key_update_reply = false;
+
+	return 0;
+}
+
+/* Send a KeyUpdate if one is due: in reply to the peer's
+ * update_requested (RFC 9846 section 4.7.3), or before the key reaches
+ * its record limit (section 5.5). ChaCha20-Poly1305 has no record limit:
+ * the sequence number would wrap first.
+ */
+static int tls_tx_maybe_update_key(struct sock *sk, int flags)
+{
+	struct tls_context *ctx = tls_get_ctx(sk);
+	bool limit;
+
+	if (likely(!ctx->tx_secret.len))
+		return 0;
+
+	limit = ctx->prot_info.cipher_type != TLS_CIPHER_CHACHA20_POLY1305 &&
+		get_unaligned_be64(ctx->tx.rec_seq) >= TLS_KEYUPDATE_TX_RECORDS;
+	if (!limit && !ctx->tx_key_update_reply)
+		return 0;
+
+	if (ctx->tx_key_updates >= TLS_KEYUPDATE_MAX) {
+		/* Ignore update_requested. At the record limit the
+		 * connection must end.
+		 */
+		ctx->tx_key_update_reply = false;
+		return limit ? -EKEYEXPIRED : 0;
+	}
+
+	return tls_tx_key_update(sk, TLS_KEY_UPDATE_NOT_REQUESTED, flags);
+}
+
+/**
+ * tls_sw_key_update - send a KeyUpdate now, for TLS_TX_KEY_UPDATE
+ * @sk: socket
+ * @request: non-zero to also ask the peer to update its key
+ *
+ * Called with tx_lock held and the socket locked.
+ *
+ * Return: 0 on success, or a negative errno.
+ */
+int tls_sw_key_update(struct sock *sk, int request)
+{
+	struct tls_context *ctx = tls_get_ctx(sk);
+	int ret;
+
+	if (!ctx->tx_secret.len)
+		return -EINVAL;
+
+	if (request) {
+		/* Only the kernel sees the answer */
+		if (!ctx->rx_secret.len)
+			return -EINVAL;
+		/* Section 4.7.3: wait for the answer to the previous one */
+		if (ctx->tx_key_update_asked)
+			return -EBUSY;
+	}
+
+	if (ctx->tx_key_updates >= TLS_KEYUPDATE_MAX - 1)
+		return -EKEYEXPIRED;
+
+	/* A reply must carry update_not_requested */
+	if (request && ctx->tx_key_update_reply) {
+		ret = tls_tx_key_update(sk, TLS_KEY_UPDATE_NOT_REQUESTED,
+					MSG_NOSIGNAL);
+		if (ret)
+			return ret;
+	}
+
+	ret = tls_tx_key_update(sk, request ? TLS_KEY_UPDATE_REQUESTED :
+				TLS_KEY_UPDATE_NOT_REQUESTED, MSG_NOSIGNAL);
+	if (!ret && request)
+		ctx->tx_key_update_asked = true;
+
+	return ret;
+}
+
 int tls_sw_sendmsg(struct sock *sk, struct msghdr *msg, size_t size)
 {
 	struct tls_context *tls_ctx = tls_get_ctx(sk);

-- 
2.53.0

