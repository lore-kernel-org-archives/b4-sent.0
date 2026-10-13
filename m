From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 13 Oct 2026 15:12:49 -0500
Subject: [PATCH net v7 2/4] net/smc: bound the receive length to the RMB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-disp-f345196c-v7-2-ef3dddfbfa68@proton.me>
References: <20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me>
In-Reply-To: <20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me>
To: "D. Wythe" <alibuda@linux.alibaba.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, linux-rdma@vger.kernel.org, 
 Stefan Raspl <raspl@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wen Gu <guwen@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791922368; l=4891;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=WO6JE1/adE/4enEj6zr53PT4E+4sxDNOtNP9RW/QtGU=;
 b=dJVEzgAj1vgolb37GpaxkDKmrT2lJeSMcUxhHDJ/6AsC9BignokEKKt91HpeoyxMAnpWzXD07
 65nGiJJuINTBETl0aMOCbW8s8r5Y1/C1V4xpxFMSFa44axF+m6vvEpz
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_rx_recvmsg() sizes the copy from bytes_to_rcv and starts it past the
bytes MSG_PEEK or splice() already took. A forged producer cursor drives
bytes_to_rcv past the RMB or negative, and with a conforming peer it
drops below the peeked count when a MSG_PEEK|MSG_WAITALL reader sleeps
while another recv() consumes what it peeked. Either way the copy reads
past the RMB into the reader's buffer: the second chunk runs long, or
the start offset leaves the RMB, as smc_curs_add() wraps only once.

Make smc_rx_data_available() report at most what fits in the RMB behind
the peeked and spliced bytes, never a negative count, and use it for the
copy and the wait predicates. Cache the RMB length for the unlocked
wait, and drop released bytes from splice_pending before the consumer
cursor moves past them, so no reader counts them twice.

Fixes: 952310ccf2d8 ("smc: receive data from RMBE")
Fixes: 9014db202cb7 ("smc: add support for splice()")
Fixes: a4b6539038c1 ("net/smc: fix data error when recvmsg with MSG_PEEK flag")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me?part=2
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c%40proton.me?part=2
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c%40proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
The wait predicates run unlocked, where a link group termination may
already have freed rmb_desc, hence the cached length. With the old
splice_pending order, a reader that took the lock between the cursor
update and the drop counted the bytes twice, and the next splice()
returned stale bytes in place of unread data. 1/4 bounds the producer
count, but wrap bumps still grow bytes_to_rcv past the RMB (see the
cover).
---
 net/smc/smc.h      |  3 +++
 net/smc/smc_core.c |  1 +
 net/smc/smc_rx.c   |  7 ++++++-
 net/smc/smc_rx.h   | 11 ++++++++++-
 4 files changed, 20 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc.h b/net/smc/smc.h
index 427b6d63b993..d4325a0a8fd8 100644
--- a/net/smc/smc.h
+++ b/net/smc/smc.h
@@ -203,6 +203,9 @@ struct smc_connection {
 						 * rmbe
 						 */
 	int			rtoken_idx;	/* idx to peer RMB rkey/addr */
+	int			rmb_len;	/* rmb_desc->len, still valid
+						 * after rmb_desc is freed
+						 */
 
 	struct smc_buf_desc	*sndbuf_desc;	/* send buffer descriptor */
 	struct smc_buf_desc	*rmb_desc;	/* RMBE descriptor */
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 9974149659c2..8829517299de 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2503,6 +2503,7 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 
 	if (is_rmb) {
 		conn->rmb_desc = buf_desc;
+		conn->rmb_len = buf_desc->len;
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index 197fddc6271f..c968ac874d8b 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -118,15 +118,20 @@ static void smc_rx_pipe_buf_release(struct pipe_inode_info *pipe,
 	struct smc_connection *conn = &priv->smc->conn;
 	struct smc_sock *smc = priv->smc;
 	struct sock *sk = &smc->sk;
+	bool drained;
 
 	lock_sock(sk);
 	if (conn->freed) {
 		release_sock(sk);
 		goto out;
 	}
+	/* drop the released bytes from splice_pending before cons moves
+	 * past them, so no reader counts them twice
+	 */
+	drained = atomic_sub_and_test(priv->len, &conn->splice_pending);
 	smc_rx_update_cons(smc, priv->len);
 	release_sock(sk);
-	if (atomic_sub_and_test(priv->len, &conn->splice_pending))
+	if (drained)
 		smc_rx_wake_up(sk);
 out:
 	kfree(priv);
diff --git a/net/smc/smc_rx.h b/net/smc/smc_rx.h
index 994f5e42d1ba..6bf44e3cc33a 100644
--- a/net/smc/smc_rx.h
+++ b/net/smc/smc_rx.h
@@ -25,7 +25,16 @@ int smc_rx_wait(struct smc_sock *smc, long *timeo, size_t peeked,
 		int (*fcrit)(struct smc_connection *conn, size_t baseline));
 static inline int smc_rx_data_available(struct smc_connection *conn, size_t peeked)
 {
-	return atomic_read(&conn->bytes_to_rcv) - peeked;
+	int avail = atomic_read(&conn->bytes_to_rcv);
+
+	/* bytes_to_rcv follows the peer's producer cursor and can be past
+	 * the RMB or negative. Report no more than fits in the RMB behind the
+	 * bytes already spliced or peeked. Compare before subtracting: near
+	 * INT_MIN, avail - peeked wraps. This also runs unlocked, possibly
+	 * after rmb_desc was freed, hence rmb_len.
+	 */
+	avail = min(avail, conn->rmb_len - atomic_read(&conn->splice_pending));
+	return avail > (int)peeked ? avail - (int)peeked : 0;
 }
 
 #endif /* SMC_RX_H */

-- 
2.56.0

