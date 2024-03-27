From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 27 Mar 2024 18:44:00 +0800
Subject: [PATCH v6 2/3] mtd: rawnand: Enable monolithic read when reading
 subpages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240327-loongson1-nand-v6-2-7f9311cef020@gmail.com>
References: <20240327-loongson1-nand-v6-0-7f9311cef020@gmail.com>
In-Reply-To: <20240327-loongson1-nand-v6-0-7f9311cef020@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711536289; l=2162;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=lS2LSZ/s5Z4DeAh+vHqnlTAlI1Wu1nzKK/BPFHeBtfc=;
 b=jswAkTrM2ib8XVP9hzAqLEdJrjizPymy8TfvB7eIXISh60W8V0vf2sTb+pWo5AXZDxYFqVxq0
 TOgwt6PbWkYD9qEkmXxlJXaJWaV/TZCv+eBZKcqpxkLIwTTX4oWrFmH
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nand_read_subpage() reads data and ECC data by two separate
operations.
This patch allows the NAND controllers who support
monolithic page read to do subpage read by a single operation,
which is more effective than nand_read_subpage().
---
Changes in v6:
- A newly added patch

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/mtd/nand/raw/nand_base.c | 5 +++--
 include/linux/mtd/rawnand.h      | 5 +++++
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/mtd/nand/raw/nand_base.c b/drivers/mtd/nand/raw/nand_base.c
index d7dbbd469b89..eeb654c6b4fc 100644
--- a/drivers/mtd/nand/raw/nand_base.c
+++ b/drivers/mtd/nand/raw/nand_base.c
@@ -3630,7 +3630,7 @@ static int nand_do_read_ops(struct nand_chip *chip, loff_t from,
 							      oob_required,
 							      page);
 			else if (!aligned && NAND_HAS_SUBPAGE_READ(chip) &&
-				 !oob)
+				 !NAND_HAS_MONOLITHIC_READ(chip) && !oob)
 				ret = chip->ecc.read_subpage(chip, col, bytes,
 							     bufpoi, page);
 			else
@@ -3648,7 +3648,8 @@ static int nand_do_read_ops(struct nand_chip *chip, loff_t from,
 			 * partial pages or when a bounce buffer is required.
 			 */
 			if (use_bounce_buf) {
-				if (!NAND_HAS_SUBPAGE_READ(chip) && !oob &&
+				if ((!NAND_HAS_SUBPAGE_READ(chip) ||
+				     NAND_HAS_MONOLITHIC_READ(chip)) && !oob &&
 				    !(mtd->ecc_stats.failed - ecc_stats.failed) &&
 				    (ops->mode != MTD_OPS_RAW)) {
 					chip->pagecache.page = realpage;
diff --git a/include/linux/mtd/rawnand.h b/include/linux/mtd/rawnand.h
index e84522e31301..92d3ab491c9c 100644
--- a/include/linux/mtd/rawnand.h
+++ b/include/linux/mtd/rawnand.h
@@ -150,6 +150,11 @@ struct gpio_desc;
 /* Device needs 3rd row address cycle */
 #define NAND_ROW_ADDR_3		BIT(14)
 
+/* Device supports monolithic reads */
+#define NAND_MONOLITHIC_READ	BIT(15)
+/* Macros to identify the above */
+#define NAND_HAS_MONOLITHIC_READ(chip) ((chip->options & NAND_MONOLITHIC_READ))
+
 /* Non chip related options */
 /* This option skips the bbt scan during initialization. */
 #define NAND_SKIP_BBTSCAN	BIT(16)

-- 
2.40.1

