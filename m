From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:08 +0900
Subject: [PATCH 09/11] mtd: spi-nor: parallel: Cleanup stacked/parallel
 flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-9-c555bd85e6e4@infineon.com>
References: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
In-Reply-To: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
To: u-boot@lists.denx.de, Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Jagan Teki <jagan@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Tom Rini <trini@konsulko.com>, 
 Ibai Erkiaga <ibai.erkiaga-elorza@amd.com>, Vignesh R <vigneshr@ti.com>, 
 Prasad Kummari <prasad.kummari@amd.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Havish Mutya <havish.mutya@amd.com>, 
 Ashok Reddy Soma <ashok.reddy.soma@amd.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Daassi Bacem <Bacem.Daassi@infineon.com>, 
 Shinsuke Okada <Shinsuke.Okada@infineon.com>, 
 Hiroyuki Saito <Hiroyuki.Saito2@infineon.com>, 
 Takahiro Kuwano <tkuw584924@gmail.com>, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=6451;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=kUiflp4TATQL7SemRpEynrSuIkD630z9TQUru6QxKpo=;
 b=NEeaA2POTm0VFtoiwFU1dg7fNYvygHU7RAnQ/LkOQV+JC2cQ75QaZ7OzlKO5UPNy/hT/5pjqS
 IYvVmdQp11JBnhz7Ae7RQee8ivFR/sCfgxiFmyWM6yaoi8s0y/FQAtz
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove check of CONFIG_SPI_STACKED_PARALLEL, SNOR_F_HAS_PARALLEL, and
SNOR_F_HAS_STACKED as paralle module is only available when the config
is enabled and dedicated for parallel mode.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/mtd/spi/parallel.c | 106 ++++++++++-----------------------------------
 1 file changed, 24 insertions(+), 82 deletions(-)

diff --git a/drivers/mtd/spi/parallel.c b/drivers/mtd/spi/parallel.c
index d884eaefcd0..decd2821337 100644
--- a/drivers/mtd/spi/parallel.c
+++ b/drivers/mtd/spi/parallel.c
@@ -17,7 +17,7 @@
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 static int write_bar(struct spi_nor *nor, u32 offset)
 {
-	u8 cmd, bank_sel, upage_curr;
+	u8 cmd, bank_sel;
 	int ret;
 	struct mtd_info *mtd = &nor->mtd;
 
@@ -25,24 +25,14 @@ static int write_bar(struct spi_nor *nor, u32 offset)
 	if (spi_nor_wait_till_ready(nor))
 		return 1;
 
-	if (nor->flags & (SNOR_F_HAS_PARALLEL | SNOR_F_HAS_STACKED) &&
-	    mtd->size <= SZ_32M)
-		return 0;
-
-	if (mtd->size <= SZ_16M)
+	if (mtd->size <= SZ_32M)
 		return 0;
 
 	offset = offset % (u32)mtd->size;
 	bank_sel = offset >> 24;
 
-	upage_curr = nor->spi->flags & SPI_XFER_U_PAGE;
-
-	if (!(nor->flags & SNOR_F_HAS_STACKED) && bank_sel == nor->bank_curr)
+	if (bank_sel == nor->bank_curr)
 		return 0;
-	else if (upage_curr == nor->upage_prev && bank_sel == nor->bank_curr)
-		return 0;
-
-	nor->upage_prev = upage_curr;
 
 	cmd = nor->bank_write_cmd;
 	write_enable(nor);
@@ -88,18 +78,7 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 			ret = -EINTR;
 			goto erase_err;
 		}
-		offset = addr;
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_PARALLEL)
-				offset /= 2;
-
-			if (nor->flags & SNOR_F_HAS_STACKED) {
-				if (offset >= (mtd->size / 2))
-					nor->spi->flags |= SPI_XFER_U_PAGE;
-				else
-					nor->spi->flags &= ~SPI_XFER_U_PAGE;
-			}
-		}
+		offset = addr / 2;
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 		ret = write_bar(nor, offset);
 		if (ret < 0)
@@ -160,7 +139,6 @@ static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
 	loff_t offset = from;
 	u32 rem_bank_len = 0;
-	u32 stack_shift = 0;
 	size_t read_len;
 	u8 bank;
 	int ret;
@@ -168,7 +146,7 @@ static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
 
 	dev_dbg(nor->dev, "from 0x%08x, len %zd\n", (u32)from, len);
 
-	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (offset & 1)) {
+	if (offset & 1) {
 		/* We can hit this case when we use file system like ubifs */
 		from--;
 		len++;
@@ -180,35 +158,12 @@ static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
 		offset = from;
 
 		if (CONFIG_IS_ENABLED(SPI_FLASH_BAR)) {
-			bank = (u32)from / SZ_16M;
-			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-				if (nor->flags & SNOR_F_HAS_PARALLEL)
-					bank /= 2;
-			}
-			rem_bank_len = SZ_16M * (bank + 1);
-			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-				if (nor->flags & SNOR_F_HAS_PARALLEL)
-					rem_bank_len *= 2;
-			}
+			bank = (u32)from / SZ_16M / 2;
+			rem_bank_len = SZ_16M * (bank + 1) * 2;
 			rem_bank_len -= from;
 		}
 
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_STACKED) {
-				stack_shift = 1;
-				if (offset >= (mtd->size / 2)) {
-					offset = offset - (mtd->size / 2);
-					nor->spi->flags |= SPI_XFER_U_PAGE;
-				} else {
-					nor->spi->flags &= ~SPI_XFER_U_PAGE;
-				}
-			}
-		}
-
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_PARALLEL)
-				offset /= 2;
-		}
+		offset /= 2;
 
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 		ret = write_bar(nor, offset);
@@ -276,7 +231,7 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 	 * Cannot write to odd offset in parallel mode,
 	 * so write 2 bytes first
 	 */
-	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (to & 1)) {
+	if (to & 1) {
 		u8 two[2] = {0xff, buf[0]};
 		size_t local_retlen;
 
@@ -307,18 +262,7 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 
 			page_offset = do_div(aux, nor->page_size);
 		}
-		offset = to + i;
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			offset /= 2;
-
-		if (nor->flags & SNOR_F_HAS_STACKED) {
-			if (offset >= (mtd->size / 2)) {
-				offset = offset - (mtd->size / 2);
-				nor->spi->flags |= SPI_XFER_U_PAGE;
-			} else {
-				nor->spi->flags &= ~SPI_XFER_U_PAGE;
-			}
-		}
+		offset = (to + i) / 2;
 
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 		ret = write_bar(nor, offset);
@@ -407,6 +351,7 @@ int spi_nor_parallel_post_init_fixups(struct spi_nor *nor)
 #if CONFIG_IS_ENABLED(DM_SPI)
 	u64 flash_size[SNOR_FLASH_CNT_MAX] = { 0 };
 	struct udevice *dev = nor->spi->dev;
+	bool is_parallel = false;
 	u32 idx = 0, i = 0;
 	int rc;
 
@@ -420,32 +365,31 @@ int spi_nor_parallel_post_init_fixups(struct spi_nor *nor)
 		} else {
 			idx++;
 			i++;
-			if (!(nor->flags & SNOR_F_HAS_PARALLEL))
-				nor->flags |= SNOR_F_HAS_PARALLEL;
+			is_parallel = true;
 		}
 	}
 
-	if (nor->flags & (SNOR_F_HAS_STACKED | SNOR_F_HAS_PARALLEL)) {
+	if (is_parallel) {
 		mtd->size = 0;
 		for (idx = 0; idx < SNOR_FLASH_CNT_MAX; idx++)
 			mtd->size += flash_size[idx];
-	}
 
-	/*
-	 * In parallel-memories the erase operation is
-	 * performed on both the flashes simultaneously
-	 * so, double the erasesize.
-	 */
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
+		/*
+		 * In parallel-memories the erase operation is
+		 * performed on both the flashes simultaneously
+		 * so, double the erasesize.
+		 */
 		nor->mtd.erasesize <<= 1;
 		nor->page_size <<= 1;
 		nor->mtd.writebufsize <<= 1;
 	}
 #endif
+	if (!is_parallel)
+		return 0;
 
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 	/* Make sure both chips use the same BAR */
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
+	{
 		int ret;
 
 		write_enable(nor);
@@ -460,11 +404,9 @@ int spi_nor_parallel_post_init_fixups(struct spi_nor *nor)
 	}
 #endif
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
-		mtd->_erase = spi_nor_erase;
-		mtd->_read = spi_nor_read;
-		mtd->_write = spi_nor_write;
-	}
+	mtd->_erase = spi_nor_erase;
+	mtd->_read = spi_nor_read;
+	mtd->_write = spi_nor_write;
 
 	return 0;
 }

-- 
2.34.1

