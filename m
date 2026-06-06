From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Jun 2026 19:02:12 -0500
Subject: [PATCH v3 09/23] dmaengine: sdxi: Start functions on probe, stop
 on remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sdxi-base-v3-9-4d38ca2bdffe@amd.com>
References: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
In-Reply-To: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780704140; l=4059;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=HJWXcsWA72TD+d9YgNYbMCtKgp6O0CoGRH3DT157Mcc=;
 b=ddgeXegAogUDZM8IolRQiz+WKYeZAUBSCUKkcdu0+1TJv9JpV+aCBwu8qucLlgssXggCygqMa
 AxX9226ioh5CZQ1dxGAaTyqo+miqWrk7KsHQYUzrrWQsMTKrKldUeUK
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Following admin context setup in the previous patch, drive each SDXI
function to active state during probe. This is done by writing
GSRV_ACTIVE to MMIO_CTL0.fn_gsr and polling MMIO_STS0.fn_gsv until the
function reaches GSV_ACTIVE or an error state. A 1-second timeout has
been sufficient in practice so far.

Introduce sdxi_unregister() to stop the function during remove and wire
it up via the pci_driver .remove callback.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 50 ++++++++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/pci.c    |  7 +++++++
 drivers/dma/sdxi/sdxi.h   |  1 +
 3 files changed, 57 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 4d595e79b8ce..e8f087f758fd 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -90,6 +90,42 @@ static void sdxi_write_fn_gsr(struct sdxi_dev *sdxi, enum sdxi_fn_gsr cmd)
 	sdxi_write64(sdxi, SDXI_MMIO_CTL0, ctl0);
 }
 
+/*
+ * Transition the function from stopped state to active.
+ * See SDXI 1.0 4.1 SDXI Function State.
+ */
+static int sdxi_dev_start(struct sdxi_dev *sdxi)
+{
+	enum sdxi_fn_gsv status = sdxi_dev_gsv(sdxi);
+	int ret;
+
+	if (status != SDXI_GSV_STOP) {
+		dev_err(sdxi->dev,
+			"can't activate busy device (unexpected gsv: %s)\n",
+			gsv_str(status));
+		return -EBUSY;
+	}
+
+	sdxi_write_fn_gsr(sdxi, SDXI_GSRV_ACTIVE);
+
+	ret = sdxi_dev_gsv_poll(sdxi, status,
+				status == SDXI_GSV_ACTIVE ||
+				status == SDXI_GSV_ERROR);
+	if (ret) {
+		dev_err(sdxi->dev, "activation timed out, current state: %s\n",
+			gsv_str(status));
+		return ret;
+	}
+
+	if (status == SDXI_GSV_ERROR) {
+		dev_err(sdxi->dev, "went to error state during activation\n");
+		return -EIO;
+	}
+
+	dev_dbg(sdxi->dev, "activated\n");
+	return 0;
+}
+
 /* Get the device to the GSV_STOP state. */
 static int sdxi_dev_stop(struct sdxi_dev *sdxi)
 {
@@ -229,7 +265,11 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	if (err)
 		return err;
 
-	return 0;
+	/*
+	 * SDXI 1.0 4.1.8.9: Set MMIO_CTL0.fn_gsr to GSRV_ACTIVE and
+	 * wait for MMIO_STS0.fn_gsv to reach GSV_ACTIVE or GSV_ERROR.
+	 */
+	return sdxi_dev_start(sdxi);
 }
 
 static int sdxi_device_init(struct sdxi_dev *sdxi)
@@ -290,6 +330,14 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
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
index 42e8af008b10..4d7d6812da6d 100644
--- a/drivers/dma/sdxi/pci.c
+++ b/drivers/dma/sdxi/pci.c
@@ -63,6 +63,12 @@ static int sdxi_pci_probe(struct pci_dev *pdev,
 	return sdxi_register(&pdev->dev, &sdxi_pci_ops);
 }
 
+static void sdxi_pci_remove(struct pci_dev *pdev)
+{
+	pci_disable_sriov(pdev);
+	sdxi_unregister(&pdev->dev);
+}
+
 static const struct pci_device_id sdxi_id_table[] = {
 	{ PCI_DEVICE_CLASS(PCI_CLASS_ACCELERATOR_SDXI, 0xffffff) },
 	{ }
@@ -73,6 +79,7 @@ static struct pci_driver sdxi_driver = {
 	.name = "sdxi",
 	.id_table = sdxi_id_table,
 	.probe = sdxi_pci_probe,
+	.remove = sdxi_pci_remove,
 	.sriov_configure = pci_sriov_configure_simple,
 };
 
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 903bf18bd3cc..a15b97135308 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -64,6 +64,7 @@ struct sdxi_dev {
 };
 
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
+void sdxi_unregister(struct device *dev);
 
 static inline u64 sdxi_read64(const struct sdxi_dev *sdxi, enum sdxi_reg reg)
 {

-- 
2.54.0

