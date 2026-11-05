From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Thu, 05 Nov 2026 11:30:39 -0500
Subject: [PATCH net-next v6 3/6] tls: loop in tls_sw_splice_read() until it
 has a record
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-keyupdate-rfc-v6-3-99b695f9eb4f@gmail.com>
References: <20261105-keyupdate-rfc-v6-0-99b695f9eb4f@gmail.com>
In-Reply-To: <20261105-keyupdate-rfc-v6-0-99b695f9eb4f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793896238; l=1113;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=4C9Djt7aw5YpZqtOVbGgX+iA/6jCePYUHtfq0NJMnQc=;
 b=PUpT2o6XdjPzvShA6vVJWrZJeFssowmSFYNxIaJU+36VTv3EDdUhyKVVAOwGi2GHxA9geOAOb
 1Q5+oi1I8AaAMbR7m67cNCDQkXhNk5BAcAOSP9ddLnk7QFgx0XlRKnP
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

tls_sw_splice_read() passes one record to the pipe. It takes the
record from rx_list or decrypts the next record from the socket.

The next patch lets the kernel consume a KeyUpdate record. splice()
then has no record to pass on and must decrypt the next one. Make the
decrypt step a loop that runs until splice() has a record.

No functional change: the loop sets skb on its first pass.

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
Reviewed-by: Hannes Reinecke <hare@kernel.org>
---
 net/tls/tls_sw.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 771e02bff519..7f7a2f70b02a 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -2023,9 +2023,8 @@ ssize_t tls_sw_splice_read(struct socket *sock,  loff_t *ppos,
 	if (err)
 		goto splice_read_end;
 
-	if (!skb_queue_empty(&ctx->rx_list)) {
-		skb = __skb_dequeue(&ctx->rx_list);
-	} else {
+	skb = __skb_dequeue(&ctx->rx_list);
+	while (!skb) {
 		struct tls_decrypt_arg darg;
 
 		err = tls_rx_rec_wait(sk, nonblock, true, false);

-- 
2.53.0

