From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 13 Nov 2026 23:14:41 -0500
Subject: [PATCH net 2/4] net/smc: do not credit stale CDC completions after
 a link switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-disp-1a9ab9b0-v1-2-4a7c8d85d849@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629679; l=4521;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=4Sn2P9DnOXO+NKmDKGa450qGEUkjLHBVxYGVT0Ek9hM=;
 b=vvdKcaXBQp92ElfK8fPvAdaTwcm4VaH+L4+m6+YKPDBoSXaL+C1Pa2ZULKIVhQxlZLid5RMsH
 xMokkbmQ6saDyaMA+v5Z7LZTvKAQLP0GSDJgUPz50QXd2UubiIsfJ9i
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A successful completion on the old link handled after
smc_switch_cursor() credits bytes that were rewound for resend, so the
application can overwrite send buffer data before it is resent. A
connection in a closing state is moved to the new link without a rewind;
when completions on the two links are then handled out of order, one
whose cursor is behind tx_curs_fin moves tx_curs_fin back and the same
bytes are credited again, which can take sndbuf_space past the send
buffer size.

Tag each CDC pend with a switch generation that smc_switch_cursor()
bumps, and credit a completion only if it is of the current generation
and its cursor is not behind tx_curs_fin.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc.h      |  3 +++
 net/smc/smc_cdc.c  | 11 ++++++++++-
 net/smc/smc_cdc.h  | 13 +++++++++++++
 net/smc/smc_core.c |  1 +
 4 files changed, 27 insertions(+), 1 deletion(-)

diff --git a/net/smc/smc.h b/net/smc/smc.h
index 36b243b34a9a..96f017938b9c 100644
--- a/net/smc/smc.h
+++ b/net/smc/smc.h
@@ -233,6 +233,9 @@ struct smc_connection {
 	atomic_t		sndbuf_space;	/* remaining space in sndbuf */
 	u16			tx_cdc_seq;	/* sequence # for CDC send */
 	u16			tx_cdc_seq_fin;	/* sequence # - tx completed */
+	u16			tx_switch_gen;	/* bumped when a link switch
+						 * rewinds the tx cursors
+						 */
 	spinlock_t		send_lock;	/* protect wr_sends */
 	atomic_t		cdc_pend_tx_wr; /* number of pending tx CDC wqe
 						 * - inc when post wqe,
diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..d1f346376c08 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -36,7 +36,15 @@ static void smc_cdc_tx_handler(struct smc_wr_tx_pend_priv *pnd_snd,
 	sndbuf_desc = conn->sndbuf_desc;
 	smc = container_of(conn, struct smc_sock, conn);
 	bh_lock_sock(&smc->sk);
-	if (!wc_status && sndbuf_desc) {
+	/* A CDC posted before a link switch rewound the cursors: its bytes
+	 * are resent on the new link or credited by the switch's catch-up.
+	 * A cursor behind tx_curs_fin (completions on two links in any
+	 * order) was credited already.
+	 */
+	if (!wc_status && sndbuf_desc &&
+	    cdcpend->switch_gen == conn->tx_switch_gen &&
+	    smc_curs_sdiff(sndbuf_desc->len, &conn->tx_curs_fin,
+			   &cdcpend->cursor) >= 0) {
 		diff = smc_curs_diff(sndbuf_desc->len,
 				     &cdcpend->conn->tx_curs_fin,
 				     &cdcpend->cursor);
@@ -107,6 +115,7 @@ static inline void smc_cdc_add_pending_send(struct smc_connection *conn,
 	pend->cursor = conn->tx_curs_sent;
 	pend->p_cursor = conn->local_tx_ctrl.prod;
 	pend->ctrl_seq = conn->tx_cdc_seq;
+	pend->switch_gen = conn->tx_switch_gen;
 }
 
 int smc_cdc_msg_send(struct smc_connection *conn,
diff --git a/net/smc/smc_cdc.h b/net/smc/smc_cdc.h
index 696cc11f2303..597acb2e123f 100644
--- a/net/smc/smc_cdc.h
+++ b/net/smc/smc_cdc.h
@@ -170,6 +170,18 @@ static inline int smc_curs_comp(unsigned int size,
 	return smc_curs_diff(size, old, new);
 }
 
+/* signed distance from old to new; the wrap difference is taken as s16,
+ * so it holds across the u16 wrap rollover, for cursors less than 32768
+ * rings apart
+ */
+static inline s64 smc_curs_sdiff(unsigned int size,
+				 union smc_host_cursor *old,
+				 union smc_host_cursor *new)
+{
+	return (s64)(s16)(new->wrap - old->wrap) * size +
+	       (s64)new->count - old->count;
+}
+
 /* calculate cursor difference between old and new, where old <= new and
  * difference may exceed size
  */
@@ -284,6 +296,7 @@ struct smc_cdc_tx_pend {
 	union smc_host_cursor	cursor;		/* tx sndbuf cursor sent */
 	union smc_host_cursor	p_cursor;	/* rx RMBE cursor produced */
 	u16			ctrl_seq;	/* conn. tx sequence # */
+	u16			switch_gen;	/* tx_switch_gen at send */
 };
 
 int smc_cdc_get_free_slot(struct smc_connection *conn,
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 73e86100e6db..fb9f6a4eb683 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1058,6 +1058,7 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 	int rc = 0;
 	int diff;
 
+	conn->tx_switch_gen++;	/* completions of earlier sends: no credit */
 	smc_curs_copy(&conn->tx_curs_sent, &conn->tx_curs_fin, conn);
 	smc_curs_copy(&fin, &conn->local_tx_ctrl_fin, conn);
 	/* set prod cursor to old state, enforce tx_rdma_writes() */

-- 
2.56.0

