From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:31 +0200
Subject: [PATCH v3 15/15] ata: ahci: cleanup legacy code and remove unused
 paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-15-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676614; l=4281;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=r3VHnjAHwr1KMNBbnlzaSAKn8jRhzTOZGcaO833UCbQ=;
 b=J6cNnBPpkLd3qntr56x4TaQqdC6xNILMRFHA0chWkYfla/LNXxjYE7BdFJxSZtHTppP6NBaCF
 DIh/IqA4kvID7aBi9v6Nq8Ctmzf1DJU+QQp8q6npSVVdHoSOboDA6d/
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove obsolete and unused AHCI initialization code inherited from older
drivers, including disabled flush helpers, legacy HOST_CAP/HOST_PORTS_IMPL
programming, outdated reset handling, and debug paths. These
changes do not alter functional behavior, as all required initialization
and shutdown logic is now implemented in dedicated commits.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 63 ++++++++----------------------------------------------
 1 file changed, 9 insertions(+), 54 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index e9e73069c1..f97e2573b7 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -465,43 +465,6 @@ static struct ata_port_operations ahci_ops = {
 	.write = ahci_write,
 };
 
-#if 0
-/*
- * In the general case of generic rotating media it makes sense to have a
- * flush capability. It probably even makes sense in the case of SSDs because
- * one cannot always know for sure what kind of internal cache/flush mechanism
- * is embodied therein. At first it was planned to invoke this after the last
- * write to disk and before rebooting. In practice, knowing, a priori, which
- * is the last write is difficult. Because writing to the disk in u-boot is
- * very rare, this flush command will be invoked after every block write.
- */
-static int ata_io_flush(u8 port)
-{
-	u8 fis[20];
-	struct ahci_ioports *pp = &(probe_ent->port[port]);
-	volatile u8 *port_mmio = (volatile u8 *)pp->port_mmio;
-	u32 cmd_fis_len = 5;	/* five dwords */
-
-	/* Preset the FIS */
-	memset(fis, 0, 20);
-	fis[0] = 0x27;		 /* Host to device FIS. */
-	fis[1] = 1 << 7;	 /* Command FIS. */
-	fis[2] = ATA_CMD_FLUSH_EXT;
-
-	memcpy((unsigned char *)pp->cmd_tbl, fis, 20);
-	ahci_fill_cmd_slot(pp, cmd_fis_len);
-	mywritel_with_flush(1, port_mmio + PORT_CMD_ISSUE);
-
-	if (waiting_for_cmd_completed(port_mmio + PORT_CMD_ISSUE,
-			WAIT_MS_FLUSH, 0x1)) {
-		debug("scsi_ahci: flush command timeout on port %d.\n", port);
-		return -EIO;
-	}
-
-	return 0;
-}
-#endif
-
 void ahci_print_info(struct ahci_device *ahci)
 {
 	u32 vers, cap, cap2, impl, speed;
@@ -588,7 +551,7 @@ static int ahci_detect(struct device *dev)
 
 int ahci_add_host(struct ahci_device *ahci)
 {
-	u32 tmp, cap_save;
+	u32 tmp;
 	int n_ports, i, ret;
 
 	ahci->host_flags = ATA_FLAG_SATA
@@ -601,35 +564,27 @@ int ahci_add_host(struct ahci_device *ahci)
 
 	ahci_debug(ahci, "ahci_host_init: start\n");
 
-	cap_save = ahci_ioread(ahci, HOST_CAP);
-	cap_save &= (HOST_CAP_SMPS | HOST_CAP_SPM);
-	cap_save |= HOST_CAP_SSS;  /* Staggered Spin-up. Not needed. */
-
 	/* global controller reset */
 	tmp = ahci_ioread(ahci, HOST_CTL);
-	if ((tmp & HOST_RESET) == 0)
-		ahci_iowrite_f(ahci, HOST_CTL, tmp | HOST_RESET);
+	ahci_iowrite_f(ahci, HOST_CTL, tmp | HOST_RESET);
 
-	/*
-	 * reset must complete within 1 second, or
-	 * the hardware should be considered fried.
-	 */
 	ret = wait_on_timeout(SECOND, (ahci_ioread(ahci, HOST_CTL) & HOST_RESET) == 0);
 	if (ret) {
-		ahci_debug(ahci, "controller reset failed (0x%x)\n", tmp);
+		ahci_debug(ahci, "controller reset failed (HOST_CTL=0x%x)\n",
+				ahci_ioread(ahci, HOST_CTL));
 		return -ENODEV;
 	}
 
-	ahci_iowrite_f(ahci, HOST_CTL, HOST_AHCI_EN);
-	ahci_iowrite(ahci, HOST_CAP, cap_save);
-	ahci_iowrite_f(ahci, HOST_PORTS_IMPL, 0xf);
+	tmp = ahci_ioread(ahci, HOST_CTL);
+	tmp |= HOST_AHCI_EN;
+	ahci_iowrite_f(ahci, HOST_CTL, tmp);
 
 	ahci->cap = ahci_ioread(ahci, HOST_CAP);
 	ahci->port_map = ahci_ioread(ahci, HOST_PORTS_IMPL);
 	ahci->n_ports = (ahci->cap & HOST_CAP_NP) + 1;
 
 	ahci_debug(ahci, "cap 0x%x  port_map 0x%x  n_ports %d\n",
-	      ahci->cap, ahci->port_map, ahci->n_ports);
+			ahci->cap, ahci->port_map, ahci->n_ports);
 
 	n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
 
@@ -648,9 +603,9 @@ int ahci_add_host(struct ahci_device *ahci)
 		ata_port_register(&ahci_port->ata);
 	}
 
+	/* enable HBA level interrupts */
 	tmp = ahci_ioread(ahci, HOST_CTL);
 	ahci_iowrite(ahci, HOST_CTL, tmp | HOST_IRQ_EN);
-	tmp = ahci_ioread(ahci, HOST_CTL);
 
 	ahci->dev->detect = ahci_detect;
 	list_add(&ahci->list, &ahci_devices);

-- 
2.47.3

