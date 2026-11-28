From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 28 Nov 2026 09:23:47 -0500
Subject: [PATCH net v2 5/6] net/smc: order the urgent mark across the
 cursor wrap rollover
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-disp-360e65c5-v2-5-d9c05004d430@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875822; l=3361;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Rc4x6htG50veeFexiJAu4UvukFo13BH1Sck0r9zaQTY=;
 b=j4YK2CVd4P1ZR5Zj0nEBlLM12vRNgq6xNEgx/lFQebYHO6m3RflBXw0d942nMmqCSUIIRNfaa
 BI5CIUtZRVkDNogPrXIx9megx8qC5C9pfDV1GU/oJFTpRIHu7dmiwDM
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_rx_update_consumer() orders the consumer cursor against urg_curs
with smc_curs_comp(), which misorders them across the 65535 -> 0
rollover of the RMB wrap. Without SO_OOBINLINE, with the reader on wrap
65535 and the urgent byte on wrap 0, the mark reads as already passed:
urg_state becomes SMC_URG_READ before the byte is reached and
recv(MSG_OOB) fails with -EINVAL. The urgent byte, which bytes_to_rcv
leaves out, is then never skipped. The sender waits for its urgent data
to be consumed before it sends more, so the connection stalls.
smc_rx_recv_urg() compares the same two cursors with smc_curs_diff(). A
consumer cursor that is past the mark on the RMB's next wrap reads as
far behind it, and urg_rx_skip_pend is set with nothing left to skip.

Use smc_curs_sdiff() in both, which orders the two cursors whatever
their wraps. smc_curs_comp() has no other user; remove it.

Fixes: de8474eb9d50 ("net/smc: urgent data support")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.h | 13 -------------
 net/smc/smc_rx.c  | 11 ++++++-----
 2 files changed, 6 insertions(+), 18 deletions(-)

diff --git a/net/smc/smc_cdc.h b/net/smc/smc_cdc.h
index 4b586a20dfc2..eecd0cc5bb79 100644
--- a/net/smc/smc_cdc.h
+++ b/net/smc/smc_cdc.h
@@ -167,19 +167,6 @@ static inline int smc_curs_diff(unsigned int size,
 	return max_t(int, 0, (new->count - old->count));
 }
 
-/* calculate cursor difference between old and new - returns negative
- * value in case old > new
- */
-static inline int smc_curs_comp(unsigned int size,
-				union smc_host_cursor *old,
-				union smc_host_cursor *new)
-{
-	if (old->wrap > new->wrap ||
-	    (old->wrap == new->wrap && old->count > new->count))
-		return -smc_curs_diff(size, new, old);
-	return smc_curs_diff(size, old, new);
-}
-
 /* signed distance from old to new; the wrap difference is taken as s16,
  * so it holds across the u16 wrap rollover, for cursors less than 32768
  * rings apart
diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index 63c178c10bf1..564b976426ca 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -62,14 +62,15 @@ static int smc_rx_update_consumer(struct smc_sock *smc,
 	struct smc_connection *conn = &smc->conn;
 	struct sock *sk = &smc->sk;
 	bool force = false;
-	int diff, rc = 0;
+	int rc = 0;
+	s64 diff;
 
 	smc_curs_add(conn->rmb_desc->len, &cons, len);
 
 	/* did we process urgent data? */
 	if (conn->urg_state == SMC_URG_VALID || conn->urg_rx_skip_pend) {
-		diff = smc_curs_comp(conn->rmb_desc->len, &cons,
-				     &conn->urg_curs);
+		diff = smc_curs_sdiff(conn->rmb_desc->len, &cons,
+				      &conn->urg_curs);
 		if (sock_flag(sk, SOCK_URGINLINE)) {
 			if (diff == 0) {
 				force = true;
@@ -330,8 +331,8 @@ static int smc_rx_recv_urg(struct smc_sock *smc, struct msghdr *msg, int len,
 				rc = memcpy_to_msg(msg, &conn->urg_rx_byte, 1);
 			len = 1;
 			smc_curs_copy(&cons, &conn->local_tx_ctrl.cons, conn);
-			if (smc_curs_diff(conn->rmb_desc->len, &cons,
-					  &conn->urg_curs) > 1)
+			if (smc_curs_sdiff(conn->rmb_desc->len, &cons,
+					   &conn->urg_curs) > 1)
 				conn->urg_rx_skip_pend = true;
 			/* Urgent Byte was already accounted for, but trigger
 			 * skipping the urgent byte in non-inline case

-- 
2.56.1

