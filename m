From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:28 +0200
Subject: [PATCH v3 12/15] ata: ahci: improve AHCI port bring-up sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-12-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=7135;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=6kzDDNMpIXgqUtyt14q3Lj35MT1iqXYy/UAoYVNMToY=;
 b=HMLAf/nfFCF9Al97lH8mp3aSFGvGIAzfaXto7pOehCbP8MGUDaub74nlZUkeVTFp5ww/PMCkE
 psys3KqOgh5Cg8oozsZCAp3aQ0WHgqQzX4SeJnvdNJVrOsC5pJOe42i
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing code only attempted a partial port disable and relied on
spin-up and link-up paths that are not reliable on some platforms like
Marvell 9170-based systems; which require a stricter and more complete
port initialization sequence than the generic AHCI specification.

This patch improves the port bring-up sequence by:
- fully disabling the port and waiting for FR/CR to clear
- clearing PORT_SCR_ERR before initialization
- issuing a COMRESET and waiting for PHY readiness
- programming both 32-bit and 64-bit base address registers
- enabling FIS receive and port start in the correct order
- waiting for device readiness via TFDATA
- removing obsolete spin-up, ICC and link-up logic

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 144 +++++++++++++++++------------------------------------
 1 file changed, 47 insertions(+), 97 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 09d37720c2..2504f4d19a 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -342,20 +342,37 @@ static int ahci_init_port(struct ahci_port *ahci_port)
 	int ret;
 
 	/* make sure port is not active */
-	val = ahci_port_read(ahci_port, PORT_CMD);
-	if (val & (PORT_CMD_LIST_ON | PORT_CMD_FIS_ON | PORT_CMD_FIS_RX | PORT_CMD_START)) {
-		ahci_port_debug(ahci_port, "Port is active. Deactivating.\n");
-		val &= ~(PORT_CMD_LIST_ON | PORT_CMD_FIS_ON |
-			 PORT_CMD_FIS_RX | PORT_CMD_START);
-		ahci_port_write(ahci_port, PORT_CMD, val);
-
-		/*
-		 * spec says 500 msecs for each bit, so
-		 * this is slightly incorrect.
-		 */
-		mdelay(500);
+	cmd = ahci_port_read(ahci_port, PORT_CMD);
+	cmd &= ~(PORT_CMD_START | PORT_CMD_FIS_RX | PORT_CMD_FIS_ON |
+			PORT_CMD_LIST_ON | PORT_CMD_SPIN_UP);
+	ahci_port_write_f(ahci_port, PORT_CMD, cmd);
+
+	/* Wait for FR=0 and CR=0 */
+	ret = wait_on_timeout(SECOND,
+		!(ahci_port_read(ahci_port, PORT_CMD) &
+			(PORT_CMD_FIS_ON | PORT_CMD_LIST_ON)));
+	if (ret)
+		dev_warn(ahci_port->ahci->dev, "timeout waiting for port disable\n");
+
+	/* Clear errors */
+	val = ahci_port_read(ahci_port, PORT_SCR_ERR);
+	if (val)
+		ahci_port_write(ahci_port, PORT_SCR_ERR, val);
+
+	/* COMRESET: write DET=1 then DET=0 */
+	ahci_port_write(ahci_port, PORT_SCR_CTL, 1);
+	udelay(1000);
+	ahci_port_write(ahci_port, PORT_SCR_CTL, 0);
+
+	/* Wait for PHY ready */
+	ret = wait_on_timeout(SECOND,
+		(ahci_port_read(ahci_port, PORT_SCR_STAT) & PORT_SCR_STAT_DET) == 0x3);
+	if (ret) {
+		ahci_port_info(ahci_port, "PHY not ready after COMRESET\n");
+		return -ETIMEDOUT;
 	}
 
+	/* Allocate DMA memory */
 	mem = dma_alloc_coherent(DMA_DEVICE_BROKEN,
 				 AHCI_PORT_PRIV_DMA_SZ, &mem_dma);
 	if (!mem) {
@@ -369,9 +386,6 @@ static int ahci_init_port(struct ahci_port *ahci_port)
 	ahci_port->cmd_slot = mem;
 	ahci_port->cmd_slot_dma = mem_dma;
 
-	ahci_port_debug(ahci_port, "cmd_slot = 0x%p (0x%pad)\n",
-			ahci_port->cmd_slot, &ahci_port->cmd_slot_dma);
-
 	/*
 	 * Second item: Received-FIS area
 	 */
@@ -384,104 +398,40 @@ static int ahci_init_port(struct ahci_port *ahci_port)
 	 */
 	ahci_port->cmd_tbl = mem + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
 	ahci_port->cmd_tbl_dma = mem_dma + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
-
-	ahci_port_debug(ahci_port, "cmd_tbl = 0x%p (0x%pad)\n",
-			ahci_port->cmd_tbl, &ahci_port->cmd_tbl_dma);
-
 	ahci_port->cmd_tbl_sg = ahci_port->cmd_tbl + AHCI_CMD_TBL_HDR_SZ;
 
-	ahci_port_write_f(ahci_port, PORT_LST_ADDR, lower_32_bits(ahci_port->cmd_slot_dma));
+	/* Program command list + FIS base addresses */
+	ahci_port_write_f(ahci_port, PORT_LST_ADDR,
+		lower_32_bits(ahci_port->cmd_slot_dma));
 	if (ahci_port->ahci->cap & HOST_CAP_64)
-		ahci_port_write_f(ahci_port, PORT_LST_ADDR_HI, upper_32_bits(ahci_port->cmd_slot_dma));
-	ahci_port_write_f(ahci_port, PORT_FIS_ADDR, lower_32_bits(ahci_port->rx_fis_dma));
+		ahci_port_write_f(ahci_port, PORT_LST_ADDR_HI,
+			upper_32_bits(ahci_port->cmd_slot_dma));
+
+	ahci_port_write_f(ahci_port, PORT_FIS_ADDR,
+		lower_32_bits(ahci_port->rx_fis_dma));
 	if (ahci_port->ahci->cap & HOST_CAP_64)
-		ahci_port_write_f(ahci_port, PORT_FIS_ADDR_HI, upper_32_bits(ahci_port->rx_fis_dma));
+		ahci_port_write_f(ahci_port, PORT_FIS_ADDR_HI,
+			upper_32_bits(ahci_port->rx_fis_dma));
 
-	/*
-	 * Add the spinup command to whatever mode bits may
-	 * already be on in the command register.
-	 */
+	/* Enable FIS receive engine */
 	cmd = ahci_port_read(ahci_port, PORT_CMD);
 	cmd |= PORT_CMD_FIS_RX;
-	cmd |= PORT_CMD_SPIN_UP;
-	cmd |= PORT_CMD_ICC_ACTIVE;
 	ahci_port_write_f(ahci_port, PORT_CMD, cmd);
 
-	mdelay(10);
-
-	cmd = ahci_port_read(ahci_port, PORT_CMD);
+	/* Enable port start */
 	cmd |= PORT_CMD_START;
 	ahci_port_write_f(ahci_port, PORT_CMD, cmd);
 
-	/*
-	 * Bring up SATA link.
-	 * SATA link bringup time is usually less than 1 ms; only very
-	 * rarely has it taken between 1-2 ms. Never seen it above 2 ms.
-	 */
-	ret = wait_on_timeout(WAIT_LINKUP,
-			(ahci_port_read(ahci_port, PORT_SCR_STAT) & PORT_SCR_STAT_DET) == 0x3);
-	if (ret) {
-		ahci_port_info(ahci_port, "SATA link timeout\n");
-		ret = -ETIMEDOUT;
-		goto err_init;
-	}
-
-	ahci_port_info(ahci_port, "SATA link ok\n");
-
-	/* Clear error status */
-	val = ahci_port_read(ahci_port, PORT_SCR_ERR);
-	if (val)
-		ahci_port_write(ahci_port, PORT_SCR_ERR, val);
-
-	ahci_port_info(ahci_port, "Spinning up device...\n");
-
+	/* Wait for device ready (TFDATA not BUSY) */
 	ret = wait_on_timeout(WAIT_SPINUP,
-			((ahci_port_read(ahci_port, PORT_TFDATA) &
-			 (ATA_STATUS_BUSY | ATA_STATUS_DRQ)) == 0) ||
-			((ahci_port_read(ahci_port, PORT_SCR_STAT) &
-			 PORT_SCR_STAT_DET) == 1));
+			!(ahci_port_read(ahci_port, PORT_TFDATA) &
+			(ATA_STATUS_BUSY | ATA_STATUS_DRQ)));
 	if (ret) {
-		ahci_port_info(ahci_port, "timeout.\n");
-		ret = -ENODEV;
-		goto err_init;
-	}
-
-	if ((ahci_port_read(ahci_port, PORT_SCR_STAT) & PORT_SCR_STAT_DET) == 1) {
-		ahci_port_info(ahci_port, "down.\n");
-		ret = -ENODEV;
-		goto err_init;
+		ahci_port_info(ahci_port, "device not ready\n");
+		return -ENODEV;
 	}
 
-	ahci_port_info(ahci_port, "ok.\n");
-
-	val = ahci_port_read(ahci_port, PORT_SCR_ERR);
-
-	ahci_port_write(ahci_port, PORT_SCR_ERR, val);
-
-	/* ack any pending irq events for this port */
-	val = ahci_port_read(ahci_port, PORT_IRQ_STAT);
-	if (val)
-		ahci_port_write(ahci_port, PORT_IRQ_STAT, val);
-
-	ahci_iowrite(ahci_port->ahci, HOST_IRQ_STAT, 1 << ahci_port->num);
-
-	/* set irq mask (enables interrupts) */
-	ahci_port_write(ahci_port, PORT_IRQ_MASK, DEF_PORT_IRQ);
-
-	/* register linkup ports */
-	val = ahci_port_read(ahci_port, PORT_SCR_STAT);
-
-	ahci_port_debug(ahci_port, "status: 0x%08x\n", val);
-
-	if ((val & PORT_SCR_STAT_DET) == 0x3)
-		return 0;
-
-	ret = -ENODEV;
-
-err_init:
-	dma_free_coherent(DMA_DEVICE_BROKEN,
-			  mem, mem_dma, AHCI_PORT_PRIV_DMA_SZ);
-	return ret;
+	return 0;
 }
 
 static int ahci_port_start(struct ata_port *ata_port)

-- 
2.47.3

