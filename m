From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 22:39:33 +0000
Subject: [PATCH] um: vector: Don't clean up NAPI that was never set up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-uml-vector-napi-v1-1-b3751cf4fa60@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKR6/2oC/yXMSQ5AQBBA0atIrVWiWoxXEQtDoYQm3YhE3F1j+
 Rb/X2DZCFvIvQsMH2Jl0Q7ke9AMle4ZpXUGFaiYiDLc5wkPbrbFoK5WwTSNEtWFdRYSg6tWw52
 c37Eof9u9Hl3xbuC+HxUyOGlzAAAA
X-Change-ID: 20261119-uml-vector-napi-88572f3b931e
To: anton.ivanov@cambridgegreys.com, johannes@sipsolutions.net, 
 richard@nod.at
Cc: linux-kernel@vger.kernel.org, linux-um@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795127972; l=2916;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=8Y+O44qYrjdqbAzW0Oc18LWnlpyxhaxzbOh4UGR+4is=;
 b=1olmBNnFslciyrZdOshl2nFiY/pp6dtf+L/vnQ7IJmgrX9G3QDMhk/nWYpP8SPcV5NB00G7e4
 pHFgwy9Lf83CXyZqLWZeGfgHelQ1lh4EaNaA3DsKpNeCmfstWN53hFK
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

vector_net_open() calls vector_net_close() on any failure once
vp->fds is set, and vector_net_close() then runs napi_disable() and
netif_napi_del() unconditionally. But the NAPI context is only added
and enabled after build_transport_data() and the header buffer
allocations, so a failure in any of those disables a NAPI context that
was never added. napi_disable() locks n->dev, which is still NULL:

  ip link set vec0 up   (vec0:transport=gre,...,rx_key=1, no tx_key)
  Kernel panic - not syncing: Kernel mode fault at addr 0x910
   napi_disable+0x4e/0x9e
   vector_net_close+0x2b9/0x87d
   vector_net_open+0x105d/0x106f
   __dev_open+0x244/0x334

Record in vp->napi_enabled whether vector_net_open() got as far as
enabling NAPI, and only disable and delete it in vector_net_close()
when it did. NAPI is still enabled only after the queues and buffers
that vector_poll() uses are set up.

Found with a static analysis tool and checked by hand.

Fixes: b35507a4cfb2 ("um: Migrate vector drivers to NAPI")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested with UML (seccomp=on) on top of the um fixes branch: with a GRE
vector device missing tx_key, "ip link set vec0 up" panics without the
patch and fails cleanly with -EINVAL with it, also when repeated. A raw
vector device on the host's lo still goes up and down twice as before.
---
 arch/um/drivers/vector_kern.c | 9 +++++++--
 arch/um/drivers/vector_kern.h | 1 +
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/arch/um/drivers/vector_kern.c b/arch/um/drivers/vector_kern.c
index 8008278ccee7..021f14780b45 100644
--- a/arch/um/drivers/vector_kern.c
+++ b/arch/um/drivers/vector_kern.c
@@ -1137,8 +1137,12 @@ static int vector_net_close(struct net_device *dev)
 		um_free_irq(vp->tx_irq, dev);
 		vp->tx_irq = 0;
 	}
-	napi_disable(&vp->napi);
-	netif_napi_del(&vp->napi);
+	/* vector_net_open() may fail before setting up NAPI */
+	if (vp->napi_enabled) {
+		napi_disable(&vp->napi);
+		netif_napi_del(&vp->napi);
+		vp->napi_enabled = false;
+	}
 	if (vp->fds->rx_fd > 0) {
 		if (vp->bpf)
 			uml_vector_detach_bpf(vp->fds->rx_fd, vp->bpf);
@@ -1260,6 +1264,7 @@ static int vector_net_open(struct net_device *dev)
 		netif_napi_add_weight(vp->dev, &vp->napi, vector_poll, NAPI_POLL_WEIGHT);
 
 	napi_enable(&vp->napi);
+	vp->napi_enabled = true;
 
 	/* READ IRQ */
 	err = um_request_irq(
diff --git a/arch/um/drivers/vector_kern.h b/arch/um/drivers/vector_kern.h
index 5f0ceb80779d..e1b697266fa7 100644
--- a/arch/um/drivers/vector_kern.h
+++ b/arch/um/drivers/vector_kern.h
@@ -118,6 +118,7 @@ struct vector_private {
 
 	bool rexmit_scheduled;
 	bool opened;
+	bool napi_enabled;
 	bool in_write_poll;
 	bool in_error;
 



