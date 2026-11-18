From: Felipe Pereira Stival <v0idpwn@gmail.com>
Date: Wed, 18 Nov 2026 17:35:49 -0300
Subject: [PATCH net 2/2] selftests: tls: add a poll test for a queued
 KeyUpdate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-v0idpwn-tls-poll-parked-keyupdate-v1-2-8e25101e7be6@gmail.com>
References: <20261118-v0idpwn-tls-poll-parked-keyupdate-v1-0-8e25101e7be6@gmail.com>
In-Reply-To: <20261118-v0idpwn-tls-poll-parked-keyupdate-v1-0-8e25101e7be6@gmail.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Felipe Pereira Stival <v0idpwn@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795034159; l=2062;
 i=v0idpwn@gmail.com; s=20261118; h=from:subject:message-id;
 bh=aEku9achIkB6xdlEKNORIQj8tkacDlGHfxVLzvkqD+I=;
 b=9enkyopIsrXF5MoQP6Zq/3/ASTULs3Fy+dQmB0HgprtypW2tcal9ICT36I2YwTGth+euHjEo0
 OVRpWt5r9r3Dt7EHSsmtfRYLtcPzIvSS/9B9ZzJbiis7hZpV9eyZwsK
X-Developer-Key: i=v0idpwn@gmail.com; a=ed25519;
 pk=dy+Py1JexopmEarZT58aUO9PMt7zs+cB62CS+N7NWTw=
X-Endpoint-Received: by B4 Relay for v0idpwn@gmail.com/20261118 with auth_id=1562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check that poll() reports a read event when a recv() for data has
decrypted and queued a KeyUpdate. Once the KeyUpdate has been read,
check that poll() doesn't report a record sent with the new key.

Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Felipe Pereira Stival <v0idpwn@gmail.com>
---
 tools/testing/selftests/net/tls.c | 40 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/tools/testing/selftests/net/tls.c b/tools/testing/selftests/net/tls.c
index bd2797f9f61..59e403b5f12 100644
--- a/tools/testing/selftests/net/tls.c
+++ b/tools/testing/selftests/net/tls.c
@@ -2421,6 +2421,46 @@ TEST_F(tls, rekey_poll_delay)
 	}
 }
 
+TEST_F(tls, rekey_poll_queued)
+{
+	char const *test_str = "test_message";
+	struct tls_crypto_info_keys tls12;
+	struct pollfd pfd = { };
+	char buf[100];
+	int send_len;
+
+	if (self->notls)
+		SKIP(return, "no TLS support");
+
+	if (variant->tls_version != TLS_1_3_VERSION)
+		return;
+
+	/* data followed by a KeyUpdate */
+	send_len = strlen(test_str) + 1;
+	EXPECT_EQ(send(self->fd, test_str, send_len, 0), send_len);
+	tls_send_keyupdate(_metadata, self->fd);
+
+	/* reading the data decrypts the KeyUpdate and leaves it queued */
+	EXPECT_EQ(recv(self->cfd, buf, sizeof(buf), MSG_WAITALL), send_len);
+	EXPECT_EQ(memcmp(buf, test_str, send_len), 0);
+
+	/* KeyUpdate hasn't been read, expect cfd to be readable */
+	pfd.fd = self->cfd;
+	pfd.events = POLLIN;
+	EXPECT_EQ(poll(&pfd, 1, 0), 1);
+
+	/* get KeyUpdate */
+	tls_recv_keyupdate(_metadata, self->cfd, 0);
+
+	/* update TX key and send with it */
+	tls_crypto_info_init(variant->tls_version, variant->cipher_type, &tls12, 1);
+	EXPECT_EQ(setsockopt(self->fd, SOL_TLS, TLS_TX, &tls12, tls12.len), 0);
+	EXPECT_EQ(send(self->fd, test_str, send_len, 0), send_len);
+
+	/* key hasn't been updated, expect cfd to be non-readable */
+	EXPECT_EQ(poll(&pfd, 1, 0), 0);
+}
+
 struct raw_rec {
 	unsigned int plain_len;
 	unsigned char plain_data[100];

-- 
2.56.0

