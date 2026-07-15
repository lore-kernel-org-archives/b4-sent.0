From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 14 Jul 2026 23:34:42 -0500
Subject: [PATCH net v2] net/smc: order the CDC receive path against buffer
 publication
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me>
X-B4-Tracking: v=1; b=H4sIAOENV2oC/x3MTQqAIBBA4avErBvI6UfpKtHCcqzZWGhEEN49a
 fkt3nshcRROMFYvRL4lyREKqK5g3W3YGMUVAzU0NFp1uHToJJ1o2p6MsQMqr8l747TVCkp2Rvb
 y/MsJAl8w5/wBB6Gs1mcAAAA=
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Dust Li <dust.li@linux.alibaba.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Eric Dumazet <edumazet@google.com>, Tony Lu <tonylu@linux.alibaba.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784090081; l=7310;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=2xz4cjDnqoAG1H/FZ06+DlrFtR6erHNnU+ZElifwqQs=;
 b=1ZcEFXlHow9qiTEgF62ozWBR3XP1RmBrt3w4BuchwclJvBZ5VwhHh4vUPYdZCfZpWAYZSDbXU
 1vUitCp2sylCks4GvsFDSIS0P7jVG+BS99BotcywZGX1OQAQ8mlklP1
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SMC CDC receive handlers dereference conn->rmb_desc, and on the
SMC-D DMB-nocopy path conn->sndbuf_desc, but both are published after
the connection is already reachable to a peer: rmb_desc after
smc_conn_create() registers it in the link group's token tree,
sndbuf_desc after __smc_buf_create() arms the ISM tasklet via
smc_ism_set_conn().  A CDC in that window reaches the handlers with the
buffer unset.  The store is plain, so a handler can load it as NULL, or
on a weakly ordered CPU see it non-NULL while its buffer is still
uninitialised -- a host crash or a stale-buffer read.

Publish both buffers with smp_store_release() and consume them with
smp_load_acquire(), bailing while unset as the handlers already do for
a killed or out-of-sync connection.  Conforming peers are unaffected.

Closes: https://sashiko.dev/#/patchset/20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2: order both CDC-reachable buffers with smp_store_release()/smp_load_acquire()
    instead of the plain NULL guard v1 used.  The rmb_desc ordering is what the
    Sashiko review of v1 asked for (the Closes: link above); the sndbuf_desc case
    (SMC-D DMB-nocopy, smc_cdc_msg_recv_action()) is the same-window sibling found
    by inspection -- smcd_buf_attach() sets the ghost sndbuf_desc after
    smc_ism_set_conn() already armed the tasklet.  Release/acquire closes the NULL
    deref on all arches and the stale-buffer read on weakly ordered ones.
    v1: https://lore.kernel.org/all/20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me/

Happy to split this: the sndbuf_desc hunks only apply where the DMB-nocopy path
exists and can carry their own Fixes: tag for a cleaner stable backport, while the
rmb_desc ordering predates the git history here.  No Fixes: added -- please add
whichever you prefer.

Both orderings are modelled with LKMM message-passing litmus tests (herd7): plain
accesses allow the "pointer published, buffer stale" outcome and flag a data race;
smp_store_release()/smp_load_acquire() forbid it.  The patched build was exercised
over an SMC-D loopback under KASAN with no regression; the rmb_desc NULL-deref arm
is reproduced with an in-kernel KASAN model faulting at the ->cpu_addr / ->len
offsets.  af_smc runs over an RDMA fabric or an ISM device, so the weak-memory arm
is model-level; litmus tests and reproducer available on request.
---
 net/smc/smc_cdc.c  | 29 +++++++++++++++++++++++++----
 net/smc/smc_core.c | 16 ++++++++++++++--
 2 files changed, 39 insertions(+), 6 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..2cd0ee7b51c2 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -332,6 +332,7 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 {
 	union smc_host_cursor cons_old, prod_old;
 	struct smc_connection *conn = &smc->conn;
+	struct smc_buf_desc *sndbuf_desc;
 	int diff_cons, diff_prod, diff_tx;
 
 	smc_curs_copy(&prod_old, &conn->local_rx_ctrl.prod, conn);
@@ -353,12 +354,20 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 		 * peer RMB, then update tx_curs_fin and sndbuf_space
 		 * here since peer has already consumed the data.
 		 */
+		/* Pair with smp_store_release() in smcd_buf_attach(): the ghost
+		 * sndbuf_desc is attached after the connection is reachable to
+		 * the ISM device, so acquire it and skip the update while it is
+		 * unset -- avoids a NULL deref and a load of an uninitialised
+		 * buffer.
+		 */
+		sndbuf_desc = smp_load_acquire(&conn->sndbuf_desc);
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
@@ -443,13 +452,21 @@ static void smcd_cdc_rx_tsklet(struct tasklet_struct *t)
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
@@ -483,7 +500,11 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
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
index cf6b620fef05..d94b728c0d68 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2499,7 +2499,13 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 	}
 
 	if (is_rmb) {
-		conn->rmb_desc = buf_desc;
+		/* Publish with release semantics: the connection is already in
+		 * the link group's token tree, so a concurrent CDC receive
+		 * handler must observe a fully initialised buffer once it sees
+		 * a non-NULL rmb_desc.  Pairs with the smp_load_acquire() in
+		 * the CDC receive path.
+		 */
+		smp_store_release(&conn->rmb_desc, buf_desc);
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
@@ -2599,7 +2605,13 @@ int smcd_buf_attach(struct smc_sock *smc)
 	buf_desc->cpu_addr =
 		(u8 *)buf_desc->cpu_addr + sizeof(struct smcd_cdc_msg);
 	buf_desc->len -= sizeof(struct smcd_cdc_msg);
-	conn->sndbuf_desc = buf_desc;
+	/* Publish with release semantics: the connection is already reachable
+	 * to the ISM device (smc_ism_set_conn() ran in __smc_buf_create()), so
+	 * the CDC receive tasklet must observe a fully initialised ghost buffer
+	 * once it sees a non-NULL sndbuf_desc.  Pairs with smp_load_acquire()
+	 * in smc_cdc_msg_recv_action().
+	 */
+	smp_store_release(&conn->sndbuf_desc, buf_desc);
 	conn->sndbuf_desc->used = 1;
 	atomic_set(&conn->sndbuf_space, conn->sndbuf_desc->len);
 	return 0;

---
base-commit: 3f1f755366687d051174739fb99f7d560202f60b
change-id: 20260714-b4-disp-835288a6-1f72ff8d7a71

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

