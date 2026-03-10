From: Frank Li <Frank.Li@nxp.com>
Date: Tue, 10 Mar 2026 15:07:38 -0400
Subject: [PATCH 2/3] mtd: rawnand: mxc: set chip->of_node to nand@0 child
 node if present
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-gpmi_nand-v1-2-6a665151aa75@nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773169659; l=1828;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=bOj/g+UY+4s889neQOAMnpSX/wgGz20f6Io/aYMX6LU=;
 b=sh93q7HWhsnaCKLZJ2Qq9mCg1igrjdWIT0UcPJC1loYjHO6n/x55Zvvbg0+k8sraeMaRzgx+c
 K502GrP2CkaCs5pORsfOhPhKkCdy+uzAcki6HaIUqBErDcRCWwAzRZ7
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
Build test only because can't find such old boards, logic is the same as
gpmi nand flash controller.
---
 drivers/mtd/nand/raw/mxc_nand.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/mtd/nand/raw/mxc_nand.c b/drivers/mtd/nand/raw/mxc_nand.c
index 8c56b685bf91a462a707ff868c601358375aafce..4d8b92e7e67257535142b3a0deb5b179e1a17bad 100644
--- a/drivers/mtd/nand/raw/mxc_nand.c
+++ b/drivers/mtd/nand/raw/mxc_nand.c
@@ -4,6 +4,7 @@
  * Copyright 2008 Sascha Hauer, kernel@pengutronix.de
  */
 
+#include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/slab.h>
 #include <linux/init.h>
@@ -1714,7 +1715,14 @@ static int mxcnd_probe(struct platform_device *pdev)
 	this->legacy.chip_delay = 5;
 
 	nand_set_controller_data(this, host);
-	nand_set_flash_node(this, pdev->dev.of_node);
+
+	struct device_node *np __free(device_node) =
+		of_get_next_child_with_prefix(pdev->dev.of_node, NULL, "nand");
+
+	if (np)
+		nand_set_flash_node(this, np);
+	else
+		nand_set_flash_node(this, pdev->dev.of_node);
 
 	host->clk = devm_clk_get(&pdev->dev, NULL);
 	if (IS_ERR(host->clk))

-- 
2.43.0

