From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 28 Nov 2026 10:05:08 -0500
Subject: [PATCH net v3 2/2] net/smc: do not reuse the DMB of a nocopy
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-disp-2c190c90-v3-2-c566f64196c8@proton.me>
References: <20261128-b4-disp-2c190c90-v3-0-c566f64196c8@proton.me>
In-Reply-To: <20261128-b4-disp-2c190c90-v3-0-c566f64196c8@proton.me>
To: Jakub Kicinski <kuba@kernel.org>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 Julian Ruess <julianr@linux.ibm.com>, netdev@vger.kernel.org, 
 linux-s390@vger.kernel.org, Wenjia Zhang <wenjia@linux.ibm.com>, 
 linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795878306; l=3021;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=TQSTuOnnPNT+E4GTIznojse1fg380ZEcVoDzWihFkbw=;
 b=lCXdXIdO2Bj2tC+ZzEAphy00w3wSe1I+HRG9QhlE99hsuc5QlOahk1x6xrcogaMxzfW9v8pIV
 3VfpXs+4q+SALpbBey6NjmF0OuyQAn/fse3E/UNKWsuMv5YeYzAd/hh
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With DMB nocopy (the dibs loopback device) the peer writes into the RMB
through its own attachment, and it can attach late. smc_buf_unuse() puts
the DMB back in the link group's pool with its token still registered
while the old peer can still write to it: the next connection that takes
it gets the old peer's CDCs, and a peer that attaches after the other
end gave up lands in another connection's DMB.

Unregister a nocopy DMB when the connection ends instead of pooling it:
the next connection gets a new DMB and token, a peer still attached
keeps the old one until it detaches, and a later attach fails. When the
link group is off its list smc_conn_free() skips smc_buf_unuse() and the
link group's free unregisters the DMB: clear conn->rmb_desc there, or a
retried connect() that cannot allocate its RMB unlinks and frees the
stale descriptor. Devices without nocopy keep their pool.

Fixes: ae2be35cbed2 ("net/smc: {at|de}tach sndbuf to peer DMB if supported")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_core.c | 27 +++++++++++++++++++++++++--
 1 file changed, 25 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index a3164201c142..509fc4c17bb8 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1243,6 +1243,22 @@ static void smcd_buf_detach(struct smc_connection *conn)
 	kfree(buf_desc);
 }
 
+/* With DMB nocopy the peer writes into the RMB through its own
+ * attachment, which can outlive this connection: unregister the DMB
+ * instead of pooling it, so the next connection gets a new one.
+ */
+static void smcd_rmb_drop(struct smc_connection *conn,
+			  struct smc_link_group *lgr)
+{
+	struct smc_buf_desc *rmb_desc = conn->rmb_desc;
+
+	down_write(&lgr->rmbs_lock);
+	smc_lgr_buf_list_del(lgr, true, rmb_desc);
+	up_write(&lgr->rmbs_lock);
+	WRITE_ONCE(conn->rmb_desc, NULL);
+	smc_buf_free(lgr, true, rmb_desc);
+}
+
 static void smc_buf_unuse(struct smc_connection *conn,
 			  struct smc_link_group *lgr)
 {
@@ -1266,8 +1282,13 @@ static void smc_buf_unuse(struct smc_connection *conn,
 			smcr_buf_unuse(conn->rmb_desc, true, lgr);
 		} else {
 			bufsize += sizeof(struct smcd_cdc_msg);
-			memzero_explicit(conn->rmb_desc->cpu_addr, bufsize);
-			WRITE_ONCE(conn->rmb_desc->used, 0);
+			if (smc_ism_support_dmb_nocopy(lgr->smcd)) {
+				smcd_rmb_drop(conn, lgr);
+			} else {
+				memzero_explicit(conn->rmb_desc->cpu_addr,
+						 bufsize);
+				WRITE_ONCE(conn->rmb_desc->used, 0);
+			}
 		}
 		SMC_STAT_RMB_SIZE(smc, is_smcd, true, false, bufsize);
 	}
@@ -1306,6 +1327,8 @@ void smc_conn_free(struct smc_connection *conn)
 	 */
 	if (!list_empty(&lgr->list))
 		smc_buf_unuse(conn, lgr); /* allow buffer reuse */
+	else if (lgr->is_smcd && smc_ism_support_dmb_nocopy(lgr->smcd))
+		WRITE_ONCE(conn->rmb_desc, NULL); /* freed with the lgr */
 	smc_lgr_unregister_conn(conn);
 
 	if (!lgr->conns_num)

-- 
2.56.1

