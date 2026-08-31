From: Tobias Jakobsen <tjakobsen84@protonmail.com>
Date: Mon, 31 Aug 2026 14:05:51 +0200
Subject: [PATCH v2 1/2] mtd: spi-nor: allow the platform to supply write
 protection state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-spi-nor-platform-lock-v2-1-6cc75b909241@protonmail.com>
References: <20260831-spi-nor-platform-lock-v2-0-6cc75b909241@protonmail.com>
In-Reply-To: <20260831-spi-nor-platform-lock-v2-0-6cc75b909241@protonmail.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Mark Brown <broonie@kernel.org>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-spi@vger.kernel.org, Tobias Jakobsen <tjakobsen84@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788177954; l=5359;
 i=tjakobsen84@protonmail.com; s=20260829; h=from:subject:message-id;
 bh=MSys8cnXbQBoWVAcIhue35cuWVEU+RVJ5eSR/jS9c98=;
 b=ajtrL7jE2GkvUCH6m2KQ0jishkNtM0TF0PpJb/axYVNuluOZtf1Qa9FzPiA4zAu5tUgw9Gp6c
 /lHveFpouueDqLb4AAyQZYtx4URG+RMherINPr34hszuGz3ETL+COZH
X-Developer-Key: i=tjakobsen84@protonmail.com; a=ed25519;
 pk=UREd6cisfwsFIDP455nUH6Ysx+ZDGnAVE9nGmKzm1Ks=
X-Endpoint-Received: by B4 Relay for tjakobsen84@protonmail.com/20260829 with auth_id=986
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some flashes are write protected by the platform they are attached to
rather than by their own block protection bits. An Intel PCH SPI
controller programmed with protected range registers is one example: it
refuses writes to a range regardless of what the chip's status register
says, while the chip's block protection bits are typically left clear.

MEMISLOCKED therefore either fails with -EOPNOTSUPP, or, once the chip
gains SPI_NOR_HAS_LOCK, reports a range as unlocked while writes to it
are in fact being refused.

Let the platform supply an optional is_locked() callback in struct
flash_platform_data, alongside the partitions it can already supply, and
prefer it over the chip's own block protection bits. This is independent
of SPI_NOR_HAS_LOCK, so an answer is also given for chips that have no
block protection support of their own.

lock() and unlock() return -EOPNOTSUPP, as platform enforced protection
is not expected to be changed at runtime.

Platforms that do not supply the callback are unaffected.

Link: https://bugzilla.kernel.org/show_bug.cgi?id=221927
Assisted-by: LLM
Signed-off-by: Tobias Jakobsen <tjakobsen84@protonmail.com>
---
 drivers/mtd/spi-nor/core.c | 52 ++++++++++++++++++++++++++++++++++++++++++++--
 include/linux/spi/flash.h  | 12 +++++++++++
 2 files changed, 62 insertions(+), 2 deletions(-)

diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index ccf4396cd..a5c37eea4 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -3001,6 +3001,50 @@ static void spi_nor_init_fixup_flags(struct spi_nor *nor)
 		nor->flags |= SNOR_F_IO_MODE_EN_VOLATILE;
 }
 
+static int spi_nor_platform_lock(struct spi_nor *nor, loff_t ofs, u64 len)
+{
+	return -EOPNOTSUPP;
+}
+
+static int spi_nor_platform_unlock(struct spi_nor *nor, loff_t ofs, u64 len)
+{
+	return -EOPNOTSUPP;
+}
+
+static int spi_nor_platform_is_locked(struct spi_nor *nor, loff_t ofs, u64 len)
+{
+	struct flash_platform_data *data = dev_get_platdata(nor->dev);
+
+	return data->is_locked(nor->spimem->spi, ofs, len);
+}
+
+static const struct spi_nor_locking_ops spi_nor_platform_locking_ops = {
+	.lock = spi_nor_platform_lock,
+	.unlock = spi_nor_platform_unlock,
+	.is_locked = spi_nor_platform_is_locked,
+};
+
+/**
+ * spi_nor_init_platform_locking_ops() - Use the platform supplied write
+ *	protection query, if there is one.
+ * @nor:	pointer to a 'struct spi_nor'
+ *
+ * Some flashes are write protected by the platform they are attached to rather
+ * than by their own block protection bits, for example by an Intel PCH SPI
+ * controller programmed with protected range registers. In that case the chip's
+ * block protection bits are typically left clear and say nothing about what is
+ * actually enforced, so prefer the platform supplied query when available.
+ */
+static void spi_nor_init_platform_locking_ops(struct spi_nor *nor)
+{
+	struct flash_platform_data *data = dev_get_platdata(nor->dev);
+
+	if (!data || !data->is_locked || !nor->spimem)
+		return;
+
+	nor->params->locking_ops = &spi_nor_platform_locking_ops;
+}
+
 /**
  * spi_nor_late_init_params() - Late initialization of default flash parameters.
  * @nor:	pointer to a 'struct spi_nor'
@@ -3040,9 +3084,13 @@ static int spi_nor_late_init_params(struct spi_nor *nor)
 	spi_nor_init_fixup_flags(nor);
 
 	/*
-	 * NOR protection support. When locking_ops are not provided, we pick
-	 * the default ones.
+	 * NOR protection support. Platform enforced protection is preferred
+	 * over the chip's own, as the chip is not necessarily aware of it.
+	 * When locking_ops are not provided, we pick the default ones.
 	 */
+	if (!nor->params->locking_ops)
+		spi_nor_init_platform_locking_ops(nor);
+
 	if (nor->flags & SNOR_F_HAS_LOCK && !nor->params->locking_ops)
 		spi_nor_init_default_locking_ops(nor);
 
diff --git a/include/linux/spi/flash.h b/include/linux/spi/flash.h
index 2401a0887..f415e2c0b 100644
--- a/include/linux/spi/flash.h
+++ b/include/linux/spi/flash.h
@@ -2,7 +2,10 @@
 #ifndef LINUX_SPI_FLASH_H
 #define LINUX_SPI_FLASH_H
 
+#include <linux/types.h>
+
 struct mtd_partition;
+struct spi_device;
 
 /**
  * struct flash_platform_data: board-specific flash data
@@ -11,6 +14,13 @@ struct mtd_partition;
  * @nr_parts: number of mtd_partitions for static partitioning
  * @type: optional flash device type (e.g. m25p80 vs m25p64), for use
  *	with chips that can't be queried for JEDEC or other IDs
+ * @is_locked: optional callback to query write protection enforced by the
+ *	platform rather than by the flash chip itself, for example a SPI
+ *	controller that gates writes to a range of the flash. Returns 1 if
+ *	the whole range is protected, 0 if it is not, or a negative errno.
+ *	When supplied it takes precedence over the chip's own block
+ *	protection bits, which do not necessarily reflect what is actually
+ *	being enforced.
  *
  * Board init code (in arch/.../mach-xxx/board-yyy.c files) can
  * provide information about SPI flash parts (such as DataFlash) to
@@ -26,6 +36,8 @@ struct flash_platform_data {
 
 	char		*type;
 
+	int		(*is_locked)(struct spi_device *spi, loff_t ofs, u64 len);
+
 	/* we'll likely add more ... use JEDEC IDs, etc */
 };
 

-- 
2.53.0

