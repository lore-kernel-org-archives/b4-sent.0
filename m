From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Wed, 28 Oct 2026 09:52:55 -0400
Subject: [PATCH RFC net-next v2 5/5] selftests/tls: add KeyUpdate tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-keyupdate-rfc-v2-5-eb5143b4c487@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793195573; l=14717;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=euGu27Fn9pivPB5DT8Yvti9FtNh59GoiCM6RB2LjB+o=;
 b=8NLtORR6yzxk5BHswtQ2F8cMVO3jXuT1aR+jk+ahE1eJ9VmnMBP+iQsMGeyBYtGheyWYwJPGi
 1HyUuynQJDyDQsBlaZh+RTIJvVOZ4Uz2c4y3MFXpYZSF2nEJy+bhSCL
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

Test the in-kernel KeyUpdate on a bidirectional connection with both
traffic secrets registered on each socket:

- registration errors: wrong length, missing key, TLS 1.2, SM4, the
  RX secret before the TX secret, and a secret that does not give the
  installed key;
- KeyUpdates in both directions with data around them;
- a data record, a KeyUpdate and another data record queued before
  the first read;
- update_requested: the peer answers before its next data, and a
  second request waits for the answer;
- splice() across a KeyUpdate;
- a key installed with TLS_TX removes the registered secrets;
- after a key installed with TLS_RX, a new update_requested is
  accepted;
- TLS_TX_KEY_UPDATE on a shut down socket does not raise SIGPIPE;
- more than 8 KeyUpdates in one second, and an invalid
  request_update value, end the connection.

The keys are derived from the secrets with HKDF-Expand-Label, with the
HMAC of the kernel through AF_ALG.

Assisted-by: LLM
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 tools/testing/selftests/net/config |   4 +
 tools/testing/selftests/net/tls.c  | 412 +++++++++++++++++++++++++++++++++++++
 2 files changed, 416 insertions(+)

diff --git a/tools/testing/selftests/net/config b/tools/testing/selftests/net/config
index cb8cb4696df7..0de4011cfabd 100644
--- a/tools/testing/selftests/net/config
+++ b/tools/testing/selftests/net/config
@@ -10,8 +10,12 @@ CONFIG_CAN_VXCAN=m
 CONFIG_CGROUPS=y
 CONFIG_CRYPTO_ARIA=y
 CONFIG_CRYPTO_CHACHA20POLY1305=m
+CONFIG_CRYPTO_HMAC=y
 CONFIG_CRYPTO_SHA1=y
+CONFIG_CRYPTO_SHA256=y
+CONFIG_CRYPTO_SHA512=y
 CONFIG_CRYPTO_SM4_GENERIC=y
+CONFIG_CRYPTO_USER_API_HASH=y
 CONFIG_DEBUG_INFO_BTF=y
 CONFIG_DEBUG_INFO_BTF_MODULES=n
 CONFIG_DUMMY=y
diff --git a/tools/testing/selftests/net/tls.c b/tools/testing/selftests/net/tls.c
index 9d3cd4fff062..775d347d54ea 100644
--- a/tools/testing/selftests/net/tls.c
+++ b/tools/testing/selftests/net/tls.c
@@ -11,6 +11,7 @@
 #include <stdlib.h>
 #include <unistd.h>
 
+#include <linux/if_alg.h>
 #include <linux/tls.h>
 #include <linux/tcp.h>
 #include <linux/socket.h>
@@ -2390,6 +2391,417 @@ TEST_F(tls, rekey_poll_delay)
 	}
 }
 
+#ifndef SOL_ALG
+#define SOL_ALG 279
+#endif
+
+/* RFC 9846 section 7.1, HKDF-Expand-Label with an empty context, for an
+ * output no longer than the hash. The HMAC comes from the kernel.
+ */
+static bool hkdf_expand_label(const unsigned char *secret, int secret_len,
+			      const char *label, unsigned char *out,
+			      int out_len)
+{
+	struct sockaddr_alg sa = {
+		.salg_family = AF_ALG,
+		.salg_type = "hash",
+	};
+	unsigned char info[2 + 1 + 255 + 1 + 1], md[48];
+	int tfm, op, n = 0, label_len = 6 + strlen(label);
+	bool ok = false;
+
+	strcpy((char *)sa.salg_name,
+	       secret_len == 48 ? "hmac(sha384)" : "hmac(sha256)");
+
+	info[n++] = out_len >> 8;
+	info[n++] = out_len;
+	info[n++] = label_len;
+	memcpy(info + n, "tls13 ", 6);
+	memcpy(info + n + 6, label, label_len - 6);
+	n += label_len;
+	info[n++] = 0;	/* context */
+	info[n++] = 1;	/* HKDF-Expand counter */
+
+	tfm = socket(AF_ALG, SOCK_SEQPACKET, 0);
+	if (tfm < 0)
+		return false;
+	if (bind(tfm, (struct sockaddr *)&sa, sizeof(sa)) ||
+	    setsockopt(tfm, SOL_ALG, ALG_SET_KEY, secret, secret_len))
+		goto out;
+
+	op = accept(tfm, NULL, 0);
+	if (op < 0)
+		goto out;
+	ok = write(op, info, n) == n && read(op, md, secret_len) == secret_len;
+	close(op);
+	if (ok)
+		memcpy(out, md, out_len);
+out:
+	close(tfm);
+	return ok;
+}
+
+/* Fill @keys with the key and IV that @secret gives, record number 0 */
+static bool keyupdate_keys(uint16_t cipher_type, const unsigned char *secret,
+			   int secret_len, struct tls_crypto_info_keys *keys)
+{
+	unsigned char *key, *salt, *iv;
+	int key_len, salt_len, iv_len;
+	unsigned char nonce[12];
+
+	tls_crypto_info_init(TLS_1_3_VERSION, cipher_type, keys, 0);
+
+	switch (cipher_type) {
+	case TLS_CIPHER_AES_GCM_128:
+		key = keys->aes128.key;
+		salt = keys->aes128.salt;
+		iv = keys->aes128.iv;
+		key_len = sizeof(keys->aes128.key);
+		salt_len = sizeof(keys->aes128.salt);
+		iv_len = sizeof(keys->aes128.iv);
+		break;
+	case TLS_CIPHER_AES_GCM_256:
+		key = keys->aesgcm256.key;
+		salt = keys->aesgcm256.salt;
+		iv = keys->aesgcm256.iv;
+		key_len = sizeof(keys->aesgcm256.key);
+		salt_len = sizeof(keys->aesgcm256.salt);
+		iv_len = sizeof(keys->aesgcm256.iv);
+		break;
+	case TLS_CIPHER_AES_CCM_128:
+		key = keys->aesccm128.key;
+		salt = keys->aesccm128.salt;
+		iv = keys->aesccm128.iv;
+		key_len = sizeof(keys->aesccm128.key);
+		salt_len = sizeof(keys->aesccm128.salt);
+		iv_len = sizeof(keys->aesccm128.iv);
+		break;
+	case TLS_CIPHER_CHACHA20_POLY1305:
+		key = keys->chacha20.key;
+		salt = keys->chacha20.salt;
+		iv = keys->chacha20.iv;
+		key_len = sizeof(keys->chacha20.key);
+		salt_len = 0;
+		iv_len = sizeof(keys->chacha20.iv);
+		break;
+	default:
+		return false;
+	}
+
+	if (!hkdf_expand_label(secret, secret_len, "key", key, key_len) ||
+	    !hkdf_expand_label(secret, secret_len, "iv", nonce,
+			       salt_len + iv_len))
+		return false;
+
+	memcpy(salt, nonce, salt_len);
+	memcpy(iv, nonce + salt_len, iv_len);
+	return true;
+}
+
+/* In-kernel KeyUpdate: fd and cfd both register the TX and RX traffic
+ * secrets of a bidirectional connection. Returns false if the variant
+ * does not support it.
+ */
+static bool keyupdate_setup(struct __test_metadata *_metadata,
+			    FIXTURE_DATA(tls) *self,
+			    const FIXTURE_VARIANT(tls) *variant)
+{
+	struct tls_crypto_info_keys keys_a, keys_b;
+	unsigned char secret_a[48], secret_b[48];
+	int len;
+
+	if (self->notls || variant->tls_version != TLS_1_3_VERSION)
+		return false;
+
+	switch (variant->cipher_type) {
+	case TLS_CIPHER_AES_GCM_128:
+	case TLS_CIPHER_AES_CCM_128:
+	case TLS_CIPHER_CHACHA20_POLY1305:
+		len = 32;
+		break;
+	case TLS_CIPHER_AES_GCM_256:
+		len = 48;
+		break;
+	default:
+		return false;
+	}
+
+	memset(secret_a, 0xa5, sizeof(secret_a));
+	memset(secret_b, 0x5a, sizeof(secret_b));
+
+	/* the keys must be the ones that the secrets give */
+	ASSERT_TRUE(keyupdate_keys(variant->cipher_type, secret_a, len,
+				   &keys_a));
+	ASSERT_TRUE(keyupdate_keys(variant->cipher_type, secret_b, len,
+				   &keys_b));
+
+	/* fd -> cfd: replace the keys of the fixture */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX, &keys_a,
+			     keys_a.len), 0);
+	EXPECT_EQ(setsockopt(self->cfd, SOL_TLS, TLS_RX, &keys_a,
+			     keys_a.len), 0);
+	/* cfd -> fd */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX, &keys_b,
+			     keys_b.len), 0);
+	EXPECT_EQ(setsockopt(self->cfd, SOL_TLS, TLS_TX, &keys_b,
+			     keys_b.len), 0);
+
+	/* the RX secret needs the TX secret first */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX_TRAFFIC_SECRET,
+			     secret_b, len), -1);
+	EXPECT_EQ(errno, EINVAL);
+
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_TRAFFIC_SECRET,
+			     secret_a, len), 0);
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX_TRAFFIC_SECRET,
+			     secret_b, len), 0);
+	EXPECT_EQ(setsockopt(self->cfd, SOL_TLS, TLS_TX_TRAFFIC_SECRET,
+			     secret_b, len), 0);
+	EXPECT_EQ(setsockopt(self->cfd, SOL_TLS, TLS_RX_TRAFFIC_SECRET,
+			     secret_a, len), 0);
+
+	return true;
+}
+
+static void keyupdate_send(struct __test_metadata *_metadata, int fd,
+			   int request)
+{
+	EXPECT_EQ(setsockopt(fd, SOL_TLS, TLS_TX_KEY_UPDATE,
+			     &request, sizeof(request)), 0);
+}
+
+static void send_recv_str(struct __test_metadata *_metadata, int from, int to,
+			  const char *str)
+{
+	int len = strlen(str) + 1;
+	char buf[64];
+
+	EXPECT_EQ(send(from, str, len, 0), len);
+	EXPECT_EQ(recv(to, buf, sizeof(buf), 0), len);
+	EXPECT_EQ(memcmp(buf, str, len), 0);
+}
+
+TEST_F(tls, keyupdate_secret_errors)
+{
+	unsigned char secret[48] = {};
+	int one = 1;
+
+	if (self->notls)
+		SKIP(return, "no TLS support");
+
+	/* no secret registered */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_KEY_UPDATE,
+			     &one, sizeof(one)), -1);
+	EXPECT_EQ(errno, EINVAL);
+
+	if (variant->tls_version != TLS_1_3_VERSION) {
+		EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_TRAFFIC_SECRET,
+				     secret, 32), -1);
+		EXPECT_EQ(errno, EINVAL);
+		return;
+	}
+
+	if (variant->cipher_type == TLS_CIPHER_SM4_GCM ||
+	    variant->cipher_type == TLS_CIPHER_SM4_CCM) {
+		EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_TRAFFIC_SECRET,
+				     secret, 32), -1);
+		EXPECT_EQ(errno, EOPNOTSUPP);
+		return;
+	}
+
+	/* the RX key is not installed on fd */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX_TRAFFIC_SECRET,
+			     secret, 32), -1);
+	EXPECT_EQ(errno, EINVAL);
+
+	/* wrong length */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_TRAFFIC_SECRET,
+			     secret, 16), -1);
+	EXPECT_EQ(errno, EINVAL);
+
+	/* the installed key does not come from this secret */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_TRAFFIC_SECRET, secret,
+			     variant->cipher_type == TLS_CIPHER_AES_GCM_256 ?
+			     48 : 32), -1);
+	EXPECT_EQ(errno, EINVAL);
+}
+
+TEST_F(tls, keyupdate)
+{
+	int i;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	send_recv_str(_metadata, self->fd, self->cfd, "before");
+
+	/* stay below the limit of 8 received KeyUpdates per second */
+	for (i = 0; i < 4; i++) {
+		keyupdate_send(_metadata, self->fd, 0);
+		send_recv_str(_metadata, self->fd, self->cfd, "after");
+		keyupdate_send(_metadata, self->cfd, 0);
+		send_recv_str(_metadata, self->cfd, self->fd, "reverse");
+	}
+}
+
+TEST_F(tls, keyupdate_queued)
+{
+	const char *str = "queued behind a KeyUpdate";
+	int len = strlen(str) + 1;
+	char buf[64];
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	/* the record before the KeyUpdate, the KeyUpdate and the record
+	 * after it are all queued before the first read
+	 */
+	EXPECT_EQ(send(self->fd, str, len, MSG_MORE), len);
+	keyupdate_send(_metadata, self->fd, 0);
+	EXPECT_EQ(send(self->fd, str, len, 0), len);
+
+	EXPECT_EQ(recv(self->cfd, buf, len, MSG_WAITALL), len);
+	EXPECT_EQ(memcmp(buf, str, len), 0);
+	EXPECT_EQ(recv(self->cfd, buf, len, MSG_WAITALL), len);
+	EXPECT_EQ(memcmp(buf, str, len), 0);
+}
+
+TEST_F(tls, keyupdate_request)
+{
+	int one = 1;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	keyupdate_send(_metadata, self->fd, 1);
+
+	/* no answer yet */
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_KEY_UPDATE,
+			     &one, sizeof(one)), -1);
+	EXPECT_EQ(errno, EBUSY);
+
+	/* cfd processes the request, then answers ahead of its data */
+	send_recv_str(_metadata, self->fd, self->cfd, "request");
+	send_recv_str(_metadata, self->cfd, self->fd, "answer");
+
+	/* answered */
+	keyupdate_send(_metadata, self->fd, 1);
+	send_recv_str(_metadata, self->fd, self->cfd, "request");
+	send_recv_str(_metadata, self->cfd, self->fd, "answer");
+}
+
+TEST_F(tls, keyupdate_splice)
+{
+	const char *str = "spliced after a KeyUpdate";
+	int len = strlen(str) + 1;
+	char buf[64];
+	int p[2];
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	ASSERT_GE(pipe(p), 0);
+
+	keyupdate_send(_metadata, self->fd, 0);
+	EXPECT_EQ(send(self->fd, str, len, 0), len);
+
+	EXPECT_EQ(splice(self->cfd, NULL, p[1], NULL, len, 0), len);
+	EXPECT_EQ(read(p[0], buf, len), len);
+	EXPECT_EQ(memcmp(buf, str, len), 0);
+
+	close(p[0]);
+	close(p[1]);
+}
+
+TEST_F(tls, keyupdate_manual_rekey)
+{
+	struct tls_crypto_info_keys tls12;
+	int zero = 0;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	/* a key installed by the user removes the registered secrets */
+	tls_crypto_info_init(variant->tls_version, variant->cipher_type,
+			     &tls12, 2);
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX, &tls12, tls12.len), 0);
+
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX_KEY_UPDATE,
+			     &zero, sizeof(zero)), -1);
+	EXPECT_EQ(errno, EINVAL);
+}
+
+TEST_F(tls, keyupdate_manual_rekey_request)
+{
+	struct tls_crypto_info_keys keys;
+	unsigned char secret[48];
+	int len;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	keyupdate_send(_metadata, self->fd, 1);
+
+	/* the answer to the request now goes to user space */
+	len = variant->cipher_type == TLS_CIPHER_AES_GCM_256 ? 48 : 32;
+	memset(secret, 0x3c, sizeof(secret));
+	ASSERT_TRUE(keyupdate_keys(variant->cipher_type, secret, len, &keys));
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX, &keys, keys.len), 0);
+
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX_TRAFFIC_SECRET,
+			     secret, len), 0);
+
+	keyupdate_send(_metadata, self->fd, 1);
+}
+
+TEST_F(tls, keyupdate_nosignal)
+{
+	int zero = 0;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	/* The default action of SIGPIPE ends the test. The result is not
+	 * checked: as for sendmsg(), the error can show up only on the
+	 * next call.
+	 */
+	EXPECT_EQ(shutdown(self->fd, SHUT_WR), 0);
+	setsockopt(self->fd, SOL_TLS, TLS_TX_KEY_UPDATE, &zero, sizeof(zero));
+}
+
+TEST_F(tls, keyupdate_rate_limit)
+{
+	char buf[64];
+	int i;
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	/* the ninth KeyUpdate in one second ends the connection */
+	for (i = 0; i < 9; i++)
+		keyupdate_send(_metadata, self->fd, 0);
+	EXPECT_EQ(send(self->fd, "x", 1, 0), 1);
+
+	EXPECT_EQ(recv(self->cfd, buf, sizeof(buf), 0), -1);
+	EXPECT_EQ(errno, EBADMSG);
+}
+
+TEST_F(tls, keyupdate_invalid)
+{
+	/* key_update, length 1, request_update 2 */
+	static const char bad[] = "\x18\x00\x00\x01\x02";
+	char buf[64];
+
+	if (!keyupdate_setup(_metadata, self, variant))
+		SKIP(return, "no in-kernel KeyUpdate for this variant");
+
+	EXPECT_EQ(tls_send_cmsg(self->fd, TLS_RECORD_TYPE_HANDSHAKE,
+				(char *)bad, 5, 0), 5);
+
+	EXPECT_EQ(recv(self->cfd, buf, sizeof(buf), 0), -1);
+	EXPECT_EQ(errno, EBADMSG);
+}
+
 struct raw_rec {
 	unsigned int plain_len;
 	unsigned char plain_data[100];

-- 
2.53.0

