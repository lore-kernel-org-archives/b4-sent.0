From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Thu, 08 May 2025 11:28:42 +0800
Subject: [PATCH] mtd: rawnand: loongson1: Fix inconsistent refcounting in
 ls1x_nand_chip_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-loongson1-nand-fix-v1-1-27b26234c62c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOkkHGgC/x2MQQqAMAzAvjJ6tjAHOvQr4mHaqgXpZAMRZH93e
 EwgeSFzEs4wmhcS35IlaoW2MbAeQXdGocrgrOtsZz2eMeqeo7aoQQk3edD5YfErUb8Fghpeiav
 +p9NcygcEQdaqZAAAAA==
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mips@vger.kernel.org, linux-mtd@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Dan Carpenter <dan.carpenter@linaro.org>, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746674928; l=2384;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=Enffpow1/oAmcpIlxb54XqOtVEib/iLdUuIMLpplTqs=;
 b=fYD8HRpmUt1FmYMRV3iW1cBEn4niKD1j8KhX3W660f8g/vV9SUM9UJ2xm+x1vbLINlw0u8KKW
 vHC+7SwNRNmAPW6deUZAEbq+C+iM1dGovTg/E7gfvQniSTIjeTEuiSr
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As reported by Dan,
commit d2d10ede04b1 ("mtd: rawnand: Add Loongson-1 NAND Controller
Driver"), leads to the following Smatch static checker warning:

drivers/mtd/nand/raw/loongson1-nand-controller.c:730 ls1x_nand_chip_init()
warn: inconsistent refcounting 'chip_np->kobj.kref.refcount.refs.counter':

Fix this issue by calling of_node_put() immediately after using chip_np.
In addition, remove all unnecessary of_node_put(chip_np) calls.

Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Closes: https://lore.kernel.org/all/aBR535RZZT-sa6QZ@stanley.mountain/
Fixes: d2d10ede04b1 ("mtd: rawnand: Add Loongson-1 NAND Controller Driver")
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/mtd/nand/raw/loongson1-nand-controller.c | 14 ++++++--------
 1 file changed, 6 insertions(+), 8 deletions(-)

diff --git a/drivers/mtd/nand/raw/loongson1-nand-controller.c b/drivers/mtd/nand/raw/loongson1-nand-controller.c
index 6a369b1c7d86..5f1bde21c8fc 100644
--- a/drivers/mtd/nand/raw/loongson1-nand-controller.c
+++ b/drivers/mtd/nand/raw/loongson1-nand-controller.c
@@ -703,27 +703,25 @@ static int ls1x_nand_chip_init(struct ls1x_nand_host *host)
 	if (!chip_np)
 		return dev_err_probe(dev, -ENODEV, "failed to get child node for NAND chip\n");
 
-	chip->controller = &host->controller;
-	chip->options = NAND_NO_SUBPAGE_WRITE | NAND_USES_DMA | NAND_BROKEN_XD;
-	chip->buf_align = 16;
-	nand_set_controller_data(chip, host);
 	nand_set_flash_node(chip, chip_np);
+	of_node_put(chip_np);
 	if (!mtd->name)
 		return dev_err_probe(dev, -EINVAL, "Missing MTD label\n");
 
+	nand_set_controller_data(chip, host);
+	chip->controller = &host->controller;
+	chip->options = NAND_NO_SUBPAGE_WRITE | NAND_USES_DMA | NAND_BROKEN_XD;
+	chip->buf_align = 16;
 	mtd->dev.parent = dev;
 	mtd->owner = THIS_MODULE;
 
 	ret = nand_scan(chip, 1);
-	if (ret) {
-		of_node_put(chip_np);
+	if (ret)
 		return dev_err_probe(dev, ret, "failed to scan NAND chip\n");
-	}
 
 	ret = mtd_device_register(mtd, NULL, 0);
 	if (ret) {
 		nand_cleanup(chip);
-		of_node_put(chip_np);
 		return dev_err_probe(dev, ret, "failed to register MTD device\n");
 	}
 

---
base-commit: 08710e696081d58163c8078e0e096be6d35c5fad
change-id: 20250507-loongson1-nand-fix-279b7cdd6fad

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

