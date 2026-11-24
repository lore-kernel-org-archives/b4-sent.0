From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Date: Tue, 24 Nov 2026 17:15:14 +0530
Subject: [PATCH v13 12/20] dmaengine: ti: k3-udma: pin owning module while
 glue clients hold a udma_dev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-dma-upstream-v13-v13-12-bd4251fdc6d4@ti.com>
References: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
In-Reply-To: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
To: Vignesh Raghavendra <vigneshr@ti.com>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Peter Ujfalusi <peter.ujfalusi@ti.com>, 
 Nishanth Menon <nm@ti.com>, Santosh Shilimkar <ssantosh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 sebin.francis@ti.com, Sai Sree Kartheek Adivi <s-adivi@ti.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795520724; l=3775;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=O2aPL26t+gNCqmeRgaGGYW+iqPg35NIXwOL2Jd6bS/s=;
 b=BN9Bh4wpa8J6x5TiTjGYx81QWGdU93XOjA2I9YUzlvnaHw41OLEzgVAAVUhF5zxDL70dJ4PsO
 ijxngSrU0N6BqyHBCJgigZCY+KEjyMSTWld7EyeSUplcrsfXASjeoM6
X-Developer-Key: i=s-adivi@ti.com; a=ed25519;
 pk=EtOwVxmXDuYMgw3DqFtPDBpf8ZvbO89w1fJm4w5yPI8=
X-Endpoint-Received: by B4 Relay for s-adivi@ti.com/20261124 with auth_id=1627
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

k3_udma_glue clients obtain a struct udma_dev pointer via
of_xudma_dev_get() and keep using it afterwards (e.g. through function
pointers like ud->psil_pair) well beyond the call that returned it.
This bypasses the dmaengine core's own try_module_get() protection,
leaving no guard against the k3-udma driver module being unloaded
while a glue client still holds a live reference.

Set ud->ddev.owner so the module can be identified, take a reference
on it in of_xudma_dev_get() with try_module_get(), and add
xudma_dev_put() to release it. Update k3_udma_glue_release_tx_chn()
and k3_udma_glue_release_rx_chn() to call xudma_dev_put() when
releasing their channels.

Signed-off-by: Sai Sree Kartheek Adivi <s-adivi@ti.com>
---
 drivers/dma/ti/k3-udma-glue.c    |  5 +++++
 drivers/dma/ti/k3-udma-private.c | 16 ++++++++++++++++
 drivers/dma/ti/k3-udma.c         |  1 +
 drivers/dma/ti/k3-udma.h         |  1 +
 4 files changed, 23 insertions(+)

diff --git a/drivers/dma/ti/k3-udma-glue.c b/drivers/dma/ti/k3-udma-glue.c
index f10f61a40f914..34b282d9a727a 100644
--- a/drivers/dma/ti/k3-udma-glue.c
+++ b/drivers/dma/ti/k3-udma-glue.c
@@ -466,6 +466,9 @@ void k3_udma_glue_release_tx_chn(struct k3_udma_glue_tx_channel *tx_chn)
 		device_unregister(&tx_chn->common.chan_dev);
 		tx_chn->common.chan_dev.parent = NULL;
 	}
+
+	if (!IS_ERR_OR_NULL(tx_chn->common.udmax))
+		xudma_dev_put(tx_chn->common.udmax);
 }
 EXPORT_SYMBOL_GPL(k3_udma_glue_release_tx_chn);
 
@@ -1258,6 +1261,8 @@ void k3_udma_glue_release_rx_chn(struct k3_udma_glue_rx_channel *rx_chn)
 		device_unregister(&rx_chn->common.chan_dev);
 		rx_chn->common.chan_dev.parent = NULL;
 	}
+
+	xudma_dev_put(rx_chn->common.udmax);
 }
 EXPORT_SYMBOL_GPL(k3_udma_glue_release_rx_chn);
 
diff --git a/drivers/dma/ti/k3-udma-private.c b/drivers/dma/ti/k3-udma-private.c
index 44c097fff5ee6..d2501e074bcfb 100644
--- a/drivers/dma/ti/k3-udma-private.c
+++ b/drivers/dma/ti/k3-udma-private.c
@@ -54,10 +54,26 @@ struct udma_dev *of_xudma_dev_get(struct device_node *np, const char *property)
 		return ERR_PTR(-EPROBE_DEFER);
 	}
 
+	/*
+	 * Callers keep using ud (via function pointers stored in it, e.g.
+	 * ud->psil_pair) after this call returns, bypassing the dmaengine
+	 * core's own try_module_get() protection. Pin the owning driver's
+	 * module here so it can't be unloaded out from under a live glue
+	 * client; xudma_dev_put() releases it.
+	 */
+	if (!try_module_get(ud->ddev.owner))
+		return ERR_PTR(-ENODEV);
+
 	return ud;
 }
 EXPORT_SYMBOL(of_xudma_dev_get);
 
+void xudma_dev_put(struct udma_dev *ud)
+{
+	module_put(ud->ddev.owner);
+}
+EXPORT_SYMBOL(xudma_dev_put);
+
 struct device *xudma_get_device(struct udma_dev *ud)
 {
 	return ud->dev;
diff --git a/drivers/dma/ti/k3-udma.c b/drivers/dma/ti/k3-udma.c
index 8a8e2b5e0f473..1df869ecab2cb 100644
--- a/drivers/dma/ti/k3-udma.c
+++ b/drivers/dma/ti/k3-udma.c
@@ -2693,6 +2693,7 @@ static int udma_probe(struct platform_device *pdev)
 	}
 
 	ud->ddev.dev = dev;
+	ud->ddev.owner = THIS_MODULE;
 	ud->dev = dev;
 	ud->psil_base = ud->match_data->psil_base;
 
diff --git a/drivers/dma/ti/k3-udma.h b/drivers/dma/ti/k3-udma.h
index 4dd597ef435b8..65243c9ad1346 100644
--- a/drivers/dma/ti/k3-udma.h
+++ b/drivers/dma/ti/k3-udma.h
@@ -656,6 +656,7 @@ int xudma_navss_psil_unpair(struct udma_dev *ud, u32 src_thread,
 			    u32 dst_thread);
 
 struct udma_dev *of_xudma_dev_get(struct device_node *np, const char *property);
+void xudma_dev_put(struct udma_dev *ud);
 struct device *xudma_get_device(struct udma_dev *ud);
 struct k3_ringacc *xudma_get_ringacc(struct udma_dev *ud);
 u32 xudma_dev_get_psil_base(struct udma_dev *ud);

-- 
2.55.0

