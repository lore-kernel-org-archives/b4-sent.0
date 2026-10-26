From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Sun, 25 Oct 2026 20:36:52 -0400
Subject: [PATCH RFC net-next 5/5] selftests/tls: add KeyUpdate tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-keyupdate-rfc-v1-5-60b7756eccbd@gmail.com>
References: <20261025-keyupdate-rfc-v1-0-60b7756eccbd@gmail.com>
In-Reply-To: <20261025-keyupdate-rfc-v1-0-60b7756eccbd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792975010; l=8642;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=yVTcJm4gumldwJJYUwOUFkQ01b/PvpDG48+U91afbhM=;
 b=OWGWACKk60Jdz51NxNg5fFf6lIwPI7RqwuiJYwckoH/iN1vocuNyVsCmOWt7Te23mgmX4FsWt
 wdcZylFlv4ZCOH7qmYwuwU5EFsMPsBiLKbc8ang8/0/rHyxFbXwcSgN
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

Test the in-kernel KeyUpdate on a bidirectional connection with both
traffic secrets registered on each socket:

- registration errors: wrong length, missing key, TLS 1.2, SM4, and
  the RX secret before the TX secret;
- KeyUpdates in both directions with data around them;
- a data record, a KeyUpdate and another data record queued before
  the first read;
- update_requested: the peer answers before its next data, and a
  second request waits for the answer;
- splice() across a KeyUpdate;
- a key installed with TLS_TX removes the registered secrets;
- more than 8 KeyUpdates in one second, and an invalid
  request_update value, end the connection.

Assisted-by: LLM
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 tools/testing/selftests/net/tls.c | 249 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 249 insertions(+)

diff --git a/tools/testing/selftests/net/tls.c b/tools/testing/selftests/net/tls.c
index 9d3cd4fff062..838030d09cd3 100644
--- a/tools/testing/selftests/net/tls.c
+++ b/tools/testing/selftests/net/tls.c
@@ -2390,6 +2390,255 @@ TEST_F(tls, rekey_poll_delay)
 	}
 }
 
+/* In-kernel KeyUpdate: fd and cfd both register the TX and RX traffic
+ * secrets of a bidirectional connection. Returns false if the variant
+ * does not support it.
+ */
+static bool keyupdate_setup(struct __test_metadata *_metadata,
+			    FIXTURE_DATA(tls) *self,
+			    const FIXTURE_VARIANT(tls) *variant)
+{
+	struct tls_crypto_info_keys tls12;
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
+	/* cfd -> fd */
+	tls_crypto_info_init(variant->tls_version, variant->cipher_type,
+			     &tls12, 1);
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_RX, &tls12, tls12.len), 0);
+	EXPECT_EQ(setsockopt(self->cfd, SOL_TLS, TLS_TX, &tls12, tls12.len), 0);
+
+	memset(secret_a, 0xa5, sizeof(secret_a));
+	memset(secret_b, 0x5a, sizeof(secret_b));
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

