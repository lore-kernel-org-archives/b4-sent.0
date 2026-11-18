From: Felipe Pereira Stival <v0idpwn@gmail.com>
Date: Wed, 18 Nov 2026 17:35:48 -0300
Subject: [PATCH net 1/2] tls: don't hide a queued KeyUpdate from poll()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-v0idpwn-tls-poll-parked-keyupdate-v1-1-8e25101e7be6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795034159; l=3018;
 i=v0idpwn@gmail.com; s=20261118; h=from:subject:message-id;
 bh=7HlESlzQZS7RmVDTTCbJYyzyo4RKoYEAiP36cchvvKI=;
 b=SrEL++XkAo7j61m/Hg6DrjlA4Mry1VKzzWNswqTICF+Xh2U3SVj0VSaAnnx3TfO2tl2kYPhSG
 SaemNdRlA/nAihIp/kTJsZSth+i2NoGKASn3kmHEGONS0D+9e3RpP/s
X-Developer-Key: i=v0idpwn@gmail.com; a=ed25519;
 pk=dy+Py1JexopmEarZT58aUO9PMt7zs+cB62CS+N7NWTw=
X-Endpoint-Received: by B4 Relay for v0idpwn@gmail.com/20261118 with auth_id=1562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When application data and a KeyUpdate are both queued, the recv() for
the data can also decrypt the KeyUpdate. That makes a rekey pending,
and the KeyUpdate is left on rx_list because its record type differs.
tls_sk_poll() reports no read events while a rekey is pending, so the
socket doesn't poll readable although a recvmsg() would return the
KeyUpdate. A reader that waits for a read event before each recv()
never reads it, never provides the new key and receives nothing more.

Report read events for records on rx_list while a rekey is pending,
since they are already decrypted. Keep ignoring the records still in
the strparser, so once the KeyUpdate has been read there are no read
events until the new key is provided, as before. Update the
documentation to say so.

Found with a level-triggered epoll reader that does one recv() per
read event. Without this patch it gets the data and then no read event
for the KeyUpdate; with it, the KeyUpdate is reported and the rekey
completes.

Fixes: 47069594e67e ("tls: implement rekey for TLS1.3")
Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Felipe Pereira Stival <v0idpwn@gmail.com>
---
 Documentation/networking/tls.rst | 7 ++++---
 net/tls/tls_main.c               | 6 +++---
 2 files changed, 7 insertions(+), 6 deletions(-)

diff --git a/Documentation/networking/tls.rst b/Documentation/networking/tls.rst
index 980c442d716..e07c1a001b2 100644
--- a/Documentation/networking/tls.rst
+++ b/Documentation/networking/tls.rst
@@ -215,9 +215,10 @@ To prevent attempting to decrypt incoming records using the wrong key,
 decryption will be paused when a KeyUpdate message is received by the
 kernel, until the new key has been provided using the TLS_RX socket
 option. Any read occurring after the KeyUpdate has been read and
-before the new key is provided will fail with EKEYEXPIRED. poll() will
-not report any read events from the socket until the new key is
-provided. There is no pausing on the transmit side.
+before the new key is provided will fail with EKEYEXPIRED. Once the
+KeyUpdate has been read, poll() will not report any read events from
+the socket until the new key is provided. There is no pausing on the
+transmit side.
 
 Userspace should make sure that the crypto_info provided has been set
 properly. In particular, the kernel will not check for key/nonce
diff --git a/net/tls/tls_main.c b/net/tls/tls_main.c
index b8d5a843f76..4c4c2801ae0 100644
--- a/net/tls/tls_main.c
+++ b/net/tls/tls_main.c
@@ -414,9 +414,9 @@ static __poll_t tls_sk_poll(struct file *file, struct socket *sock,
 	tls_ctx = tls_get_ctx(sk);
 	ctx = tls_sw_ctx_rx(tls_ctx);
 
-	if ((skb_queue_empty_lockless(&ctx->rx_list) &&
-	     !tls_strp_msg_ready(ctx)) ||
-	    READ_ONCE(ctx->key_update_pending))
+	if (skb_queue_empty_lockless(&ctx->rx_list) &&
+	    (!tls_strp_msg_ready(ctx) ||
+	     READ_ONCE(ctx->key_update_pending)))
 		mask &= ~(EPOLLIN | EPOLLRDNORM);
 
 	return mask;

-- 
2.56.0

