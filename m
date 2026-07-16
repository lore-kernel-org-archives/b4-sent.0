From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 16 Jul 2026 08:50:45 -0500
Subject: [PATCH net v3] net/smc: order the CDC receive path against buffer
 publication
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-b4-disp-aa52955a-v3-1-03a4411a7549@proton.me>
X-B4-Tracking: v=1; b=H4sIALThWGoC/x3MPQqAMAxA4atIZgP9sRW9ijhEjZqlllZEEO9uc
 fyG9x7InIQz9NUDiS/JcoQCW1cw7xQ2RlmKwSjjVas9Tg0ukiMSOdM5R+i8WnU3N5YMQcli4lX
 ufzlA4BPG9/0AAXzEXWcAAAA=
To: "D. Wythe" <alibuda@linux.alibaba.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Tony Lu <tonylu@linux.alibaba.com>
Cc: netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-s390@vger.kernel.org, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784209844; l=9556;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=8rdrQeoqAP//SANKUMiO9RanFoUJmkH6UG4jV/txETM=;
 b=WGVanU1Q5UWJ0VRvNyWdONdPuWe9Xe37CaN5HmENvtKiROmzY1mWgJbjTt8OaCpH4IYzvwtfY
 0YsU/ji30l+DzxmUSROprHb3c8ZKYjXfm/f/zOr+dIS3pJrXjbJzgIt
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SMC CDC receive handlers dereference conn->rmb_desc, and on the
SMC-D DMB-nocopy path conn->sndbuf_desc, but both are published after the
connection is already reachable to a peer: rmb_desc once the connection
is in the link group's token tree, the nocopy ghost sndbuf_desc later
still, in smcd_buf_attach() after the ISM receive tasklet is armed. A CDC
in that window hits a handler with the buffer unset -- a NULL dereference
and host DoS -- or, on a weakly ordered CPU, non-NULL but not yet
initialised. Both are also published before the receive state
(bytes_to_rcv, sndbuf_space), so an early CDC's accounting can be
overwritten by setup.

Initialise the receive state first and publish both buffers last with
smp_store_release(), consuming them with smp_load_acquire() and bailing
while unset, as the handlers already do for a killed connection. Gate the
whole sndbuf consumer trigger on the send buffer, not just the nocopy
accounting: smc_tx_prepared_sends() and smc_tx_pending() dereference it
too. Conforming peers are unaffected.

Closes: https://sashiko.dev/#/patchset/20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3:
 - Publish rmb_desc and the ghost sndbuf_desc after the receive state is
   initialised, not before. The earlier revision released the pointer first,
   which let an early CDC's accounting be overwritten by setup.
 - Gate the whole sndbuf consumer trigger on sndbuf_desc, not only the nocopy
   accounting: smc_tx_prepared_sends() and smc_tx_pending() dereference it too.
 The v2 review raised both.
v2: https://lore.kernel.org/all/20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me/
v1: https://lore.kernel.org/all/20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me/

herd7 models both orderings. Plain accesses allow the "pointer published, buffer
stale" outcome and flag a data race; release/acquire forbid it. A publish-order
litmus shows the lost update is allowed with the store released first and never
with it released last. af_smc runs over an RDMA fabric or an ISM device, so the
weak-memory arm is model-level; litmus tests and reproducer on request.

No Fixes: tag -- the rmb_desc ordering is foundational (predates the git history
here); the sndbuf_desc hunks additionally cover the later SMC-D DMB-nocopy path.
Happy to split rmb/sndbuf for a cleaner stable backport.
---
 net/smc/smc_cdc.c  | 50 +++++++++++++++++++++++++++++++++++++++++---------
 net/smc/smc_core.c | 26 ++++++++++++++++++++++----
 2 files changed, 63 insertions(+), 13 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..ea61b1e75c72 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -332,8 +332,20 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 {
 	union smc_host_cursor cons_old, prod_old;
 	struct smc_connection *conn = &smc->conn;
+	struct smc_buf_desc *sndbuf_desc;
 	int diff_cons, diff_prod, diff_tx;
 
+	/* Acquire the send buffer once, pairing with the smp_store_release() in
+	 * __smc_buf_create()/smcd_buf_attach().  On the SMC-D DMB-nocopy path
+	 * the ghost sndbuf_desc is attached only after the connection is already
+	 * reachable to the ISM device, so it can still be unset here; every
+	 * sndbuf_desc consumer below (the nocopy accounting and the sndbuf
+	 * consumer trigger, which dereferences it via smc_tx_prepared_sends())
+	 * is skipped while it is NULL to avoid a NULL deref and a load of an
+	 * uninitialised buffer.
+	 */
+	sndbuf_desc = smp_load_acquire(&conn->sndbuf_desc);
+
 	smc_curs_copy(&prod_old, &conn->local_rx_ctrl.prod, conn);
 	smc_curs_copy(&cons_old, &conn->local_rx_ctrl.cons, conn);
 	smc_cdc_msg_to_host(&conn->local_rx_ctrl, cdc, conn);
@@ -351,14 +363,17 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 
 		/* if local sndbuf shares the same memory region with
 		 * peer RMB, then update tx_curs_fin and sndbuf_space
-		 * here since peer has already consumed the data.
+		 * here since peer has already consumed the data.  The ghost
+		 * sndbuf_desc (acquired above) may still be unset in the SMC-D
+		 * DMB-nocopy setup window, so skip the update while it is NULL.
 		 */
 		if (conn->lgr->is_smcd &&
-		    smc_ism_support_dmb_nocopy(conn->lgr->smcd)) {
+		    smc_ism_support_dmb_nocopy(conn->lgr->smcd) &&
+		    sndbuf_desc) {
 			/* Calculate consumed data and
 			 * increment free send buffer space.
 			 */
-			diff_tx = smc_curs_diff(conn->sndbuf_desc->len,
+			diff_tx = smc_curs_diff(sndbuf_desc->len,
 						&conn->tx_curs_fin,
 						&conn->local_rx_ctrl.cons);
 			/* increase local sndbuf space and fin_curs */
@@ -391,10 +406,15 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 			conn->urg_state = SMC_URG_NOTYET;
 	}
 
-	/* trigger sndbuf consumer: RDMA write into peer RMBE and CDC */
-	if ((diff_cons && smc_tx_prepared_sends(conn)) ||
-	    conn->local_rx_ctrl.prod_flags.cons_curs_upd_req ||
-	    conn->local_rx_ctrl.prod_flags.urg_data_pending) {
+	/* trigger sndbuf consumer: RDMA write into peer RMBE and CDC.
+	 * smc_tx_prepared_sends() and smc_tx_pending() dereference sndbuf_desc,
+	 * so skip the whole trigger while it is unset (the SMC-D DMB-nocopy
+	 * setup window): there is nothing to send without a send buffer.
+	 */
+	if (sndbuf_desc &&
+	    ((diff_cons && smc_tx_prepared_sends(conn)) ||
+	     conn->local_rx_ctrl.prod_flags.cons_curs_upd_req ||
+	     conn->local_rx_ctrl.prod_flags.urg_data_pending)) {
 		if (!sock_owned_by_user(&smc->sk))
 			smc_tx_pending(conn);
 		else
@@ -443,13 +463,21 @@ static void smcd_cdc_rx_tsklet(struct tasklet_struct *t)
 {
 	struct smc_connection *conn = from_tasklet(conn, t, rx_tsklet);
 	struct smcd_cdc_msg *data_cdc;
+	struct smc_buf_desc *rmb_desc;
 	struct smcd_cdc_msg cdc;
 	struct smc_sock *smc;
 
 	if (!conn || conn->killed)
 		return;
+	/* Pair with smp_store_release() in __smc_buf_create(): the connection
+	 * is published before its RMB is allocated, so bail while rmb_desc is
+	 * unset to avoid a NULL deref and a load of an uninitialised buffer.
+	 */
+	rmb_desc = smp_load_acquire(&conn->rmb_desc);
+	if (!rmb_desc)
+		return;
 
-	data_cdc = (struct smcd_cdc_msg *)conn->rmb_desc->cpu_addr;
+	data_cdc = (struct smcd_cdc_msg *)rmb_desc->cpu_addr;
 	smcd_curs_copy(&cdc.prod, &data_cdc->prod, conn);
 	smcd_curs_copy(&cdc.cons, &data_cdc->cons, conn);
 	smc = container_of(conn, struct smc_sock, conn);
@@ -483,7 +511,11 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
 	lgr = smc_get_lgr(link);
 	read_lock_bh(&lgr->conns_lock);
 	conn = smc_lgr_find_conn(ntohl(cdc->token), lgr);
-	if (!conn || conn->out_of_sync) {
+	/* Pair with smp_store_release() in __smc_buf_create(): bail while the
+	 * RMB is unset (smc_cdc_msg_recv_action() dereferences it) to avoid a
+	 * NULL deref and a stale-buffer read in the connection setup window.
+	 */
+	if (!conn || conn->out_of_sync || !smp_load_acquire(&conn->rmb_desc)) {
 		read_unlock_bh(&lgr->conns_lock);
 		return;
 	}
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index cf6b620fef05..0561f83be327 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2499,15 +2499,26 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 	}
 
 	if (is_rmb) {
-		conn->rmb_desc = buf_desc;
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
 		conn->rmbe_update_limit =
 			smc_rmb_wnd_update_limit(buf_desc->len);
+		/* Publish the receive buffer last, with release semantics: the
+		 * connection is already in the link group's token tree, so a
+		 * concurrent CDC receive handler must observe the fully
+		 * initialised receive state above (and the buffer) once it sees
+		 * a non-NULL rmb_desc.  Pairs with the smp_load_acquire() in the
+		 * CDC receive path.
+		 */
+		smp_store_release(&conn->rmb_desc, buf_desc);
 		if (is_smcd)
 			smc_ism_set_conn(conn); /* map RMB/smcd_dev to conn */
 	} else {
+		/* Plain store: this send-buffer pass runs before the RMB pass,
+		 * whose smp_store_release(&conn->rmb_desc) then publishes this
+		 * store too, and the CDC receive path is gated on rmb_desc.
+		 */
 		conn->sndbuf_desc = buf_desc;
 		smc->sk.sk_sndbuf = bufsize * 2;
 		atomic_set(&conn->sndbuf_space, bufsize);
@@ -2599,9 +2610,16 @@ int smcd_buf_attach(struct smc_sock *smc)
 	buf_desc->cpu_addr =
 		(u8 *)buf_desc->cpu_addr + sizeof(struct smcd_cdc_msg);
 	buf_desc->len -= sizeof(struct smcd_cdc_msg);
-	conn->sndbuf_desc = buf_desc;
-	conn->sndbuf_desc->used = 1;
-	atomic_set(&conn->sndbuf_space, conn->sndbuf_desc->len);
+	buf_desc->used = 1;
+	atomic_set(&conn->sndbuf_space, buf_desc->len);
+	/* Publish the ghost send buffer last, with release semantics: the
+	 * connection is already reachable to the ISM device (smc_ism_set_conn()
+	 * ran in __smc_buf_create()), so the CDC receive tasklet must observe
+	 * the fully initialised ghost buffer once it sees a non-NULL
+	 * sndbuf_desc.  Pairs with smp_load_acquire() in
+	 * smc_cdc_msg_recv_action().
+	 */
+	smp_store_release(&conn->sndbuf_desc, buf_desc);
 	return 0;
 
 free:

---
base-commit: 3f1f755366687d051174739fb99f7d560202f60b
change-id: 20260716-b4-disp-aa52955a-560f19c43a2a

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

