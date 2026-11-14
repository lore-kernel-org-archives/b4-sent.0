From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 13 Nov 2026 23:14:43 -0500
Subject: [PATCH net 4/4] net/smc: order the urgent mark across the cursor
 wrap rollover
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-disp-1a9ab9b0-v1-4-4a7c8d85d849@proton.me>
References: <20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me>
In-Reply-To: <20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me>
To: Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Paolo Abeni <pabeni@redhat.com>, Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, netdev@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 Wen Gu <guwen@linux.alibaba.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-rdma@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629679; l=2415;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=H0cDzBMU5jnWhuir5b0Y+uamDOQJx9v7YnLHHqnWujU=;
 b=alisxctGY78SwE7oHxLyUorWTGmWoZBmYFTPJ7GI45VR5SB/8i0kWOibNF6J7f4E+tArli1n2
 Lz/ru3MfW06AG4Oar/5Hyqm71sIY1CnsCs2ed4wib0RTDUhShCTI8WV
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
leaves out, is then never skipped, and the sender, which waits for its
urgent data to be consumed before it sends more, sends nothing more:
the connection stalls.

Use smc_curs_sdiff(), which orders the two cursors across the
rollover. smc_curs_comp() has no other user; remove it.

Fixes: de8474eb9d50 ("net/smc: urgent data support")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.h | 13 -------------
 net/smc/smc_rx.c  |  4 ++--
 2 files changed, 2 insertions(+), 15 deletions(-)

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
index 63c178c10bf1..0345167cdc0d 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -68,8 +68,8 @@ static int smc_rx_update_consumer(struct smc_sock *smc,
 
 	/* did we process urgent data? */
 	if (conn->urg_state == SMC_URG_VALID || conn->urg_rx_skip_pend) {
-		diff = smc_curs_comp(conn->rmb_desc->len, &cons,
-				     &conn->urg_curs);
+		diff = smc_curs_sdiff(conn->rmb_desc->len, &cons,
+				      &conn->urg_curs);
 		if (sock_flag(sk, SOCK_URGINLINE)) {
 			if (diff == 0) {
 				force = true;

-- 
2.56.0

