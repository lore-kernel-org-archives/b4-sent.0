From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:19 -0500
Subject: [PATCH 09/23] dmaengine: sdxi: Start functions on probe, stop on
 remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-9-1d184cb5c60a@amd.com>
References: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
In-Reply-To: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, PradeepVineshReddy.Kodamati@amd.com, 
 John.Kariuki@amd.com, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=4243;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=tB3lqNofDjvSRvVs4sn03HUYBVpXqToogjCQBXepPAM=;
 b=b5aLYMANEMiSYqDAU4NLy+2HAooZQ0C2iqepz1Ikojjx9AT7Fb74R8g9wi+JuP/T0Da713jc9
 dIsCjDhA5gnCofDaMil2HHZzDQUIlR6/RknaonzuUQpSxTa4Lm6rT89
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
 drivers/dma/sdxi/device.c | 56 ++++++++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/pci.c    |  6 +++++
 drivers/dma/sdxi/sdxi.h   |  1 +
 3 files changed, 62 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 636abc410dcd..145aa098c269 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -67,6 +67,49 @@ static void sdxi_write_fn_gsr(struct sdxi_dev *sdxi, enum sdxi_fn_gsr cmd)
 	sdxi_write64(sdxi, SDXI_MMIO_CTL0, ctl0);
 }
 
+static int sdxi_dev_start(struct sdxi_dev *sdxi)
+{
+	unsigned long deadline;
+	enum sdxi_fn_gsv status;
+
+	status = sdxi_dev_gsv(sdxi);
+	if (status != SDXI_GSV_STOP) {
+		sdxi_err(sdxi,
+			 "can't activate busy device (unexpected gsv: %s)\n",
+			 gsv_str(status));
+		return -EIO;
+	}
+
+	sdxi_write_fn_gsr(sdxi, SDXI_GSRV_ACTIVE);
+
+	deadline = jiffies + msecs_to_jiffies(1000);
+	do {
+		status = sdxi_dev_gsv(sdxi);
+		sdxi_dbg(sdxi, "%s: function state: %s\n", __func__, gsv_str(status));
+
+		switch (status) {
+		case SDXI_GSV_ACTIVE:
+			sdxi_dbg(sdxi, "activated\n");
+			return 0;
+		case SDXI_GSV_ERROR:
+			sdxi_err(sdxi, "went to error state\n");
+			return -EIO;
+		case SDXI_GSV_INIT:
+		case SDXI_GSV_STOP:
+			/* transitional states, wait */
+			fsleep(1000);
+			break;
+		default:
+			sdxi_err(sdxi, "unexpected gsv %u, giving up\n", status);
+			return -EIO;
+		}
+	} while (time_before(jiffies, deadline));
+
+	sdxi_err(sdxi, "activation timed out, current status %u\n",
+		sdxi_dev_gsv(sdxi));
+	return -ETIMEDOUT;
+}
+
 /* Get the device to the GSV_STOP state. */
 static int sdxi_dev_stop(struct sdxi_dev *sdxi)
 {
@@ -197,7 +240,11 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	if (err)
 		return err;
 
-	return 0;
+	/*
+	 * SDXI 1.0 4.1.8.9: Set MMIO_CTL0.fn_gsr to GSRV_ACTIVE and
+	 * wait for MMIO_STS0.fn_gsv to reach GSV_ACTIVE or GSV_ERROR.
+	 */
+	return sdxi_dev_start(sdxi);
 }
 
 static int sdxi_create_dma_pool(struct sdxi_dev *sdxi, struct dma_pool **pool,
@@ -250,3 +297,10 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 
 	return sdxi_device_init(sdxi);
 }
+
+void sdxi_unregister(struct device *dev)
+{
+	struct sdxi_dev *sdxi = dev_get_drvdata(dev);
+
+	sdxi_dev_stop(sdxi);
+}
diff --git a/drivers/dma/sdxi/pci.c b/drivers/dma/sdxi/pci.c
index f3f8485e50e3..8e4dfde078ff 100644
--- a/drivers/dma/sdxi/pci.c
+++ b/drivers/dma/sdxi/pci.c
@@ -67,6 +67,11 @@ static int sdxi_pci_probe(struct pci_dev *pdev,
 	return sdxi_register(&pdev->dev, &sdxi_pci_ops);
 }
 
+static void sdxi_pci_remove(struct pci_dev *pdev)
+{
+	sdxi_unregister(&pdev->dev);
+}
+
 static const struct pci_device_id sdxi_id_table[] = {
 	{ PCI_DEVICE_CLASS(PCI_CLASS_ACCELERATOR_SDXI, 0xffffff) },
 	{ }
@@ -77,6 +82,7 @@ static struct pci_driver sdxi_driver = {
 	.name = "sdxi",
 	.id_table = sdxi_id_table,
 	.probe = sdxi_pci_probe,
+	.remove = sdxi_pci_remove,
 	.sriov_configure = pci_sriov_configure_simple,
 };
 
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index bbc14364a5c9..426101875334 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -75,6 +75,7 @@ static inline struct device *sdxi_to_dev(const struct sdxi_dev *sdxi)
 #define sdxi_err(s, fmt, ...) dev_err(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
 
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
+void sdxi_unregister(struct device *dev);
 
 static inline u64 sdxi_read64(const struct sdxi_dev *sdxi, enum sdxi_reg reg)
 {

-- 
2.53.0

