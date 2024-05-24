From: Nikita Shubin <n.shubin@yadro.com>
Date: Fri, 24 May 2024 13:24:46 +0300
Subject: [PATCH 1/3] dmaengine: ioatdma: Fix leaking on version mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240524-ioatdma-fixes-v1-1-b785f1f7accc@yadro.com>
References: <20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com>
In-Reply-To: <20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com>
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Logan Gunthorpe <logang@deltatee.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <n.shubin@yadro.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716546287; l=1829;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=ASVt6+nzAUVivKjUfhTrAzVsAPEzKEYVziXwIRDAuFU=;
 b=XdFjbO1C+F4RPvuUhl70SgRp5TAmjOw0er3PeydKwZ6a0TMrJ8hxcVT1EdTQ2Uay47pohcjT7bbf
 HH7eDqy+COYafUho+mNi7U9FxeznZlsBC8bgnV83ptzoYEG5Gpou
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix leaking ioatdma_device if I/OAT version is less than IOAT_VER_3_0.

Fixes: bf453a0a18b2 ("dmaengine: ioat: Support in-use unbind")
Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 drivers/dma/ioat/init.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/drivers/dma/ioat/init.c b/drivers/dma/ioat/init.c
index 9c364e92cb82..e76e507ae898 100644
--- a/drivers/dma/ioat/init.c
+++ b/drivers/dma/ioat/init.c
@@ -1350,6 +1350,7 @@ static int ioat_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	void __iomem * const *iomap;
 	struct device *dev = &pdev->dev;
 	struct ioatdma_device *device;
+	u8 version;
 	int err;
 
 	err = pcim_enable_device(pdev);
@@ -1363,6 +1364,10 @@ static int ioat_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	if (!iomap)
 		return -ENOMEM;
 
+	version = readb(iomap[IOAT_MMIO_BAR] + IOAT_VER_OFFSET);
+	if (version < IOAT_VER_3_0)
+		return -ENODEV;
+
 	err = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(64));
 	if (err)
 		return err;
@@ -1373,16 +1378,14 @@ static int ioat_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	pci_set_master(pdev);
 	pci_set_drvdata(pdev, device);
 
-	device->version = readb(device->reg_base + IOAT_VER_OFFSET);
+	device->version = version;
 	if (device->version >= IOAT_VER_3_4)
 		ioat_dca_enabled = 0;
-	if (device->version >= IOAT_VER_3_0) {
-		if (is_skx_ioat(pdev))
-			device->version = IOAT_VER_3_2;
-		err = ioat3_dma_probe(device, ioat_dca_enabled);
-	} else
-		return -ENODEV;
 
+	if (is_skx_ioat(pdev))
+		device->version = IOAT_VER_3_2;
+
+	err = ioat3_dma_probe(device, ioat_dca_enabled);
 	if (err) {
 		dev_err(dev, "Intel(R) I/OAT DMA Engine init failed\n");
 		return -ENODEV;

-- 
2.43.2

