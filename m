From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 13 Nov 2026 14:11:44 -0500
Subject: [PATCH net] net/smc: check every link before skipping the RMB
 registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-disp-08835f86-v1-1-b2ee1b9b94e2@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBAFf4W8s5tQSkv1V4wHShddD5V00ZgQ/
 t2qx5lkZoNyEVacmg2FX6LyyBXMocF0G/OVSVJldG3njTGWYk9JdKE2BOvm4IkHfxytS/3gImq
 2FJ7l/VuekXnF5S/1Ge88rd8Z9v0DTX9F43kAAAA=
X-Change-ID: 20261113-b4-disp-08835f86-e769a35d475b
To: Eric Dumazet <edumazet@kernel.org>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, "David S. Miller" <davem@davemloft.net>
Cc: Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, netdev@vger.kernel.org, 
 linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tony Lu <tonylu@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794597103; l=2617;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=mxIkZpcGP0ojXYjGzeyRwrFvn8NYY3W/U2JZTVq6wpo=;
 b=Wq4dO2nn7dqxjzQGkG1W+5WLAT2QT6qVHDcnLQLSZHqmURL+8bNwq6UwLvKkf/Kgoqo+FiLPD
 YVSR1SRlvJfDRkdYuHo1J9A8kCqdVX3u8DGSuRyErpBZydisJOodaRs
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smcr_lgr_reg_rmbs() skips the MR registration (its fast path) when the
RMB is registered on every active link, but the check reads is_reg_mr[]
at the index of the connection's link for each link it walks. An RMB
that sits unused in the pool when a link is added is not registered on
that link. A later connection on the older link that reuses it takes
the fast path, never registers it on the newer link, and its
CONFIRM_RKEY still gives the peer an rkey for that link. After a
failover to the newer link, the peer's RDMA writes into the RMB fail
with a remote access error, that link goes down too and, with no other
link left, the link group is terminated.

Read is_reg_mr[] at each active link's own index, so the fast path is
taken only when the RMB is registered on all of them.

Fixes: 4da687448de7 ("net/smc: reduce unnecessary blocking in smcr_lgr_reg_rmbs()")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Repro on SMC-Rv2 with soft-RoCE (rxe) over two veth pairs between two
namespaces. The link group starts with one link, and the second link
comes up only after the first connection is closed and its RMBs are
back in the pools. A second connection on the first link then takes
those RMBs, and the server's rxe device for the first link is removed.

Unpatched, the client's first RDMA write over the second link completes
with IB_WC_REM_ACCESS_ERR, the second link goes down and the link
groups on both sides are terminated; the server reads EOF. Patched, the
connection survives the failover and the data checks out in both
directions. A connection that gets a new RMB survives the failover with
and without the patch, and one placed on the second link that reuses
the RMBs takes the slow path in both builds (read from debug counters
added to smc.ko for the test). No KASAN splat in any run.
---
 net/smc/af_smc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/smc/af_smc.c b/net/smc/af_smc.c
index bfc0c7e71a12..53ee0f4afc11 100644
--- a/net/smc/af_smc.c
+++ b/net/smc/af_smc.c
@@ -581,7 +581,7 @@ static int smcr_lgr_reg_rmbs(struct smc_link *link,
 	for (i = 0; i < SMC_LINKS_PER_LGR_MAX; i++) {
 		if (!smc_link_active(&lgr->lnk[i]))
 			continue;
-		if (!rmb_desc->is_reg_mr[link->link_idx]) {
+		if (!rmb_desc->is_reg_mr[lgr->lnk[i].link_idx]) {
 			up_read(&lgr->llc_conf_mutex);
 			goto slow_path;
 		}

---
base-commit: ead6fa9a0ab194f02a2f36d634b193e9c5f9a1c6
change-id: 20261113-b4-disp-08835f86-e769a35d475b

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

