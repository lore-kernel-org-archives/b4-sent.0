From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Wed, 28 Oct 2026 09:52:52 -0400
Subject: [PATCH RFC net-next v2 2/5] tls: add socket options to register
 the traffic secrets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-keyupdate-rfc-v2-2-eb5143b4c487@gmail.com>
References: <20261028-keyupdate-rfc-v2-0-eb5143b4c487@gmail.com>
In-Reply-To: <20261028-keyupdate-rfc-v2-0-eb5143b4c487@gmail.com>
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
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793195573; l=9945;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=hvoBqvDeZyJWvEXq8KBpjuo3Newp8nwShxn3FNiStMI=;
 b=Xu1Opm8Y9jRP5Ysn9QK//ANFqfjYyAVZM8UNI7Mn3ClIULsrqRK7FdNBoiDJTPUoIPauhZvup
 ee3pB94CIpgAho/krXe5TaB78DNrZhu181VImpGII0mfg5iHd64mIri
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

kTLS holds the key and IV of each direction, but not the traffic secret
they were derived from. The derivation is one-way, so the kernel cannot
compute the next generation for a KeyUpdate on its own.

Add TLS_TX_TRAFFIC_SECRET and TLS_RX_TRAFFIC_SECRET. The owner of the
socket passes the TLS 1.3 application traffic secret of a direction after
installing its key. The cipher of the installed key selects the hash, so
the option takes only the secret. A socket without a registered secret
behaves as before.

The secret must give the installed key and IV, or the option fails with
-EINVAL. A wrong secret would otherwise fail only at the first
KeyUpdate.

The TX secret can be registered alone. The RX secret needs the TX secret
first: a received KeyUpdate can ask for one in reply, and since the
kernel consumes the record, only the kernel can send that reply.

Installing a new key with TLS_TX or TLS_RX removes the secrets that no
longer apply. The secrets are cleared when the context is freed and
cannot be read back.

Assisted-by: LLM
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 Documentation/networking/tls.rst |  26 ++++++++
 include/net/tls.h                |  13 ++++
 include/uapi/linux/tls.h         |   2 +
 net/tls/tls_main.c               | 139 ++++++++++++++++++++++++++++++++++++++-
 4 files changed, 179 insertions(+), 1 deletion(-)

diff --git a/Documentation/networking/tls.rst b/Documentation/networking/tls.rst
index 980c442d7161..2e011bd1ce4a 100644
--- a/Documentation/networking/tls.rst
+++ b/Documentation/networking/tls.rst
@@ -300,6 +300,32 @@ extra byte used by the ContentType field.
 
 [1] https://datatracker.ietf.org/doc/html/rfc8449
 
+TLS_TX_TRAFFIC_SECRET and TLS_RX_TRAFFIC_SECRET
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+``TLS_TX_TRAFFIC_SECRET`` registers the TLS 1.3 application traffic secret
+of the transmit direction, ``TLS_RX_TRAFFIC_SECRET`` that of the receive
+direction. With a registered secret, the kernel performs KeyUpdate for that
+direction itself (RFC 9846, section 4.7.3). The value is the secret itself.
+TLS 1.3 only, software path only.
+
+Install the key of the direction first, with the ``TLS_TX`` or ``TLS_RX``
+socket option described above. The cipher of that key selects the hash, and
+the secret must have the length of that hash: 32 bytes for SHA-256
+(AES-128-GCM, AES-128-CCM, ChaCha20-Poly1305) or 48 bytes for SHA-384
+(AES-256-GCM). Other ciphers return ``EOPNOTSUPP``.
+
+Each secret can be registered once. ``TLS_RX_TRAFFIC_SECRET`` needs
+``TLS_TX_TRAFFIC_SECRET`` first: a received KeyUpdate can ask for one in
+reply, and only the kernel sees it. ``TLS_TX_TRAFFIC_SECRET`` alone is
+allowed.
+
+If the application installs a new key itself with ``TLS_TX``, both secrets
+are removed. With ``TLS_RX``, the RX secret is removed. KeyUpdate for that
+direction is then left to the application again.
+
+The secrets cannot be read back.
+
 Statistics
 ==========
 
diff --git a/include/net/tls.h b/include/net/tls.h
index e57bef58851e..aacc6d12226e 100644
--- a/include/net/tls.h
+++ b/include/net/tls.h
@@ -65,6 +65,9 @@ struct tls_rec;
 
 #define TLS_AAD_SPACE_SIZE		13
 
+/* SHA-384, the longest hash of a TLS 1.3 cipher suite kTLS supports */
+#define TLS_MAX_TRAFFIC_SECRET_SIZE	48
+
 #define TLS_MAX_IV_SIZE			16
 #define TLS_MAX_SALT_SIZE		4
 #define TLS_TAG_SIZE			16
@@ -224,6 +227,12 @@ struct tls_prot_info {
 	u16 tail_size;
 };
 
+/* A TLS 1.3 application traffic secret. len is 0 if none is registered. */
+struct tls_traffic_secret {
+	u8 data[TLS_MAX_TRAFFIC_SECRET_SIZE];
+	u8 len;
+};
+
 struct tls_context {
 	/* read-only cache line */
 	struct tls_prot_info prot_info;
@@ -266,6 +275,10 @@ struct tls_context {
 	union tls_crypto_context crypto_send;
 	union tls_crypto_context crypto_recv;
 
+	/* Registered for KeyUpdate, protected by the socket lock */
+	struct tls_traffic_secret tx_secret;
+	struct tls_traffic_secret rx_secret;
+
 	struct list_head list;
 	refcount_t refcount;
 	struct rcu_head rcu;
diff --git a/include/uapi/linux/tls.h b/include/uapi/linux/tls.h
index 1245ab38afc1..d1b136ecea96 100644
--- a/include/uapi/linux/tls.h
+++ b/include/uapi/linux/tls.h
@@ -42,6 +42,8 @@
 #define TLS_TX_ZEROCOPY_RO	3	/* TX zerocopy (only sendfile now) */
 #define TLS_RX_EXPECT_NO_PAD	4	/* Attempt opportunistic zero-copy */
 #define TLS_TX_MAX_PAYLOAD_LEN	5	/* Maximum plaintext size */
+#define TLS_TX_TRAFFIC_SECRET	6	/* TLS 1.3 TX traffic secret */
+#define TLS_RX_TRAFFIC_SECRET	7	/* TLS 1.3 RX traffic secret */
 
 /* Supported versions */
 #define TLS_VERSION_MINOR(ver)	((ver) & 0xFF)
diff --git a/net/tls/tls_main.c b/net/tls/tls_main.c
index 8bdb78718a8d..8bb1b2773f3f 100644
--- a/net/tls/tls_main.c
+++ b/net/tls/tls_main.c
@@ -31,6 +31,8 @@
  * SOFTWARE.
  */
 
+#include <crypto/sha2.h>
+#include <crypto/utils.h>
 #include <linux/module.h>
 
 #include <net/tcp.h>
@@ -325,6 +327,8 @@ void tls_ctx_free(struct sock *sk, struct tls_context *ctx)
 
 	memzero_explicit(&ctx->crypto_send, sizeof(ctx->crypto_send));
 	memzero_explicit(&ctx->crypto_recv, sizeof(ctx->crypto_recv));
+	memzero_explicit(&ctx->tx_secret, sizeof(ctx->tx_secret));
+	memzero_explicit(&ctx->rx_secret, sizeof(ctx->rx_secret));
 	mutex_destroy(&ctx->tx_lock);
 
 	if (sk)
@@ -757,8 +761,16 @@ static int do_tls_setsockopt_conf(struct sock *sk, sockptr_t optval,
 		ctx->rx_conf = conf;
 	update_sk_prot(sk, ctx);
 
-	if (update)
+	if (update) {
+		/* The registered secret no longer matches the key. The RX
+		 * secret also needs the TX one, see do_tls_setsockopt_secret().
+		 */
+		if (tx)
+			memzero_explicit(&ctx->tx_secret,
+					 sizeof(ctx->tx_secret));
+		memzero_explicit(&ctx->rx_secret, sizeof(ctx->rx_secret));
 		return 0;
+	}
 
 	if (tx) {
 		ctx->sk_write_space = sk->sk_write_space;
@@ -857,6 +869,124 @@ static int do_tls_setsockopt_tx_payload_len(struct sock *sk, sockptr_t optval,
 	return 0;
 }
 
+/* Length of the TLS 1.3 traffic secret for @cipher_type, the size of
+ * its hash. 0 if KeyUpdate is not supported for the cipher.
+ */
+static int tls_traffic_secret_len(u16 cipher_type)
+{
+	switch (cipher_type) {
+	case TLS_CIPHER_AES_GCM_128:
+	case TLS_CIPHER_AES_CCM_128:
+	case TLS_CIPHER_CHACHA20_POLY1305:
+		return SHA256_DIGEST_SIZE;
+	case TLS_CIPHER_AES_GCM_256:
+		return SHA384_DIGEST_SIZE;
+	default:
+		return 0;
+	}
+}
+
+/* The installed key and IV must be the ones that @secret gives. Each
+ * KeyUpdate derives the next key from the secret, so a wrong secret
+ * fails only at the first KeyUpdate, with no clear cause.
+ */
+static int tls_check_traffic_secret(struct tls_crypto_info *crypto_info,
+				    const u8 *secret, int len)
+{
+	const struct tls_cipher_desc *cipher_desc;
+	u8 iv[TLS_MAX_SALT_SIZE + TLS_MAX_IV_SIZE];
+	u8 key[TLS_CIPHER_AES_GCM_256_KEY_SIZE];
+	int rc;
+
+	cipher_desc = get_cipher_desc(crypto_info->cipher_type);
+	if (!cipher_desc || cipher_desc->key > sizeof(key) ||
+	    cipher_desc->salt + cipher_desc->iv > sizeof(iv))
+		return -EINVAL;
+
+	rc = tls_hkdf_expand_label(secret, len, "key", key, cipher_desc->key);
+	if (rc)
+		goto out;
+
+	rc = tls_hkdf_expand_label(secret, len, "iv", iv,
+				   cipher_desc->salt + cipher_desc->iv);
+	if (rc)
+		goto out;
+
+	if (crypto_memneq(key, crypto_info_key(crypto_info, cipher_desc),
+			  cipher_desc->key) ||
+	    crypto_memneq(iv, crypto_info_salt(crypto_info, cipher_desc),
+			  cipher_desc->salt) ||
+	    crypto_memneq(iv + cipher_desc->salt,
+			  crypto_info_iv(crypto_info, cipher_desc),
+			  cipher_desc->iv))
+		rc = -EINVAL;
+
+out:
+	memzero_explicit(key, sizeof(key));
+	memzero_explicit(iv, sizeof(iv));
+
+	return rc;
+}
+
+static int do_tls_setsockopt_secret(struct sock *sk, sockptr_t optval,
+				    unsigned int optlen, int tx)
+{
+	struct tls_context *ctx = tls_get_ctx(sk);
+	struct tls_crypto_info *crypto_info;
+	struct tls_traffic_secret *secret;
+	u8 data[TLS_MAX_TRAFFIC_SECRET_SIZE];
+	int len, rc;
+
+	if (tx) {
+		crypto_info = &ctx->crypto_send.info;
+		secret = &ctx->tx_secret;
+	} else {
+		crypto_info = &ctx->crypto_recv.info;
+		secret = &ctx->rx_secret;
+	}
+
+	/* The key must be installed first: its cipher selects the hash */
+	if (!TLS_CRYPTO_INFO_READY(crypto_info) ||
+	    crypto_info->version != TLS_1_3_VERSION)
+		return -EINVAL;
+
+	if ((tx ? ctx->tx_conf : ctx->rx_conf) != TLS_SW)
+		return -EOPNOTSUPP;
+
+	len = tls_traffic_secret_len(crypto_info->cipher_type);
+	if (!len)
+		return -EOPNOTSUPP;
+
+	if (sockptr_is_null(optval) || optlen != len)
+		return -EINVAL;
+
+	/* A received KeyUpdate may ask for one in reply. The kernel
+	 * consumes the record, so only the kernel can send the reply.
+	 */
+	if (!tx && !ctx->tx_secret.len)
+		return -EINVAL;
+
+	if (secret->len)
+		return -EBUSY;
+
+	if (copy_from_sockptr(data, optval, len)) {
+		rc = -EFAULT;
+		goto out;
+	}
+
+	rc = tls_check_traffic_secret(crypto_info, data, len);
+	if (rc)
+		goto out;
+
+	memcpy(secret->data, data, len);
+	secret->len = len;
+
+out:
+	memzero_explicit(data, sizeof(data));
+
+	return rc;
+}
+
 static int do_tls_setsockopt(struct sock *sk, int optname, sockptr_t optval,
 			     unsigned int optlen)
 {
@@ -883,6 +1013,13 @@ static int do_tls_setsockopt(struct sock *sk, int optname, sockptr_t optval,
 		rc = do_tls_setsockopt_tx_payload_len(sk, optval, optlen);
 		release_sock(sk);
 		break;
+	case TLS_TX_TRAFFIC_SECRET:
+	case TLS_RX_TRAFFIC_SECRET:
+		lock_sock(sk);
+		rc = do_tls_setsockopt_secret(sk, optval, optlen,
+					      optname == TLS_TX_TRAFFIC_SECRET);
+		release_sock(sk);
+		break;
 	default:
 		rc = -ENOPROTOOPT;
 		break;

-- 
2.53.0

