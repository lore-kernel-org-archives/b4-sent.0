From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:52 -0600
Subject: [PATCH v4 11/25] dmaengine: sdxi: Start functions on probe, stop
 on remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-11-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=3595;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=KVXTfwQ5rgpAGS9SA9c+aurw0U8b5Pi6OYeDsytTWPE=;
 b=BJTRtTVI9p4VUklov/z71fajVlT+9uRwOW1/6H+rSoTGe/LasdfKFlwSyRTspvediHY219ZDF
 t4i2k5jHceiBUtzWmb7zl/fZRhQz7INyZmDuzK+kPM1xh7Nw8aZDSPZ
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Activate the function after administrative context setup, polling for
GSV_ACTIVE or GSV_ERROR with a one-second timeout. Stop the function during
PCI removal.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 53 ++++++++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/pci.c    |  1 +
 drivers/dma/sdxi/sdxi.h   |  1 +
 3 files changed, 54 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index f9787d7190d4..d5a5b8d43391 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -212,6 +212,36 @@ static int sdxi_dev_stop(struct sdxi_dev *sdxi)
 	return sdxi->bus_ops->reset ? sdxi->bus_ops->reset(sdxi) : -EIO;
 }
 
+/*
+ * Activate a stopped function. GSRV_ACTIVE takes it through the
+ * transient GSV_INIT state to GSV_ACTIVE or GSV_ERROR. See SDXI 1.0
+ * 4.1.8.9.
+ */
+static int sdxi_dev_start(struct sdxi_dev *sdxi)
+{
+	const unsigned long settled = BIT(SDXI_GSV_ACTIVE) | BIT(SDXI_GSV_ERROR);
+	enum sdxi_fn_gsv gsv = sdxi_dev_gsv(sdxi);
+
+	if (gsv != SDXI_GSV_STOP) {
+		dev_err(sdxi->dev,
+			"start: MMIO_STS0.fn_gsv = %#x (%s) on entry\n",
+			gsv, gsv_str(gsv));
+		return -EBUSY;
+	}
+
+	sdxi_write_fn_gsr(sdxi, SDXI_GSRV_ACTIVE);
+
+	if (sdxi_dev_gsv_poll(sdxi, gsv, BIT(gsv) & settled) ||
+	    gsv != SDXI_GSV_ACTIVE) {
+		dev_err(sdxi->dev,
+			"start: MMIO_STS0.fn_gsv = %#x (%s) after activate\n",
+			gsv, gsv_str(gsv));
+		return -EIO;
+	}
+
+	return 0;
+}
+
 /* Stop the function and discard inherited MMIO configuration. */
 static int sdxi_fn_prepare(struct sdxi_dev *sdxi)
 {
@@ -361,7 +391,20 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	if (err)
 		return err;
 
-	return 0;
+	/*
+	 * SDXI 1.0 4.1.8.9: Set MMIO_CTL0.fn_gsr to GSRV_ACTIVE and
+	 * wait for MMIO_STS0.fn_gsv to reach GSV_ACTIVE or GSV_ERROR.
+	 *
+	 * We haven't queued any descriptors to the admin context at
+	 * this point, so the admin context jump start (SDXI 1.0
+	 * 4.1.8.10.b) is accomplished later when other
+	 * code starts client contexts.
+	 */
+	err = sdxi_dev_start(sdxi);
+	if (err)
+		sdxi_dev_stop(sdxi);
+
+	return err;
 }
 
 static int sdxi_device_init(struct sdxi_dev *sdxi)
@@ -407,6 +450,14 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 }
 EXPORT_SYMBOL_NS_GPL(sdxi_register, "SDXI");
 
+void sdxi_unregister(struct device *dev)
+{
+	struct sdxi_dev *sdxi = dev_get_drvdata(dev);
+
+	sdxi_dev_stop(sdxi);
+}
+EXPORT_SYMBOL_NS_GPL(sdxi_unregister, "SDXI");
+
 MODULE_AUTHOR("Wei Huang");
 MODULE_AUTHOR("Nathan Lynch");
 MODULE_DESCRIPTION("SDXI core");
diff --git a/drivers/dma/sdxi/pci.c b/drivers/dma/sdxi/pci.c
index 6a293db69199..d196ab5cf6f1 100644
--- a/drivers/dma/sdxi/pci.c
+++ b/drivers/dma/sdxi/pci.c
@@ -99,6 +99,7 @@ static int sdxi_pci_probe(struct pci_dev *pdev,
 
 static void sdxi_pci_remove(struct pci_dev *pdev)
 {
+	sdxi_unregister(&pdev->dev);
 	pci_disable_sriov(pdev);
 }
 
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 525473029987..631a605ea62f 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -68,6 +68,7 @@ struct sdxi_dev {
 };
 
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
+void sdxi_unregister(struct device *dev);
 
 static inline u64 sdxi_read64(const struct sdxi_dev *sdxi, enum sdxi_reg reg)
 {

-- 
2.56.0

