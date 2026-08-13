From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 13 Aug 2026 17:26:29 +0200
Subject: [PATCH v4 09/14] ata: ahci: add PCI AHCI and Marvell 9170
 controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-rn102-rn104-series-v4-9-f932ac63efa0@gmail.com>
References: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
In-Reply-To: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786634824; l=3034;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=A4ugrv46pB1faIhK+VC7D6/Kfdt2bOARz2Sq0q/XHQs=;
 b=/PJEzic3ZLU79Rd8v8o8n5m4pTmT1SMkZ4A/TXdGkFIiQXc+TwjnkIrs08Ea9OiUBssjeJD/e
 yMIMwI2l7UnCogeI1ilZwYQOrguMp4vvoiesCZN5MQdoz9loRMfWMGC
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Barebox previously supported only memory-mapped AHCI controllers.
Some devices expose their AHCI controller through PCI BARs, such as the
Marvell 9170 controller found in Netgear RN102/RN104 NAS devices,
requiring a dedicated probing path and MMIO mapping.
This patch extends the barebox AHCI driver with full support for
PCI-based AHCI controllers, adding:

- A PCI probe path that enables AHCI initialization via
pci_enable_device(), pci_iomap() and ahci_add_host().

- A small device list to keep track of PCI AHCI instances.

Changes are based on the upstream Linux driver, with some adaptations.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 49 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/ata/ahci.h |  1 +
 2 files changed, 50 insertions(+)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 819dc37b3e..fd27da40f2 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -19,6 +19,8 @@
 #include <disks.h>
 #include <ata_drive.h>
 #include <linux/sizes.h>
+#include <linux/pci.h>
+#include <linux/pci_ids.h>
 #include <clock.h>
 
 #include "ahci.h"
@@ -47,6 +49,45 @@
 #define ahci_debug(ahci, fmt, arg...) \
 	dev_dbg(ahci->dev, fmt, ##arg)
 
+static const struct pci_device_id ahci_pci_tbl[] = {
+	{ PCI_DEVICE(PCI_VENDOR_ID_MARVELL_EXT, 0x9170) },
+	{ 0, }
+};
+
+static int ahci_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
+{
+	struct ahci_device *ahci;
+	void __iomem *mmio;
+	int ret;
+
+	dev_info(&pdev->dev, "ahci: PCI probe %04x:%04x rev %02x\n",
+			pdev->vendor, pdev->device, pdev->revision);
+
+	ret = pci_enable_device(pdev);
+	if (ret)
+		return ret;
+
+	pci_set_master(pdev);
+
+	mmio = pci_iomap(pdev, 5);
+	if (!mmio)
+		return -ENODEV;
+
+	ahci = xzalloc(sizeof(*ahci));
+	ahci->dev = &pdev->dev;
+	ahci->mmio_base = mmio;
+	pdev->dev.priv = ahci;
+
+	ret = ahci_add_host(ahci);
+	if (ret) {
+		free(ahci);
+		pdev->dev.priv = NULL;
+		return ret;
+	}
+
+	return 0;
+}
+
 struct ahci_cmd_hdr {
 	u32	opts;
 	u32	status;
@@ -635,6 +676,7 @@ int ahci_add_host(struct ahci_device *ahci)
 	tmp = ahci_ioread(ahci, HOST_CTL);
 
 	ahci->dev->detect = ahci_detect;
+	list_add(&ahci->list, &ahci_devices);
 
 	return 0;
 }
@@ -674,6 +716,13 @@ static __maybe_unused struct of_device_id ahci_dt_ids[] = {
 };
 MODULE_DEVICE_TABLE(of, ahci_dt_ids);
 
+static struct pci_driver ahci_pci_driver = {
+	.name = "ahci-pci",
+	.id_table = ahci_pci_tbl,
+	.probe = ahci_pci_probe,
+};
+device_pci_driver(ahci_pci_driver);
+
 static struct driver ahci_driver = {
 	.name   = "ahci",
 	.probe  = ahci_probe,
diff --git a/drivers/ata/ahci.h b/drivers/ata/ahci.h
index 196bde73c2..d2a19f4648 100644
--- a/drivers/ata/ahci.h
+++ b/drivers/ata/ahci.h
@@ -184,6 +184,7 @@ struct ahci_port {
 };
 
 struct ahci_device {
+	struct list_head list;
 	struct device		*dev;
 	struct ahci_port	ports[AHCI_MAX_PORTS];
 	u32			n_ports;

-- 
2.47.3

