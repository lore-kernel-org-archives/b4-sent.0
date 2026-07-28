From: Luca Lauro <famlauro93l@gmail.com>
Date: Tue, 28 Jul 2026 19:43:22 +0200
Subject: [PATCH v2 10/10] ata: ahci: add PCI AHCI support and
 Marvell-specific fixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-rn102-rn104-series-v2-10-ae31f55b7bc8@gmail.com>
References: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
In-Reply-To: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=24339;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=Vrvx1yi165xTKF6YmAzlAOzH22VwRZoX7CuDDUPwtLY=;
 b=cXVmn7WhwzT5izGkfWT1GrZrG3SKTPQy3GK4rtH+jHnOZfVUNRciDQYXEDQPOEUZkryUIJEst
 Tgkh0eYM9+sAZQlq1H7xplGDAfFVMaM+aEMNN5/yufjBx0WfLZcURhX
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch extends the barebox AHCI driver with full support for
PCI-based AHCI controllers, required for Marvell Armada 3700/XP/AC5
platforms used in the Netgear RN102/RN104 NAS devices.

Barebox previously supported only memory-mapped AHCI controllers.
Marvell exposes its AHCI controller through PCI BARs, requiring a
dedicated probing path and MMIO mapping via pci_iomap(). The new
ahci_pci_probe() function integrates PCI AHCI devices with the existing
ahci_add_host() infrastructure.

In addition to PCI support, several functional fixes are required for
Marvell AHCI to operate reliably:

- Correct DMA handling for zero-length buffers in ahci_io()
  (avoid invalid DMA mappings and sg entries).

- Implement a Marvell-compatible COMRESET sequence:
  DET=1 → delay → DET=0, followed by PHY-ready polling.

- Improve port disable logic by clearing START/FIS_RX/LIST_ON and
  waiting for FR/CR to drop to zero.

- Clear PORT_SCR_ERR before reinitializing the port.

- Program command list and FIS base addresses correctly, including
  HOST_CAP_64 handling.

The patch also introduces several improvements:

- Add ahci_ata_nodata(), a helper for ATA commands without data
  (e.g. FLUSH EXT, STANDBY NOW).

- Add definitions for ATA_CMD_FLUSH_EXT and ATA_CMD_STANDBYNOW1.

- Add an AHCI poweroff handler that flushes and parks all disks before
  shutdown, improving reliability on NAS devices.

These changes are required for reliable SATA enumeration and operation
on Marvell-based NAS devices. Other AHCI platforms are unaffected, as
the new logic is only exercised when PCI AHCI is present.

Whitespace-only changes should have been removed.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 656 ++++++++++++++++++++++++++++++-----------------------
 drivers/ata/ahci.h |   1 +
 2 files changed, 374 insertions(+), 283 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 819dc37b3e..6c32393959 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -19,7 +19,9 @@
 #include <disks.h>
 #include <ata_drive.h>
 #include <linux/sizes.h>
+#include <linux/pci.h>
 #include <clock.h>
+#include <poweroff.h>
 
 #include "ahci.h"
 
@@ -47,6 +49,54 @@
 #define ahci_debug(ahci, fmt, arg...) \
 	dev_dbg(ahci->dev, fmt, ##arg)
 
+#define ATA_CMD_FLUSH_EXT 0xEA
+#define ATA_CMD_STANDBYNOW1 0xE0
+
+#ifndef PCI_VENDOR_ID_MARVELL_EXT
+#define PCI_VENDOR_ID_MARVELL_EXT 0x1b4b
+#endif
+
+static LIST_HEAD(ahci_devices);
+
+static const struct pci_device_id ahci_pci_tbl[] = {
+    { PCI_DEVICE(PCI_VENDOR_ID_MARVELL_EXT, 0x9170) },
+    { 0, }
+};
+
+static int ahci_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
+{
+    struct ahci_device *ahci;
+    void __iomem *mmio;
+    int ret;
+
+    dev_info(&pdev->dev, "ahci: PCI probe %04x:%04x rev %02x\n",
+         pdev->vendor, pdev->device, pdev->revision);
+
+    ret = pci_enable_device(pdev);
+    if (ret)
+        return ret;
+
+    pci_set_master(pdev);
+
+    mmio = pci_iomap(pdev, 5);
+    if (!mmio)
+        return -ENODEV;
+
+    ahci = xzalloc(sizeof(*ahci));
+    ahci->dev = &pdev->dev;
+    ahci->mmio_base = mmio;
+    pdev->dev.priv = ahci;
+
+    ret = ahci_add_host(ahci);
+    if (ret) {
+        free(ahci);
+        pdev->dev.priv = NULL;
+        return ret;
+    }
+
+    return 0;
+}
+
 struct ahci_cmd_hdr {
 	u32	opts;
 	u32	status;
@@ -148,45 +198,63 @@ static int ahci_fill_sg(struct ahci_port *ahci_port, dma_addr_t buf_dma, int buf
 	return sg_count;
 }
 
-static int ahci_io(struct ahci_port *ahci_port, u8 *fis, int fis_len, void *rbuf,
-		const void *wbuf, int buf_len)
+static int ahci_io(struct ahci_port *ahci_port, u8 *fis, int fis_len,
+                   void *rbuf, const void *wbuf, int buf_len)
 {
-	u32 opts;
-	int sg_count;
-	int ret;
-	void *buf;
-	dma_addr_t buf_dma;
-	enum dma_data_direction dma_dir;
+    u32 opts;
+    int sg_count = 0;
+    int ret;
+    void *buf = NULL;
+    dma_addr_t buf_dma = 0;
+    enum dma_data_direction dma_dir = DMA_NONE;
 
-	if (!ahci_link_ok(ahci_port, 1))
-		return -EIO;
+    if (!ahci_link_ok(ahci_port, 1))
+        return -EIO;
 
-	if (wbuf) {
-		buf = (void *)wbuf;
-		dma_dir = DMA_TO_DEVICE;
-	} else {
-		buf = rbuf;
-		dma_dir = DMA_FROM_DEVICE;
-	}
+    if (buf_len > 0) {
+        if (wbuf) {
+            buf = (void *)wbuf;
+            dma_dir = DMA_TO_DEVICE;
+        } else {
+            buf = rbuf;
+            dma_dir = DMA_FROM_DEVICE;
+        }
 
-	buf_dma = dma_map_single(ahci_port->ahci->dev, buf, buf_len, dma_dir);
+        buf_dma = dma_map_single(ahci_port->ahci->dev, buf, buf_len, dma_dir);
+        sg_count = ahci_fill_sg(ahci_port, buf_dma, buf_len);
+    }
 
-	memcpy(ahci_port->cmd_tbl, fis, fis_len);
+    memcpy(ahci_port->cmd_tbl, fis, fis_len);
 
-	sg_count = ahci_fill_sg(ahci_port, buf_dma, buf_len);
-	opts = (fis_len >> 2) | (sg_count << 16);
-	if (wbuf)
-		opts |= CMD_LIST_OPTS_WRITE;
-	ahci_fill_cmd_slot(ahci_port, opts);
+    opts = (fis_len >> 2) | (sg_count << 16);
+    if (wbuf && buf_len > 0)
+        opts |= CMD_LIST_OPTS_WRITE;
+    ahci_fill_cmd_slot(ahci_port, opts);
 
-	ahci_port_write_f(ahci_port, PORT_CMD_ISSUE, 1);
+    ahci_port_write_f(ahci_port, PORT_CMD_ISSUE, 1);
 
-	ret = wait_on_timeout(WAIT_DATAIO,
-			(ahci_port_read(ahci_port, PORT_CMD_ISSUE) & 0x1) == 0);
+    ret = wait_on_timeout(WAIT_DATAIO,
+            (ahci_port_read(ahci_port, PORT_CMD_ISSUE) & 0x1) == 0);
 
-	dma_unmap_single(ahci_port->ahci->dev, buf_dma, buf_len, dma_dir);
+    if (buf_len > 0)
+        dma_unmap_single(ahci_port->ahci->dev, buf_dma, buf_len, dma_dir);
 
-	return ret;
+    return ret;
+}
+
+static int ahci_ata_nodata(struct ahci_port *ahci, u8 command, u8 feature)
+{
+    u8 fis[20] = {
+        0x27,        /* Host to device FIS */
+        1 << 7,      /* Command FIS */
+        command,     /* Command */
+        feature,     /* Features */
+    };
+
+    if (!ahci_link_ok(ahci, 0))
+        return -ENODEV;
+
+    return ahci_io(ahci, fis, sizeof(fis), NULL, NULL, 0);
 }
 
 /*
@@ -272,152 +340,88 @@ static int ahci_write(struct ata_port *ata, const void *buf, sector_t block,
 
 static int ahci_init_port(struct ahci_port *ahci_port)
 {
-	u32 val, cmd;
-	void *mem;
-	dma_addr_t mem_dma;
-	int ret;
-
-	/* make sure port is not active */
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
-	}
-
-	mem = dma_alloc_coherent(DMA_DEVICE_BROKEN,
-				 AHCI_PORT_PRIV_DMA_SZ, &mem_dma);
-	if (!mem) {
-		return -ENOMEM;
-	}
-
-	/*
-	 * First item in chunk of DMA memory: 32-slot command list,
-	 * 32 bytes each in size
-	 */
-	ahci_port->cmd_slot = mem;
-	ahci_port->cmd_slot_dma = mem_dma;
-
-	ahci_port_debug(ahci_port, "cmd_slot = 0x%p (0x%pad)\n",
-			ahci_port->cmd_slot, &ahci_port->cmd_slot_dma);
-
-	/*
-	 * Second item: Received-FIS area
-	 */
-	ahci_port->rx_fis = mem + AHCI_CMD_LIST_SZ;
-	ahci_port->rx_fis_dma = mem_dma + AHCI_CMD_LIST_SZ;
-
-	/*
-	 * Third item: data area for storing a single command
-	 * and its scatter-gather table
-	 */
-	ahci_port->cmd_tbl = mem + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
-	ahci_port->cmd_tbl_dma = mem_dma + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
-
-	ahci_port_debug(ahci_port, "cmd_tbl = 0x%p (0x%pad)\n",
-			ahci_port->cmd_tbl, &ahci_port->cmd_tbl_dma);
-
-	ahci_port->cmd_tbl_sg = ahci_port->cmd_tbl + AHCI_CMD_TBL_HDR_SZ;
-
-	ahci_port_write_f(ahci_port, PORT_LST_ADDR, lower_32_bits(ahci_port->cmd_slot_dma));
-	if (ahci_port->ahci->cap & HOST_CAP_64)
-		ahci_port_write_f(ahci_port, PORT_LST_ADDR_HI, upper_32_bits(ahci_port->cmd_slot_dma));
-	ahci_port_write_f(ahci_port, PORT_FIS_ADDR, lower_32_bits(ahci_port->rx_fis_dma));
-	if (ahci_port->ahci->cap & HOST_CAP_64)
-		ahci_port_write_f(ahci_port, PORT_FIS_ADDR_HI, upper_32_bits(ahci_port->rx_fis_dma));
-
-	/*
-	 * Add the spinup command to whatever mode bits may
-	 * already be on in the command register.
-	 */
-	cmd = ahci_port_read(ahci_port, PORT_CMD);
-	cmd |= PORT_CMD_FIS_RX;
-	cmd |= PORT_CMD_SPIN_UP;
-	cmd |= PORT_CMD_ICC_ACTIVE;
-	ahci_port_write_f(ahci_port, PORT_CMD, cmd);
-
-	mdelay(10);
-
-	cmd = ahci_port_read(ahci_port, PORT_CMD);
-	cmd |= PORT_CMD_START;
-	ahci_port_write_f(ahci_port, PORT_CMD, cmd);
-
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
-	ret = wait_on_timeout(WAIT_SPINUP,
-			((ahci_port_read(ahci_port, PORT_TFDATA) &
-			 (ATA_STATUS_BUSY | ATA_STATUS_DRQ)) == 0) ||
-			((ahci_port_read(ahci_port, PORT_SCR_STAT) &
-			 PORT_SCR_STAT_DET) == 1));
-	if (ret) {
-		ahci_port_info(ahci_port, "timeout.\n");
-		ret = -ENODEV;
-		goto err_init;
-	}
-
-	if ((ahci_port_read(ahci_port, PORT_SCR_STAT) & PORT_SCR_STAT_DET) == 1) {
-		ahci_port_info(ahci_port, "down.\n");
-		ret = -ENODEV;
-		goto err_init;
-	}
-
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
+    u32 cmd, val;
+    void *mem;
+    dma_addr_t mem_dma;
+    int ret;
+
+    /* 1. Disable port (clear ST, FRE) */
+    cmd = ahci_port_read(ahci_port, PORT_CMD);
+    cmd &= ~(PORT_CMD_START | PORT_CMD_FIS_RX | PORT_CMD_FIS_ON |
+             PORT_CMD_LIST_ON | PORT_CMD_SPIN_UP);
+    ahci_port_write_f(ahci_port, PORT_CMD, cmd);
+
+    /* Wait for FR=0 and CR=0 */
+    ret = wait_on_timeout(SECOND,
+        !(ahci_port_read(ahci_port, PORT_CMD) &
+          (PORT_CMD_FIS_ON | PORT_CMD_LIST_ON)));
+    if (ret)
+        dev_warn(ahci_port->ahci->dev, "timeout waiting for port disable\n");
+
+    /* 2. Clear errors */
+    val = ahci_port_read(ahci_port, PORT_SCR_ERR);
+    if (val)
+        ahci_port_write(ahci_port, PORT_SCR_ERR, val);
+
+    /* 3. COMRESET: write DET=1 then DET=0 */
+    ahci_port_write(ahci_port, PORT_SCR_CTL, 1);
+    udelay(1000);
+    ahci_port_write(ahci_port, PORT_SCR_CTL, 0);
+
+    /* 4. Wait for PHY ready */
+    ret = wait_on_timeout(SECOND,
+        (ahci_port_read(ahci_port, PORT_SCR_STAT) & PORT_SCR_STAT_DET) == 0x3);
+    if (ret) {
+        ahci_port_info(ahci_port, "PHY not ready after COMRESET\n");
+        return -ETIMEDOUT;
+    }
+
+    /* 5. Allocate DMA memory (unchanged) */
+    mem = dma_alloc_coherent(DMA_DEVICE_BROKEN,
+                 AHCI_PORT_PRIV_DMA_SZ, &mem_dma);
+    if (!mem)
+        return -ENOMEM;
+
+    ahci_port->cmd_slot = mem;
+    ahci_port->cmd_slot_dma = mem_dma;
+    ahci_port->rx_fis = mem + AHCI_CMD_LIST_SZ;
+    ahci_port->rx_fis_dma = mem_dma + AHCI_CMD_LIST_SZ;
+    ahci_port->cmd_tbl = mem + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
+    ahci_port->cmd_tbl_dma = mem_dma + AHCI_CMD_LIST_SZ + AHCI_RX_FIS_SZ;
+    ahci_port->cmd_tbl_sg = ahci_port->cmd_tbl + AHCI_CMD_TBL_HDR_SZ;
+
+    /* 6. Program command list + FIS base addresses */
+    ahci_port_write_f(ahci_port, PORT_LST_ADDR,
+        lower_32_bits(ahci_port->cmd_slot_dma));
+    if (ahci_port->ahci->cap & HOST_CAP_64)
+        ahci_port_write_f(ahci_port, PORT_LST_ADDR_HI,
+            upper_32_bits(ahci_port->cmd_slot_dma));
+
+    ahci_port_write_f(ahci_port, PORT_FIS_ADDR,
+        lower_32_bits(ahci_port->rx_fis_dma));
+    if (ahci_port->ahci->cap & HOST_CAP_64)
+        ahci_port_write_f(ahci_port, PORT_FIS_ADDR_HI,
+            upper_32_bits(ahci_port->rx_fis_dma));
+
+    /* 7. Enable FIS receive engine */
+    cmd = ahci_port_read(ahci_port, PORT_CMD);
+    cmd |= PORT_CMD_FIS_RX;
+    ahci_port_write_f(ahci_port, PORT_CMD, cmd);
+
+    /* 8. Enable port start */
+    cmd |= PORT_CMD_START;
+    ahci_port_write_f(ahci_port, PORT_CMD, cmd);
+
+    /* 9. Wait for device ready (TFDATA not BUSY) */
+    ret = wait_on_timeout(WAIT_SPINUP,
+        !(ahci_port_read(ahci_port, PORT_TFDATA) &
+          (ATA_STATUS_BUSY | ATA_STATUS_DRQ)));
+    if (ret) {
+        ahci_port_info(ahci_port, "device not ready\n");
+        return -ENODEV;
+    }
+
+    return 0;
 }
 
 static int ahci_port_start(struct ata_port *ata_port)
@@ -441,49 +445,12 @@ static int ahci_port_start(struct ata_port *ata_port)
 }
 
 static struct ata_port_operations ahci_ops = {
-	.init = ahci_port_start,
-	.read_id = ahci_read_id,
-	.read = ahci_read,
-	.write = ahci_write,
+    .init       = ahci_port_start,
+    .read_id    = ahci_read_id,
+    .read       = ahci_read,
+    .write      = ahci_write,
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
@@ -570,73 +537,71 @@ static int ahci_detect(struct device *dev)
 
 int ahci_add_host(struct ahci_device *ahci)
 {
-	u32 tmp, cap_save;
-	int n_ports, i, ret;
-
-	ahci->host_flags = ATA_FLAG_SATA
-				| ATA_FLAG_NO_LEGACY
-				| ATA_FLAG_MMIO
-				| ATA_FLAG_PIO_DMA
-				| ATA_FLAG_NO_ATAPI;
-	ahci->pio_mask = 0x1f;
-	ahci->udma_mask = 0x7f;	/* FIXME: assume to support UDMA6 */
-
-	ahci_debug(ahci, "ahci_host_init: start\n");
-
-	cap_save = ahci_ioread(ahci, HOST_CAP);
-	cap_save &= (HOST_CAP_SMPS | HOST_CAP_SPM);
-	cap_save |= HOST_CAP_SSS;  /* Staggered Spin-up. Not needed. */
-
-	/* global controller reset */
-	tmp = ahci_ioread(ahci, HOST_CTL);
-	if ((tmp & HOST_RESET) == 0)
-		ahci_iowrite_f(ahci, HOST_CTL, tmp | HOST_RESET);
-
-	/*
-	 * reset must complete within 1 second, or
-	 * the hardware should be considered fried.
-	 */
-	ret = wait_on_timeout(SECOND, (ahci_ioread(ahci, HOST_CTL) & HOST_RESET) == 0);
-	if (ret) {
-		ahci_debug(ahci, "controller reset failed (0x%x)\n", tmp);
-		return -ENODEV;
-	}
-
-	ahci_iowrite_f(ahci, HOST_CTL, HOST_AHCI_EN);
-	ahci_iowrite(ahci, HOST_CAP, cap_save);
-	ahci_iowrite_f(ahci, HOST_PORTS_IMPL, 0xf);
-
-	ahci->cap = ahci_ioread(ahci, HOST_CAP);
-	ahci->port_map = ahci_ioread(ahci, HOST_PORTS_IMPL);
-	ahci->n_ports = (ahci->cap & HOST_CAP_NP) + 1;
-
-	ahci_debug(ahci, "cap 0x%x  port_map 0x%x  n_ports %d\n",
-	      ahci->cap, ahci->port_map, ahci->n_ports);
-
-	n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
-
-	for (i = 0; i < n_ports; i++) {
-		struct ahci_port *ahci_port = &ahci->ports[i];
-
-		if (!(ahci->port_map & (1 << i)))
-			continue;
-
-		ahci_port->num = i;
-		ahci_port->ahci = ahci;
-		ahci_port->ata.dev = ahci->dev;
-		ahci_port->port_mmio = ahci_port_base(ahci->mmio_base, i);
-		ahci_port->ata.ops = &ahci_ops;
-		ahci_port->ata.ahci = true;
-		ata_port_register(&ahci_port->ata);
-	}
-
-	tmp = ahci_ioread(ahci, HOST_CTL);
-	ahci_iowrite(ahci, HOST_CTL, tmp | HOST_IRQ_EN);
-	tmp = ahci_ioread(ahci, HOST_CTL);
-
-	ahci->dev->detect = ahci_detect;
-
-	return 0;
+    u32 tmp;
+    int n_ports, i, ret;
+
+    ahci->host_flags = ATA_FLAG_SATA
+                | ATA_FLAG_NO_LEGACY
+                | ATA_FLAG_MMIO
+                | ATA_FLAG_PIO_DMA
+                | ATA_FLAG_NO_ATAPI;
+    ahci->pio_mask = 0x1f;
+    ahci->udma_mask = 0x7f; /* FIXME: assume to support UDMA6 */
+
+    ahci_debug(ahci, "ahci_host_init: start\n");
+
+    /*
+     * Global controller reset: forziamo sempre il bit HOST_RESET,
+     * come fa il kernel Linux, e aspettiamo che torni a 0.
+     */
+    tmp = ahci_ioread(ahci, HOST_CTL);
+    ahci_iowrite_f(ahci, HOST_CTL, tmp | HOST_RESET);
+
+    ret = wait_on_timeout(SECOND,
+                  (ahci_ioread(ahci, HOST_CTL) & HOST_RESET) == 0);
+    if (ret) {
+        ahci_debug(ahci, "controller reset failed (HOST_CTL=0x%x)\n",
+               ahci_ioread(ahci, HOST_CTL));
+        return -ENODEV;
+    }
+
+
+    tmp = ahci_ioread(ahci, HOST_CTL);
+    tmp |= HOST_AHCI_EN;
+    ahci_iowrite_f(ahci, HOST_CTL, tmp);
+
+    ahci->cap = ahci_ioread(ahci, HOST_CAP);
+    ahci->port_map = ahci_ioread(ahci, HOST_PORTS_IMPL);
+    ahci->n_ports = (ahci->cap & HOST_CAP_NP) + 1;
+
+    ahci_debug(ahci, "cap 0x%x  port_map 0x%x  n_ports %d\n",
+           ahci->cap, ahci->port_map, ahci->n_ports);
+
+    n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
+
+    for (i = 0; i < n_ports; i++) {
+        struct ahci_port *ahci_port = &ahci->ports[i];
+
+        if (!(ahci->port_map & (1 << i)))
+            continue;
+
+        ahci_port->num = i;
+        ahci_port->ahci = ahci;
+        ahci_port->ata.dev = ahci->dev;
+        ahci_port->port_mmio = ahci_port_base(ahci->mmio_base, i);
+        ahci_port->ata.ops = &ahci_ops;
+        ahci_port->ata.ahci = true;
+        ata_port_register(&ahci_port->ata);
+    }
+
+    /* enable HBA level interrupts */
+    tmp = ahci_ioread(ahci, HOST_CTL);
+    ahci_iowrite(ahci, HOST_CTL, tmp | HOST_IRQ_EN);
+
+    ahci->dev->detect = ahci_detect;
+	list_add(&ahci->list, &ahci_devices);
+
+    return 0;
 }
 
 static int ahci_probe(struct device *dev)
@@ -665,6 +630,124 @@ static int ahci_probe(struct device *dev)
 	return ret;
 }
 
+/* -------------------------------------------------------------------------- */
+/*                       AHCI shutdown helpers (kernel-like)                  */
+/* -------------------------------------------------------------------------- */
+
+/* Stop DMA engine (clear START, wait LIST_ON=0) */
+static int ahci_stop_engine(struct ahci_port *port)
+{
+    u32 cmd;
+
+    cmd = ahci_port_read(port, PORT_CMD);
+
+    /* Already stopped? */
+    if (!(cmd & (PORT_CMD_START | PORT_CMD_LIST_ON)))
+        return 0;
+
+    /* Clear START */
+    cmd &= ~PORT_CMD_START;
+    ahci_port_write_f(port, PORT_CMD, cmd);
+
+    /* Wait for LIST_ON to clear */
+    return wait_on_timeout(500 * MSECOND,
+        !(ahci_port_read(port, PORT_CMD) & PORT_CMD_LIST_ON));
+}
+
+/* Stop FIS receive engine (clear FIS_RX, wait FIS_ON=0) */
+static int ahci_stop_fis_rx(struct ahci_port *port)
+{
+    u32 cmd;
+
+    cmd = ahci_port_read(port, PORT_CMD);
+    cmd &= ~PORT_CMD_FIS_RX;
+    ahci_port_write_f(port, PORT_CMD, cmd);
+
+    /* Wait for FIS_ON to clear */
+    return wait_on_timeout(1000 * MSECOND,
+        !(ahci_port_read(port, PORT_CMD) & PORT_CMD_FIS_ON));
+}
+
+/* Stop all ports (libata_pci_shutdown_one equivalent) */
+static void __maybe_unused ahci_shutdown_host(struct ahci_device *ahci)
+{
+    int i, n_ports;
+
+    n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
+
+    for (i = 0; i < n_ports; i++) {
+        struct ahci_port *port = &ahci->ports[i];
+
+        if (!(ahci->port_map & (1 << i)))
+            continue;
+
+        /* Stop DMA engine */
+        ahci_stop_engine(port);
+
+        /* Stop FIS receive engine */
+        ahci_stop_fis_rx(port);
+    }
+}
+
+/* Issue FLUSH EXT + STANDBY IMMEDIATE */
+static void ahci_port_shutdown(struct ahci_port *port)
+{
+    if (!port->cmd_tbl || !port->cmd_slot)
+        return;
+
+    if (!ahci_link_ok(port, 0))
+        return;
+
+    if (ahci_ata_nodata(port, ATA_CMD_FLUSH_EXT, 0))
+        ahci_port_info(port, "FLUSH EXT failed\n");
+
+    if (ahci_ata_nodata(port, ATA_CMD_STANDBYNOW1, 0))
+        ahci_port_info(port, "STANDBY IMMEDIATE failed\n");
+}
+
+/* Full poweroff sequence */
+static void ahci_poweroff(struct poweroff_handler *handler, unsigned long flags)
+{
+    struct ahci_device *ahci;
+    int i, n_ports;
+
+    list_for_each_entry(ahci, &ahci_devices, list) {
+
+        if (!ahci->mmio_base)
+            continue;
+
+        /* 1. FLUSH + STANDBY su tutte le porte attive */
+        n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
+
+        for (i = 0; i < n_ports; i++) {
+            struct ahci_port *port = &ahci->ports[i];
+
+            if (!(ahci->port_map & (1 << i)))
+                continue;
+
+            ahci_port_shutdown(port);
+        }
+
+        /* 2. (opzionale) spegnere il controller dopo i comandi
+         *    Se vuoi tenerlo, fallo SOLO dopo i comandi:
+         *
+         * ahci_shutdown_host(ahci);
+         */
+    }
+}
+
+static struct poweroff_handler ahci_po_handler = {
+    .poweroff = ahci_poweroff,
+    .priority = 200,   /* più alto di gpio-poweroff */
+};
+
+static int ahci_register_poweroff(void)
+{
+    poweroff_handler_register(&ahci_po_handler);
+    return 0;
+}
+postcore_initcall(ahci_register_poweroff);
+
 static __maybe_unused struct of_device_id ahci_dt_ids[] = {
 	{
 		.compatible = "calxeda,hb-ahci",
@@ -674,6 +757,13 @@ static __maybe_unused struct of_device_id ahci_dt_ids[] = {
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

