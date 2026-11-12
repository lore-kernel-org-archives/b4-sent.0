From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 07:59:36 -0500
Subject: [PATCH net v9 2/6] net/smc: bound the receive length to the RMB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-0287c16e-v9-2-e5e8fa688177@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794488375; l=7328;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=L04qSXw7HxPjxskjaVdA+heWOrdU6VRxVTt4ADzW71k=;
 b=MHldl2jRMuehMOviHeXXwU87Dt56cbbB5lIWm+FP2yZznslhbjt/TyuNhNwNMMAevTsGJfQrr
 2k9b/y85lwhAmtx39+WM8fyzfDh4gHrpFAtRb7vfZAxHQ9Eho3dFNvl
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_rx_recvmsg() sizes the copy from bytes_to_rcv and starts it past the
bytes MSG_PEEK or splice() already took. A forged producer cursor drives
bytes_to_rcv past the RMB or negative, and with a conforming peer it
drops below the peeked count when a MSG_PEEK|MSG_WAITALL reader sleeps
while another recv() consumes what it peeked. Either way the copy reads
past the RMB into the reader's buffer. poll(), SIOCINQ and the deferred
accept read the same raw count.

Make smc_rx_data_available() report at most what fits in the RMB behind
the peeked and spliced bytes, never a negative count, and use it in all
of these. Cache the RMB length for the unlocked wait, where rmb_desc may
already be freed, and drop released bytes from splice_pending under the
socket lock, with the consumer cursor update, so a reader cannot run
between the two and count them twice.

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
already have freed rmb_desc, hence the cached length; v9 reads and
writes it with READ_ONCE()/WRITE_ONCE(). With the old splice_pending
order, a reader that took the lock between the cursor update and the
drop counted the bytes twice, and the next splice() returned stale bytes
in place of unread data. 1/6 bounds the producer count, but wrap bumps
still grow bytes_to_rcv past the RMB (see the cover).
---
 net/smc/af_smc.c   |  6 +++---
 net/smc/smc.h      |  3 +++
 net/smc/smc_cdc.c  |  2 +-
 net/smc/smc_core.c |  1 +
 net/smc/smc_rx.c   |  9 +++++++--
 net/smc/smc_rx.h   | 12 +++++++++++-
 6 files changed, 26 insertions(+), 7 deletions(-)

diff --git a/net/smc/af_smc.c b/net/smc/af_smc.c
index ec5980add7a9..90e7d0d2e398 100644
--- a/net/smc/af_smc.c
+++ b/net/smc/af_smc.c
@@ -2774,7 +2774,7 @@ int smc_accept(struct socket *sock, struct socket *new_sock,
 			if (skb_queue_empty(&clcsk->sk_receive_queue))
 				sk_wait_data(clcsk, &timeo, NULL);
 			release_sock(clcsk);
-		} else if (!atomic_read(&smc_sk(nsk)->conn.bytes_to_rcv)) {
+		} else if (!smc_rx_data_available(&smc_sk(nsk)->conn, 0)) {
 			lock_sock(nsk);
 			smc_rx_wait(smc_sk(nsk), &timeo, 0, smc_rx_data_available);
 			release_sock(nsk);
@@ -2939,7 +2939,7 @@ __poll_t smc_poll(struct file *file, struct socket *sock,
 						mask |= EPOLLOUT | EPOLLWRNORM;
 				}
 			}
-			if (atomic_read(&smc->conn.bytes_to_rcv))
+			if (smc_rx_data_available(&smc->conn, 0))
 				mask |= EPOLLIN | EPOLLRDNORM;
 			if (sk->sk_shutdown & RCV_SHUTDOWN)
 				mask |= EPOLLIN | EPOLLRDNORM | EPOLLRDHUP;
@@ -3237,7 +3237,7 @@ int smc_ioctl(struct socket *sock, unsigned int cmd,
 		    smc->sk.sk_state == SMC_CLOSED)
 			answ = 0;
 		else
-			answ = atomic_read(&smc->conn.bytes_to_rcv);
+			answ = smc_rx_data_available(&smc->conn, 0);
 		break;
 	case SIOCOUTQ:
 		/* output queue size (not send + not acked) */
diff --git a/net/smc/smc.h b/net/smc/smc.h
index 36b243b34a9a..8601304b3c06 100644
--- a/net/smc/smc.h
+++ b/net/smc/smc.h
@@ -204,6 +204,9 @@ struct smc_connection {
 						 * rmbe
 						 */
 	int			rtoken_idx;	/* idx to peer RMB rkey/addr */
+	int			rmb_len;	/* rmb_desc->len, still valid
+						 * after rmb_desc is freed
+						 */
 
 	struct smc_buf_desc	*sndbuf_desc;	/* send buffer descriptor */
 	struct smc_buf_desc	*rmb_desc;	/* RMBE descriptor */
diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..e2c765ff2ba3 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -381,7 +381,7 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 		/* bytes_to_rcv is decreased in smc_recvmsg */
 		smp_mb__before_atomic();
 		atomic_add(diff_prod, &conn->bytes_to_rcv);
-		/* guarantee 0 <= bytes_to_rcv <= rmb_desc->len */
+		/* can be out of range, see smc_rx_data_available() */
 		smp_mb__after_atomic();
 		smc->sk.sk_data_ready(&smc->sk);
 	} else {
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 0a9f5418329a..0edbe6106c1a 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2511,6 +2511,7 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 
 	if (is_rmb) {
 		conn->rmb_desc = buf_desc;
+		WRITE_ONCE(conn->rmb_len, buf_desc->len);
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index 63c178c10bf1..78ab3df1689c 100644
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
+	/* lower splice_pending under the socket lock, with the cons update, or
+	 * a reader running between the two counts the released bytes twice
+	 */
+	drained = atomic_sub_and_test(priv->len, &conn->splice_pending);
 	smc_rx_update_cons(smc, priv->len);
 	release_sock(sk);
-	if (atomic_sub_and_test(priv->len, &conn->splice_pending))
+	if (drained)
 		smc_rx_wake_up(sk);
 out:
 	kfree(priv);
@@ -543,7 +548,7 @@ int smc_rx_recvmsg(struct smc_sock *smc, struct msghdr *msg,
 			/* increased in recv tasklet smc_cdc_msg_rcv() */
 			smp_mb__before_atomic();
 			atomic_sub(copylen, &conn->bytes_to_rcv);
-			/* guarantee 0 <= bytes_to_rcv <= rmb_desc->len */
+			/* can be out of range, see smc_rx_data_available() */
 			smp_mb__after_atomic();
 			if (msg && smc_rx_update_consumer(smc, cons, copylen))
 				goto out;
diff --git a/net/smc/smc_rx.h b/net/smc/smc_rx.h
index 994f5e42d1ba..1833eca15bfb 100644
--- a/net/smc/smc_rx.h
+++ b/net/smc/smc_rx.h
@@ -25,7 +25,17 @@ int smc_rx_wait(struct smc_sock *smc, long *timeo, size_t peeked,
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
+	avail = min(avail, READ_ONCE(conn->rmb_len) -
+			   atomic_read(&conn->splice_pending));
+	return avail > (int)peeked ? avail - (int)peeked : 0;
 }
 
 #endif /* SMC_RX_H */

-- 
2.56.0

