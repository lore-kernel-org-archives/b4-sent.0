From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 14 Jun 2026 03:23:31 -0500
Subject: [PATCH v3 2/3] net/smc: bound the receive length to the RMB in
 smc_rx_recvmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260614-b4-disp-edd64be9-v3-2-551fa514257e@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781425409; l=2584;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=Y/3QqJVlrCKltO0Cz8rMmwTKlkY3BnW+tSsL2yrTGTg=;
 b=GL4RXe2Aexldd9WYN3tIcnVonPl/3AH6Rwtwx/IAFov+okzHX1u4sH6uvMbQEBdupWnDeCaFG
 Qm+sfIAVaCABCQilKVxVdP+Ex/1Q3Y/MLGptSxJ5YFxJx6ht84IOzdF
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

conn->bytes_to_rcv is accumulated in the receive tasklet from the peer's
producer cursor:

	diff_prod = smc_curs_diff(rmb_desc->len, &prod_old, &prod_new);
	atomic_add(diff_prod, &conn->bytes_to_rcv);

smc_curs_diff()'s differing-wrap branch returns (size - old.count) +
new.count, which exceeds rmb_desc->len for a forged producer cursor and
accumulates across CDC messages, so bytes_to_rcv can grow past the RMB
(and across many messages can overflow the signed counter negative).
smc_rx_recvmsg() reads it as the number of readable bytes and performs a
wrap-around copy whose second chunk (copylen - first_chunk, read from
ring offset 0) is never re-bounded to rmb_desc->len, reading past the
RMB into adjacent kernel memory and disclosing it to the peer.

Bound the readable count to rmb_desc->len where it is consumed, treating
a negative (sign-overflowed) value as out of range too, so the copy
length can never exceed the ring.  This enforces the documented
0 <= bytes_to_rcv <= rmb_desc->len invariant at the consumer, where it
is race-free against the producer update that runs in the receive
tasklet.

Fixes: 952310ccf2d8 ("smc: receive data from RMBE")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_rx.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index c1d9b923938d..f461cf10b085 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -442,6 +442,18 @@ int smc_rx_recvmsg(struct smc_sock *smc, struct msghdr *msg,
 		/* initialize variables for 1st iteration of subsequent loop */
 		/* could be just 1 byte, even after waiting on data above */
 		readable = smc_rx_data_available(conn, peeked_bytes);
+		/* bytes_to_rcv is accumulated from the peer's wire-controlled
+		 * producer cursor; a forged cursor can drive it past the RMB,
+		 * or overflow the signed accumulator to a negative value across
+		 * many CDC messages (which a plain "> len" check would miss
+		 * before the size_t cast below turns it huge).  Bound it to the
+		 * RMB in either case so the wrap-around copy cannot run past
+		 * rmb_desc->len.  This enforces the documented
+		 * 0 <= bytes_to_rcv <= rmb_desc->len invariant at the consumer,
+		 * race-free against the producer update in the receive tasklet.
+		 */
+		if (readable < 0 || readable > conn->rmb_desc->len)
+			readable = conn->rmb_desc->len;
 		splbytes = atomic_read(&conn->splice_pending);
 		if (!readable || (msg && splbytes)) {
 			if (splbytes)

-- 
2.43.0

