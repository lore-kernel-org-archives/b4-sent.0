From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 07:59:37 -0500
Subject: [PATCH net v9 3/6] net/smc: bound the send length to the send
 buffer in smc_tx_sendmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-0287c16e-v9-3-e5e8fa688177@proton.me>
References: <20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me>
In-Reply-To: <20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me>
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, "David S. Miller" <davem@davemloft.net>, 
 Jakub Kicinski <kuba@kernel.org>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Ursula Braun <ubraun@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-s390@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Simon Horman <horms@kernel.org>, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794488375; l=3799;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=ioWt2nFN8deKKR5Xb2UG2DAkkoZuzmKYXtUilMMIgkA=;
 b=ff6Z2RzXixcmmtuatiFKXxb3m30/JFoQZNnsf61UBEpoJoOC/NbrFVDwPQOA1qiQS2WCjCsmb
 IR12c1YbPFKDvIA8kz3zsUUVnni+GPhYA9bMmKZd8IZPNOtRbphBl22
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

conn->sndbuf_space can run past the send buffer. After an SMC-R link
failover, a late completion from the old link can move tx_curs_fin back,
and the next completion credits the same bytes again; across the ring
end, smc_curs_diff() credits the step back itself as more than a whole
ring, so even with a conforming peer sndbuf_space can reach three times
the buffer. The failover catch-up and SMC-D DMB merge (only the loopback
device today) also credit it from the peer's consumer cursor without a
bound. smc_tx_sendmsg() takes it as the write space, and the second
chunk of its copy writes past the send buffer.

Clamp writespace, which sizes the copy, to sndbuf_desc->len, negative
values included, so the copy stays in the send buffer. The over-credit
itself is not undone: with sndbuf_space too large, send() can still
overwrite data in the send buffer that the peer has not received.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Fixes: cc0ab806fc52 ("net/smc: adapt cursor update when sndbuf and peer DMB are merged")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Dust Li <dust.li@linux.alibaba.com>
Reviewed-by: Sidraya Jayagond <sidraya@linux.ibm.com>
---
The overwrite after an over-credit is by inspection; not tested. Fixing
the credit in smc_cdc_tx_handler() needs a cursor compare that survives
the u16 wrap rollover, which smc_curs_comp() does not do, so it is left
out here. A negative value maps to len, not 0, since 0 would make the
send loop spin.
---
 net/smc/smc_cdc.c |  2 +-
 net/smc/smc_tx.c  | 10 +++++++++-
 2 files changed, 10 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index e2c765ff2ba3..90a79a983b48 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -43,7 +43,7 @@ static void smc_cdc_tx_handler(struct smc_wr_tx_pend_priv *pnd_snd,
 		/* sndbuf_space is decreased in smc_sendmsg */
 		smp_mb__before_atomic();
 		atomic_add(diff, &cdcpend->conn->sndbuf_space);
-		/* guarantee 0 <= sndbuf_space <= sndbuf_desc->len */
+		/* can be out of range, see smc_tx_sendmsg() */
 		smp_mb__after_atomic();
 		smc_curs_copy(&conn->tx_curs_fin, &cdcpend->cursor, conn);
 		smc_curs_copy(&conn->local_tx_ctrl_fin, &cdcpend->p_cursor,
diff --git a/net/smc/smc_tx.c b/net/smc/smc_tx.c
index 0f0c6df3bf2c..3913ef103b35 100644
--- a/net/smc/smc_tx.c
+++ b/net/smc/smc_tx.c
@@ -233,6 +233,14 @@ int smc_tx_sendmsg(struct smc_sock *smc, struct msghdr *msg, size_t len)
 		/* initialize variables for 1st iteration of subsequent loop */
 		/* could be just 1 byte, even after smc_tx_wait above */
 		writespace = atomic_read(&conn->sndbuf_space);
+		/* sndbuf_space can be out of range: late completions of an
+		 * old SMC-R link credit it again after a failover, and with
+		 * SMC-D DMB merge it follows the peer's consumer cursor.
+		 * Bound writespace, which sizes the copy; a negative value
+		 * would become huge in the size_t min_t() below.
+		 */
+		if (writespace < 0 || writespace > conn->sndbuf_desc->len)
+			writespace = conn->sndbuf_desc->len;
 		/* not more than what user space asked for */
 		copylen = min_t(size_t, send_remaining, writespace);
 		/* determine start of sndbuf */
@@ -278,7 +286,7 @@ int smc_tx_sendmsg(struct smc_sock *smc, struct msghdr *msg, size_t len)
 		/* increased in send tasklet smc_cdc_tx_handler() */
 		smp_mb__before_atomic();
 		atomic_sub(copylen, &conn->sndbuf_space);
-		/* guarantee 0 <= sndbuf_space <= sndbuf_desc->len */
+		/* can be out of range, see writespace above */
 		smp_mb__after_atomic();
 		/* since we just produced more new data into sndbuf,
 		 * trigger sndbuf consumer: RDMA write into peer RMBE and CDC

-- 
2.56.0

