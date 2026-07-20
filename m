From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Mon, 20 Jul 2026 17:12:40 +0200
Subject: [PATCH RFC 3/3] mtd: spi-nor: skip erase type search in uniform
 bulk erase
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-spi_nor_multisize_erase-v1-3-38d719bfe77b@nokia.com>
References: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
In-Reply-To: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784560422; l=2899;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=JccJSJOGyqps8s+o8d+1DpyuMp97oOREt9SAuUTfY14=;
 b=lbQ4Fmof4KLiT5h9lWgbbmm1rJJWMIM8tx9ke27GMzCKVFiY+AqQey+s0Lf2iCgYuCg2nhF5u
 d0ntNlWgMC2BDwYUNuZg0qrbs2FqQRLPCqJ7yQmGOWJKm3s6Dzwwt6g
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spi_nor_erase_uniform() calls spi_nor_find_best_erase_type() on every
erase step when CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is enabled.  For
large requests whose middle is aligned to the largest supported erase
size, that lookup always returns the same type.

Find the largest supported uniform erase type once at the start of the
request, then use it directly while the remaining length is still large
enough and the current address stays aligned.  Fall back to
spi_nor_find_best_erase_type() only at the head or tail of the range,
where a smaller erase type may be required.

This has no effect on erase behavior; it only avoids redundant type
selection work in the bulk-aligned case.

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
 drivers/mtd/spi-nor/core.c | 37 +++++++++++++++++++++++++++++++++----
 1 file changed, 33 insertions(+), 4 deletions(-)

diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index 4e13919d238a..31839dc2705d 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -1689,8 +1689,8 @@ static int spi_nor_erase_uniform(struct spi_nor *nor, u64 addr, u32 len)
 {
 	const struct spi_nor_erase_map *map = &nor->params->erase_map;
 	const struct spi_nor_erase_region *region = &map->uniform_region;
-	const struct spi_nor_erase_type *erase;
-	int ret;
+	const struct spi_nor_erase_type *erase, *largest = NULL;
+	int i, ret;
 	/*
 	 * When CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is disabled, erase_size is
 	 * mtd->erasesize and nor->erase_opcode was set once at init by
@@ -1698,10 +1698,39 @@ static int spi_nor_erase_uniform(struct spi_nor *nor, u64 addr, u32 len)
 	 */
 	u32 erase_size = nor->mtd.erasesize;
 
+	if (IS_ENABLED(CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE)) {
+		u8 erase_mask = map->uniform_region.erase_mask;
+
+		for (i = SNOR_ERASE_TYPE_MAX - 1; i >= 0; i--) {
+			if (!(erase_mask & BIT(i)))
+				continue;
+			if (!map->erase_type[i].size)
+				continue;
+
+			largest = &map->erase_type[i];
+			break;
+		}
+
+		if (unlikely(!largest))
+			return -EINVAL;
+	}
+
 	while (len) {
 		if (IS_ENABLED(CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE)) {
-			erase = spi_nor_find_best_erase_type(map, region, addr,
-							     len);
+			/*
+			 * For large aligned ranges, every step in the middle
+			 * picks the same largest erase type. Skip
+			 * spi_nor_find_best_erase_type() there and use
+			 * @largest directly when @addr is aligned to it and
+			 * @len is still large enough. Fall back to the full
+			 * search only at the head or tail, where a smaller
+			 * erase type may be required.
+			 */
+			if (len >= largest->size && !(addr & largest->size_mask))
+				erase = largest;
+			else
+				erase = spi_nor_find_best_erase_type(map, region,
+								     addr, len);
 			if (unlikely(!erase))
 				return -EINVAL;
 

-- 
2.43.0

