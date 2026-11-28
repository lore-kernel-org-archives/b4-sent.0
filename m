From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 28 Nov 2026 09:23:48 -0500
Subject: [PATCH net v2 6/6] net/smc: update the urgent state under the
 socket spinlock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-disp-360e65c5-v2-6-d9c05004d430@proton.me>
References: <20261128-b4-disp-360e65c5-v2-0-d9c05004d430@proton.me>
In-Reply-To: <20261128-b4-disp-360e65c5-v2-0-d9c05004d430@proton.me>
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>
Cc: Stefan Raspl <raspl@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Tony Lu <tonylu@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875822; l=5552;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=cKpQorhXG1R2EN46yHv6FFpnAnjJofWItGyhdXnydh0=;
 b=52EUOOBVkeHj+JcivLB6j18Lkd0sR+ndlUwrnY10S/5+FMUFasZ8e86P7S1tW4YaceKCl57zI
 AjySuahXMNJD8vTzUUnmN6riZ2jncGCSxYKbSfVBTt5aedvm3zL4FCy
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_cdc_msg_recv_action() sets a new urgent mark, byte and state under
the socket spinlock, even while a reader owns the socket, and the
reader tests and changes urg_state under the socket lock only. In
smc_rx_recv_urg() a second urgent byte that arrives after the state was
set to SMC_URG_READ is returned in place of the first, and the next
recv(MSG_OOB) returns it again. In smc_rx_update_consumer() a mark set
after the test is overwritten with SMC_URG_READ: its byte is neither
returned nor skipped, and the sender, which waits for its urgent data
to be consumed, stalls.

Take the socket spinlock around both test-and-set sequences.
smc_rx_update_consumer() takes it only after a test without the lock
finds a mark or a pending skip, so a read with no urgent data is
unchanged. The lines of smc_rx_recv_urg() after its SMC_URG_VALID block
could only be reached through this race; drop them.

Fixes: de8474eb9d50 ("net/smc: urgent data support")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-215220@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_rx.c | 102 +++++++++++++++++++++++++++++++++----------------------
 1 file changed, 62 insertions(+), 40 deletions(-)

diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index 564b976426ca..2680b91e882b 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -67,26 +67,38 @@ static int smc_rx_update_consumer(struct smc_sock *smc,
 
 	smc_curs_add(conn->rmb_desc->len, &cons, len);
 
-	/* did we process urgent data? */
+	/* did we process urgent data? smc_cdc_msg_recv_action() sets a new
+	 * mark under the socket spinlock, even while we own the socket:
+	 * test again under it. A mark set after the first test is left to
+	 * the next call, like one set after the unlock.
+	 */
 	if (conn->urg_state == SMC_URG_VALID || conn->urg_rx_skip_pend) {
-		diff = smc_curs_sdiff(conn->rmb_desc->len, &cons,
-				      &conn->urg_curs);
-		if (sock_flag(sk, SOCK_URGINLINE)) {
-			if (diff == 0) {
-				force = true;
-				rc = 1;
-				conn->urg_state = SMC_URG_READ;
+		local_bh_disable();
+		bh_lock_sock(sk);
+		if (conn->urg_state == SMC_URG_VALID ||
+		    conn->urg_rx_skip_pend) {
+			diff = smc_curs_sdiff(conn->rmb_desc->len, &cons,
+					      &conn->urg_curs);
+			if (sock_flag(sk, SOCK_URGINLINE)) {
+				if (diff == 0) {
+					force = true;
+					rc = 1;
+					conn->urg_state = SMC_URG_READ;
+				}
+			} else {
+				if (diff == 1) {
+					/* skip urgent byte */
+					force = true;
+					smc_curs_add(conn->rmb_desc->len,
+						     &cons, 1);
+					conn->urg_rx_skip_pend = false;
+				} else if (diff < -1)
+					/* we read past urgent byte */
+					conn->urg_state = SMC_URG_READ;
 			}
-		} else {
-			if (diff == 1) {
-				/* skip urgent byte */
-				force = true;
-				smc_curs_add(conn->rmb_desc->len, &cons, 1);
-				conn->urg_rx_skip_pend = false;
-			} else if (diff < -1)
-				/* we read past urgent byte */
-				conn->urg_state = SMC_URG_READ;
 		}
+		bh_unlock_sock(sk);
+		local_bh_enable();
 	}
 
 	smc_curs_copy(&conn->local_tx_ctrl.cons, &cons, conn);
@@ -314,42 +326,52 @@ static int smc_rx_recv_urg(struct smc_sock *smc, struct msghdr *msg, int len,
 	struct smc_connection *conn = &smc->conn;
 	union smc_host_cursor cons;
 	struct sock *sk = &smc->sk;
+	bool valid;
+	char byte;
 	int rc = 0;
 
-	if (sock_flag(sk, SOCK_URGINLINE) ||
-	    !(conn->urg_state == SMC_URG_VALID) ||
-	    conn->urg_state == SMC_URG_READ)
+	if (sock_flag(sk, SOCK_URGINLINE))
 		return -EINVAL;
 
-	SMC_STAT_INC(smc, urg_data_cnt);
-	if (conn->urg_state == SMC_URG_VALID) {
-		if (!(flags & MSG_PEEK))
-			smc->conn.urg_state = SMC_URG_READ;
-		msg->msg_flags |= MSG_OOB;
+	/* smc_cdc_msg_recv_action() sets a new mark and byte under the
+	 * socket spinlock, even while we own the socket: take the byte
+	 * together with the state it belongs to.
+	 */
+	local_bh_disable();
+	bh_lock_sock(sk);
+	valid = conn->urg_state == SMC_URG_VALID;
+	if (valid) {
+		byte = conn->urg_rx_byte;
 		if (len > 0) {
-			if (!(flags & MSG_TRUNC))
-				rc = memcpy_to_msg(msg, &conn->urg_rx_byte, 1);
-			len = 1;
 			smc_curs_copy(&cons, &conn->local_tx_ctrl.cons, conn);
 			if (smc_curs_sdiff(conn->rmb_desc->len, &cons,
 					   &conn->urg_curs) > 1)
 				conn->urg_rx_skip_pend = true;
-			/* Urgent Byte was already accounted for, but trigger
-			 * skipping the urgent byte in non-inline case
-			 */
-			if (!(flags & MSG_PEEK))
-				smc_rx_update_consumer(smc, cons, 0);
-		} else {
-			msg->msg_flags |= MSG_TRUNC;
 		}
-
-		return rc ? -EFAULT : len;
+		if (!(flags & MSG_PEEK))
+			conn->urg_state = SMC_URG_READ;
 	}
+	bh_unlock_sock(sk);
+	local_bh_enable();
+	if (!valid)
+		return -EINVAL;
 
-	if (sk->sk_state == SMC_CLOSED || sk->sk_shutdown & RCV_SHUTDOWN)
-		return 0;
+	SMC_STAT_INC(smc, urg_data_cnt);
+	msg->msg_flags |= MSG_OOB;
+	if (len > 0) {
+		if (!(flags & MSG_TRUNC))
+			rc = memcpy_to_msg(msg, &byte, 1);
+		len = 1;
+		/* Urgent Byte was already accounted for, but trigger
+		 * skipping the urgent byte in non-inline case
+		 */
+		if (!(flags & MSG_PEEK))
+			smc_rx_update_consumer(smc, cons, 0);
+	} else {
+		msg->msg_flags |= MSG_TRUNC;
+	}
 
-	return -EAGAIN;
+	return rc ? -EFAULT : len;
 }
 
 static bool smc_rx_recvmsg_data_available(struct smc_sock *smc, size_t peeked)

-- 
2.56.1

