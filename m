From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 28 Jul 2026 11:52:53 -0500
Subject: [PATCH net v4] net/smc: order the CDC receive path against buffer
 publication
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-b4-disp-52ee4e7d-v4-1-0dda94b0f397@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6CQBBG4auQqZkE1sEFrkIshP3RoQCyA8aEc
 HdXLb/ivYMMUWHUZgdFvNR0mRMkz2h43ucHWEMyucJdC+9q7oWD2sqVAwQ+8EVqX8mIpkSglK0
 Ro75/y+72t+39hGH7fug8P1dKY+l0AAAA
X-Change-ID: 20260728-b4-disp-52ee4e7d-348754fe91ed
To: Tony Lu <tonylu@linux.alibaba.com>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@google.com>, "David S. Miller" <davem@davemloft.net>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>
Cc: Hans Wippel <hwippel@linux.ibm.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-s390@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, linux-rdma@vger.kernel.org, 
 Ursula Braun <ubraun@linux.ibm.com>, Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785257572; l=10163;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Vts1TiiPbGpD3Qv/nKiQnSpqKQKxXy38+nvWx/7Gr0s=;
 b=Fd8GQGB24INiIZa3WpnsGbRwVJbGzz5vUjvCCb5AUxxJTvnAWEpIDFlAZNPCoM3UgqT48stXc
 JEitAt5kWyVAbMCGZDgXM/lJs23TeD1KfDyOji6gXywl102Z39zyf7a
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
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

Fixes: 69cb7dc0218b ("net/smc: add common buffer size in send and receive buffer descriptors")
Closes: https://sashiko.dev/#/patchset/20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v4: Add the Fixes: tag Jakub asked for. 69cb7dc0218b is where the CDC path
 started reading the buffer length through a descriptor pointer -- it replaced
 conn->rmbe_size and conn->sndbuf_size with conn->rmb_desc->len and
 conn->sndbuf_desc->len -- so it is the first commit where an unpublished
 buffer can be dereferenced here. The token lookup itself is older
 (5f08318f617b, 2017), but it read a scalar, so there was nothing to
 dereference. The SMC-D DMB-nocopy hunks cover the ghost sndbuf_desc, added
 by ae2be35cbed2; a tree without that commit needs only the rmb_desc part.
v3: https://lore.kernel.org/all/20260716-b4-disp-aa52955a-v3-1-03a4411a7549@proton.me/
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
index b4208cb186c5..33bf9cc979ef 100644
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
base-commit: e095f249e2209674f6366f6db0383a2b96e19239
change-id: 20260728-b4-disp-52ee4e7d-348754fe91ed

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

