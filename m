From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 14 Jun 2026 03:23:32 -0500
Subject: [PATCH v3 3/3] net/smc: bound the send length to the send buffer
 in smc_tx_sendmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260614-b4-disp-edd64be9-v3-3-551fa514257e@proton.me>
References: <20260614-b4-disp-edd64be9-v3-0-551fa514257e@proton.me>
In-Reply-To: <20260614-b4-disp-edd64be9-v3-0-551fa514257e@proton.me>
To: Wenjia Zhang <wenjia@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 Ursula Braun <ubraun@linux.ibm.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-s390@vger.kernel.org, Paolo Abeni <pabeni@redhat.com>, 
 linux-kernel@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Jakub Kicinski <kuba@kernel.org>, Tony Lu <tonylu@linux.alibaba.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781425409; l=2754;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=4S35QpGjFI4Nol8jEunjm9yblHJ/ApOBlLnW/qpjsWU=;
 b=vwFLjibbCYXZPOBwsd2IHPubLmw+2WKN4GI/oz8r7HApaeyQqzparJCEYXby2jhTaf9CytpYQ
 rJx8harvq6wC02iIhBc4p0unRq1vFURj+feqTJEG/a3OHtb8mocCe+7
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the SMC-D DMB-merge (nocopy) path, smc_cdc_msg_recv_action() advances
conn->sndbuf_space from the peer's consumer cursor:

	diff_tx = smc_curs_diff(sndbuf_desc->len, &tx_curs_fin,
				&local_rx_ctrl.cons);
	atomic_add(diff_tx, &conn->sndbuf_space);

The consumer cursor is wire-controlled and unvalidated, and
smc_curs_diff()'s differing-wrap branch can return more than
sndbuf_desc->len, so a forged cursor drives sndbuf_space past the send
buffer (and across many CDC messages can overflow the signed counter
negative).  smc_tx_sendmsg() reads it as the available write space and
performs a wrap-around copy whose second chunk (copylen - first_chunk,
written at ring offset 0) is never re-bounded to sndbuf_desc->len,
writing user data past the send buffer -- a heap out-of-bounds write of
attacker-influenced length and content.

Bound the write space to sndbuf_desc->len where it is consumed, treating
a negative (sign-overflowed) value as out of range too, so the copy
length can never exceed the ring.  This enforces the documented
0 <= sndbuf_space <= sndbuf_desc->len invariant at the producer,
race-free against the CDC tasklet that advances sndbuf_space.

Fixes: cc0ab806fc52 ("net/smc: adapt cursor update when sndbuf and peer DMB are merged")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_tx.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/net/smc/smc_tx.c b/net/smc/smc_tx.c
index 3144b4b1fe29..5916f02060fb 100644
--- a/net/smc/smc_tx.c
+++ b/net/smc/smc_tx.c
@@ -233,6 +233,19 @@ int smc_tx_sendmsg(struct smc_sock *smc, struct msghdr *msg, size_t len)
 		/* initialize variables for 1st iteration of subsequent loop */
 		/* could be just 1 byte, even after smc_tx_wait above */
 		writespace = atomic_read(&conn->sndbuf_space);
+		/* sndbuf_space is advanced from the peer's wire-controlled
+		 * consumer cursor on the SMC-D DMB-merge path; a forged cursor
+		 * can inflate it past the send buffer, or overflow the signed
+		 * accumulator to a negative value across many CDC messages
+		 * (which a plain "> len" check would miss before the size_t
+		 * cast below turns it huge).  Bound it to the send buffer in
+		 * either case so the wrap-around write cannot run past
+		 * sndbuf_desc->len.  This enforces the documented
+		 * 0 <= sndbuf_space <= sndbuf_desc->len invariant at the
+		 * producer, race-free against the CDC tasklet.
+		 */
+		if (writespace < 0 || writespace > conn->sndbuf_desc->len)
+			writespace = conn->sndbuf_desc->len;
 		/* not more than what user space asked for */
 		copylen = min_t(size_t, send_remaining, writespace);
 		/* determine start of sndbuf */

-- 
2.43.0

