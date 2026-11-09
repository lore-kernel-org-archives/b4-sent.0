From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Mon, 09 Nov 2026 18:39:45 +0900
Subject: [PATCH v4 5/5] mtd: spi-nor: remove page_size from struct
 flash_info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-split-sfdp-id-v3-v4-5-7270c9d82fd3@infineon.com>
References: <20261109-split-sfdp-id-v3-v4-0-7270c9d82fd3@infineon.com>
In-Reply-To: <20261109-split-sfdp-id-v3-v4-0-7270c9d82fd3@infineon.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, Vincent Jardin <vjardin@free.fr>, 
 Fabio Estevam <festevam@nabladev.com>, Eugen Hristev <ehristev@kernel.org>, 
 Bastien Curutchet <bastien.curutchet@bootlin.com>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794217192; l=3445;
 i=takahiro.kuwano@infineon.com; s=20261016-2; h=from:subject:message-id;
 bh=IIHKxqpy6yT05/P0HQsi21XK0QtpGpDcGMPAREI3WT8=;
 b=tnbmMqviWbpDwtz5HZVNuqOpL3MxxYUUgkf1zsQIYAYfm8lJZ1B2VenTmoax7INbgRJqF7yCU
 RIL0+nSj/H/AE2erIKzWWqJLm6DLYUx+WfYRcmBDTUoTReDOtBJ9vvr
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=pp4mpJAHIqhV2MvdSGbIzKRk3ujhk+tSlGjyTursr4E=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20261016-2 with auth_id=1202
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All devices described by the INFO() or INFO6() macros use a 256-byte
page size, so page_size is not needed as a per-device field in
struct flash_info. Replacing it with a constant reduces the size of
the device ID database.

Fujitsu FRAM is the exception: it needs a late_init fixup to set
params->page_size to the chip size.

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi/fujitsu.c      | 22 +++++++++++++++++++++-
 drivers/mtd/spi/sf_internal.h  |  5 ++---
 drivers/mtd/spi/spi-nor-core.c |  2 +-
 3 files changed, 24 insertions(+), 5 deletions(-)

diff --git a/drivers/mtd/spi/fujitsu.c b/drivers/mtd/spi/fujitsu.c
index 3d5328b1815..6758d0c9d16 100644
--- a/drivers/mtd/spi/fujitsu.c
+++ b/drivers/mtd/spi/fujitsu.c
@@ -15,13 +15,33 @@ static const struct flash_info fujitsu_nor_parts[] = {
 		.id_len = 3,
 		.sector_size = 32 * 1024,
 		.n_sectors = 1,
-		.page_size = 32 * 1024, /* Whole chip can be written at once */
 		.flags = SPI_NOR_NO_ERASE,
 		.addr_width = 2,
 	},
 };
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+static void fujitsu_late_init(struct spi_nor *nor,
+			      struct spi_nor_flash_parameter *params)
+{
+	/* Whole chip can be written at once */
+	params->page_size = params->size;
+}
+
+static struct spi_nor_fixups fujitsu_fixups = {
+	.late_init = fujitsu_late_init,
+};
+
+static void fujitsu_set_fixups(struct spi_nor *nor)
+{
+	nor->fixups = &fujitsu_fixups;
+}
+#endif /* !CONFIG_IS_ENABLED(SPI_FLASH_TINY) */
+
 const struct spi_nor_manufacturer spi_nor_fujitsu = {
 	.parts = fujitsu_nor_parts,
 	.nparts = ARRAY_SIZE(fujitsu_nor_parts),
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+	.set_fixups = fujitsu_set_fixups,
+#endif
 };
diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 2be206b2651..ef163122e61 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -18,6 +18,8 @@
 #define SPI_NOR_MAX_ID_LEN	6
 #define SPI_NOR_MAX_ADDR_WIDTH	4
 
+#define SPI_NOR_DEFAULT_PAGE_SIZE 256
+
 /**
  * struct spi_nor_fixups - SPI NOR fixup hooks
  * @post_bfpt: called after the BFPT table has been parsed
@@ -61,7 +63,6 @@ struct flash_info {
 	unsigned int	sector_size;
 	u16		n_sectors;
 
-	u16		page_size;
 	u16		addr_width;
 
 	u32		flags;
@@ -117,7 +118,6 @@ struct flash_info {
 		.id_len = (!(_jedec_id) ? 0 : (3 + ((_ext_id) ? 2 : 0))),	\
 		.sector_size = (_sector_size),				\
 		.n_sectors = (_n_sectors),				\
-		.page_size = 256,					\
 		.flags = (_flags),
 
 #define INFO6(_name, _jedec_id, _ext_id, _sector_size, _n_sectors, _flags)	\
@@ -133,7 +133,6 @@ struct flash_info {
 		.id_len = 6,						\
 		.sector_size = (_sector_size),				\
 		.n_sectors = (_n_sectors),				\
-		.page_size = 256,					\
 		.flags = (_flags),
 
 /**
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index 8943ef529a2..c6e5ba4bceb 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -2018,7 +2018,7 @@ static int spi_nor_init_params(struct spi_nor *nor,
 	/* Set SPI NOR sizes. */
 	params->writesize = 1;
 	params->size = info->sector_size * info->n_sectors;
-	params->page_size = info->page_size;
+	params->page_size = SPI_NOR_DEFAULT_PAGE_SIZE;
 
 	if (!(info->flags & SPI_NOR_NO_FR)) {
 		/* Default to Fast Read for DT and non-DT platform devices. */

-- 
2.53.0

