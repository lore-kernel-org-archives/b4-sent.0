From: Frank Li <Frank.Li@nxp.com>
Date: Tue, 10 Mar 2026 15:07:37 -0400
Subject: [PATCH 1/3] mtd: rawnand: gpmi: set chip->of_node to nand@0 child
 node if present
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-gpmi_nand-v1-1-6a665151aa75@nxp.com>
References: <20260310-gpmi_nand-v1-0-6a665151aa75@nxp.com>
In-Reply-To: <20260310-gpmi_nand-v1-0-6a665151aa75@nxp.com>
To: Han Xu <han.xu@nxp.com>, Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: imx@lists.linux.dev, linux-mtd@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Max Krummenacher <max.oss.09@gmail.com>, 
 Francesco Dolcini <francesco.dolcini@toradex.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773169659; l=1960;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=a9JwL4V+z0V/CdLgwtBGNvbdwXlOFNtmIrkNA8GkZ4Q=;
 b=1hqUkmrfgaunI5WwUJZTxhGdYB1iquyAtHc/hWcUoyZ+nhMTFPedqecwiuKNw/Vi/kyU+RAOS
 WgeCfL6SUijBZuehbGpcjgygs1j1Altum22n53OH5VMsyVIe5TsjQsn
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nand-controller.yaml binding requires a child node (e.g. nand@0) under
the NAND controller. However, the driver currently assigns the controller's
of_node directly to the NAND chip.

Search for the first child node with the "nand" prefix and assign it to
chip->of_node. This filters out properties such as "partition" that may be
placed under the controller node in some older DTS files.

Fall back to using the controller's of_node if no suitable child node is
found to maintain backward compatibility.

This issue went unnoticed because the default behavior works for most NAND
chips.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c b/drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c
index 51f595fbc834e7f711331629bb9f7a1482749b62..c1f766cb225aad3502d73ef54a9aedcd50054b93 100644
--- a/drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c
+++ b/drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2010-2015 Freescale Semiconductor, Inc.
  * Copyright (C) 2008 Embedded Alley Solutions, Inc.
  */
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/delay.h>
 #include <linux/slab.h>
@@ -2688,7 +2689,15 @@ static int gpmi_nand_init(struct gpmi_nand_data *this)
 
 	/* init the nand_chip{}, we don't support a 16-bit NAND Flash bus. */
 	nand_set_controller_data(chip, this);
-	nand_set_flash_node(chip, this->pdev->dev.of_node);
+
+	struct device_node *np __free(device_node) =
+		of_get_next_child_with_prefix(this->pdev->dev.of_node, NULL, "nand");
+
+	if (np)
+		nand_set_flash_node(chip, np);
+	else
+		nand_set_flash_node(chip, this->pdev->dev.of_node);
+
 	chip->legacy.block_markbad = gpmi_block_markbad;
 	chip->badblock_pattern	= &gpmi_bbt_descr;
 	chip->options		|= NAND_NO_SUBPAGE_WRITE;

-- 
2.43.0

