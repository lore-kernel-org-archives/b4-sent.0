From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:25 +0200
Subject: [PATCH v3 09/15] ata: ahci: add PCI AHCI and Marvell 9170
 controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-9-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=3138;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=yte79XZArVVOMu3MuERqR75S8BT0xmmnVsSEQoqX19Q=;
 b=tC/SsauP3auSky6d9vDWLXleFtlgq1xGFRaQ0cbMqLYLYaCN05c7FJRM150mG1SX/zYOGU8U3
 WKqsVObUovqCMWT+maI/eTMtt34TBn6xbJaj+/7zjTrEvWdbavxcjvI
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
 drivers/ata/ahci.c | 54 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/ata/ahci.h |  1 +
 2 files changed, 55 insertions(+)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 819dc37b3e..0ac1a9dead 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -19,6 +19,7 @@
 #include <disks.h>
 #include <ata_drive.h>
 #include <linux/sizes.h>
+#include <linux/pci.h>
 #include <clock.h>
 
 #include "ahci.h"
@@ -47,6 +48,51 @@
 #define ahci_debug(ahci, fmt, arg...) \
 	dev_dbg(ahci->dev, fmt, ##arg)
 
+#ifndef PCI_VENDOR_ID_MARVELL_EXT
+#define PCI_VENDOR_ID_MARVELL_EXT 0x1b4b
+#endif
+
+static LIST_HEAD(ahci_devices);
+
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
@@ -635,6 +681,7 @@ int ahci_add_host(struct ahci_device *ahci)
 	tmp = ahci_ioread(ahci, HOST_CTL);
 
 	ahci->dev->detect = ahci_detect;
+	list_add(&ahci->list, &ahci_devices);
 
 	return 0;
 }
@@ -674,6 +721,13 @@ static __maybe_unused struct of_device_id ahci_dt_ids[] = {
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

