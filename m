From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Mon, 09 Nov 2026 18:39:42 +0900
Subject: [PATCH v4 2/5] mtd: spi-nor: import manufacturer driver concept
 from Linux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-split-sfdp-id-v3-v4-2-7270c9d82fd3@infineon.com>
References: <20261109-split-sfdp-id-v3-v4-0-7270c9d82fd3@infineon.com>
In-Reply-To: <20261109-split-sfdp-id-v3-v4-0-7270c9d82fd3@infineon.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, Vincent Jardin <vjardin@free.fr>, 
 Fabio Estevam <festevam@nabladev.com>, Eugen Hristev <ehristev@kernel.org>, 
 Bastien Curutchet <bastien.curutchet@bootlin.com>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794217192; l=5906;
 i=takahiro.kuwano@infineon.com; s=20261016-2; h=from:subject:message-id;
 bh=xQODin/mkv0+SFiLPEzeOAW8UrlFlDiJAWOD3eXHMoE=;
 b=xdf3hT0T+iA9PCIjizT0a2PGUm+dzEQyQA4hKUlNjF9/FYpQAoFCu7KuAodf5Vy3cRz8MTywc
 Q4ZlFHHB9tFBsqjAJrkndM0RY9mjwca+aid2NCapUhrOM+rpj2WTpkJ
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=pp4mpJAHIqhV2MvdSGbIzKRk3ujhk+tSlGjyTursr4E=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20261016-2 with auth_id=1202
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port spi_nor_manufacturer struct from Linux but ommit 'name' as we don't
print manufacturer name in u-boot, and add 'set_fixups' function pointer
to assign chip specific fixups in manufacturer drivers.Since the u-boot
has size constraint, we should keep having chip-specific fixups in
struct spi_nor instead of flash_info. The 'fixups' and 'set_fixups' are
excluded for tiny.

The manufacturers array and match_id helper are placed in spi-nor-ids.c
as those need to be referred from both core and tiny.

Tested-by: Bastien Curutchet <bastien.curutchet@bootlin.com> # mx25uw51245g
Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi/sf_internal.h  | 19 +++++++++++++++++++
 drivers/mtd/spi/sfdp.c         |  9 +++++++++
 drivers/mtd/spi/spi-nor-core.c |  9 +++++++++
 drivers/mtd/spi/spi-nor-ids.c  | 22 ++++++++++++++++++++++
 include/linux/mtd/spi-nor.h    |  2 ++
 5 files changed, 61 insertions(+)

diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 576617beb70..bc69af94aca 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -97,6 +97,23 @@ struct flash_info {
 #define SPI_NOR_OCTAL_DTR_READ	BIT(17)	/* Flash supports Octal DTR Read */
 };
 
+/**
+ * struct spi_nor_manufacturer - SPI NOR manufacturer object
+ * @parts: array of parts supported by this manufacturer
+ * @nparts: number of entries in the parts array
+ * @fixups: hooks called at various points in time during spi_nor_scan()
+ * @set_fixups: called to assign chip-specific fixups
+ */
+struct spi_nor_manufacturer {
+	const struct flash_info *parts;
+	unsigned int nparts;
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+	const struct spi_nor_fixups *fixups;
+	void (*set_fixups)(struct spi_nor *nor);
+#endif
+};
+
+extern const struct spi_nor_manufacturer *manufacturers[];
 extern const struct flash_info spi_nor_ids[];
 
 #define JEDEC_MFR(info)	((info)->id[0])
@@ -143,4 +160,6 @@ int macronix_quad_enable(struct spi_nor *nor);
 int spi_nor_hwcaps_read2cmd(u32 hwcaps);
 int spansion_no_read_cr_quad_enable(struct spi_nor *nor);
 
+const struct flash_info *spi_nor_match_id(struct spi_nor *nor, const u8 *id);
+
 #endif /* _SF_INTERNAL_H_ */
diff --git a/drivers/mtd/spi/sfdp.c b/drivers/mtd/spi/sfdp.c
index fd545796d50..db9dda12e27 100644
--- a/drivers/mtd/spi/sfdp.c
+++ b/drivers/mtd/spi/sfdp.c
@@ -219,6 +219,15 @@ spi_nor_post_bfpt_fixups(struct spi_nor *nor,
 			 const struct sfdp_bfpt *bfpt,
 			 struct spi_nor_flash_parameter *params)
 {
+	int ret;
+
+	if (nor->manufacturer->fixups && nor->manufacturer->fixups->post_bfpt) {
+		ret = nor->manufacturer->fixups->post_bfpt(nor, bfpt_header,
+							   bfpt, params);
+		if (ret)
+			return ret;
+	}
+
 	if (nor->fixups && nor->fixups->post_bfpt)
 		return nor->fixups->post_bfpt(nor, bfpt_header, bfpt, params);
 
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index b99a1a45d8f..205986a4464 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -2190,6 +2190,9 @@ spi_nor_set_pp_settings(struct spi_nor_pp_command *pp,
 static void spi_nor_post_sfdp_fixups(struct spi_nor *nor,
 				     struct spi_nor_flash_parameter *params)
 {
+	if (nor->manufacturer->fixups && nor->manufacturer->fixups->post_sfdp)
+		nor->manufacturer->fixups->post_sfdp(nor, params);
+
 	if (nor->fixups && nor->fixups->post_sfdp)
 		nor->fixups->post_sfdp(nor, params);
 }
@@ -2197,6 +2200,9 @@ static void spi_nor_post_sfdp_fixups(struct spi_nor *nor,
 static void spi_nor_late_init_fixups(struct spi_nor *nor,
 				     struct spi_nor_flash_parameter *params)
 {
+	if (nor->manufacturer->fixups && nor->manufacturer->fixups->late_init)
+		nor->manufacturer->fixups->late_init(nor, params);
+
 	if (nor->fixups && nor->fixups->late_init)
 		nor->fixups->late_init(nor, params);
 }
@@ -3640,6 +3646,9 @@ int spi_nor_remove(struct spi_nor *nor)
 
 void spi_nor_set_fixups(struct spi_nor *nor)
 {
+	if (nor->manufacturer->set_fixups)
+		nor->manufacturer->set_fixups(nor);
+
 #ifdef CONFIG_SPI_FLASH_SPANSION
 	if (JEDEC_MFR(nor->info) == SNOR_MFR_CYPRESS) {
 		switch (nor->info->id[1]) {
diff --git a/drivers/mtd/spi/spi-nor-ids.c b/drivers/mtd/spi/spi-nor-ids.c
index 67486d7a945..6ee141f3e11 100644
--- a/drivers/mtd/spi/spi-nor-ids.c
+++ b/drivers/mtd/spi/spi-nor-ids.c
@@ -731,3 +731,25 @@ const struct flash_info spi_nor_ids[] = {
 #endif
 	{ },
 };
+
+const struct spi_nor_manufacturer *manufacturers[] = {
+	NULL /* sentinel */
+};
+
+const struct flash_info *spi_nor_match_id(struct spi_nor *nor, const u8 *id)
+{
+	const struct flash_info *part;
+	unsigned int i, j;
+
+	for (i = 0; manufacturers[i]; i++) {
+		for (j = 0; j < manufacturers[i]->nparts; j++) {
+			part = &manufacturers[i]->parts[j];
+			if (!memcmp(part->id, id, part->id_len)) {
+				nor->manufacturer = manufacturers[i];
+				return part;
+			}
+		}
+	}
+
+	return NULL;
+}
diff --git a/include/linux/mtd/spi-nor.h b/include/linux/mtd/spi-nor.h
index b427253b910..e06ad53a64f 100644
--- a/include/linux/mtd/spi-nor.h
+++ b/include/linux/mtd/spi-nor.h
@@ -506,6 +506,7 @@ struct spi_flash {
  * @lock:		the lock for the read/write/erase/lock/unlock operations
  * @dev:		point to a spi device, or a spi nor controller device.
  * @info:		spi-nor part JDEC MFR id and other info
+ * @manufacturer:	SPI NOR manufacturer
  * @manufacturer_sfdp:	manufacturer specific SFDP table
  * @page_size:		the page size of the SPI NOR
  * @addr_width:		number of address bytes
@@ -557,6 +558,7 @@ struct spi_nor {
 	struct udevice		*dev;
 	struct spi_slave	*spi;
 	const struct flash_info	*info;
+	const struct spi_nor_manufacturer *manufacturer;
 	u8			*manufacturer_sfdp;
 	u32			page_size;
 	u8			addr_width;

-- 
2.53.0

