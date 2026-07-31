From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Fri, 31 Jul 2026 16:57:19 +0900
Subject: [PATCH v3] mtd: spi-nor: remove unused NO_OP_CHIP_ERASE flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-no_op_chip_erase-v3-1-41f101d9968b@infineon.com>
X-B4-Tracking: v=1; b=H4sIAF9VbGoC/yXMQQ6CMBBG4auQWdukQhD1KsY0bf2BcdE2HSQkh
 LtTZPkt3ltJkBlCz2qljJmFYyhoLhX50YYBij/FVOv6prvmqkI0MRk/cjLIVqBarb272846PKh
 kKaPn5b98vU/Lz33hp+ND27YD+1Y/dHQAAAA=
X-Change-ID: 20260731-no_op_chip_erase-500cb8a7abe9
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785484650; l=3127;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=jprftuHIU60xPd5Dstni2VUPc6HizHvPQXOhr2GB5c8=;
 b=EMtwEyxS9gBoBD2Qg+w33I764ypoFIdvNiYEtgWNG8lvesztgM1LFxjZo/o2GQ5UjTMNXmEgj
 f/fTHr0j5aXDzxTJ7PqBgNLMUayHjAPKf74R93jS5EdRZCkzqJ8I+Ph
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>

NO_OP_CHIP_ERASE flag is no longer used.
Remove definition and references of the flag in core and debugfs.

Reviewed-by: Tudor Ambarus <tudor.ambarus@linaro.org>
Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Reviewed-by: Miquel Raynal <miquel.raynal@bootlin.com>
Reviewed-by: Michael Walle <mwalle@kernel.org>
---
Changes in v3:
- Rebase on top of v7.5-rc5
- Collect trailers
Changes in v2:
- Collect R-b from Tudor
- Just drop NO_OP_CHIP_ERASE and leave the rest of bit assignment as is
- Copy to <linux-kernel@vger.kernel.org>
---
 drivers/mtd/spi-nor/core.c    | 3 +--
 drivers/mtd/spi-nor/core.h    | 6 ++++--
 drivers/mtd/spi-nor/debugfs.c | 7 ++-----
 3 files changed, 7 insertions(+), 9 deletions(-)

diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index ccf4396cdcd0..4d868afca2c1 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -1852,8 +1852,7 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 		return ret;
 
 	/* chip (die) erase? */
-	if ((len == mtd->size && !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) ||
-	    multi_die_erase) {
+	if (len == mtd->size || multi_die_erase) {
 		ret = spi_nor_erase_dice(nor, addr, len, die_size);
 		if (ret)
 			goto erase_err;
diff --git a/drivers/mtd/spi-nor/core.h b/drivers/mtd/spi-nor/core.h
index ba2d1a862c9d..765a8542af54 100644
--- a/drivers/mtd/spi-nor/core.h
+++ b/drivers/mtd/spi-nor/core.h
@@ -121,10 +121,12 @@
 		   SPI_MEM_OP_NO_ADDR,					\
 		   SPI_MEM_OP_NO_DATA)
 
-/* Keep these in sync with the list in debugfs.c */
+/*
+ * This could contain holes, if adding a new flag use the first free spot.
+ * Keep the flags in sync with the list in debugfs.c
+ */
 enum spi_nor_option_flags {
 	SNOR_F_HAS_SR_TB	= BIT(0),
-	SNOR_F_NO_OP_CHIP_ERASE	= BIT(1),
 	SNOR_F_BROKEN_RESET	= BIT(2),
 	SNOR_F_4B_OPCODES	= BIT(3),
 	SNOR_F_HAS_4BAIT	= BIT(4),
diff --git a/drivers/mtd/spi-nor/debugfs.c b/drivers/mtd/spi-nor/debugfs.c
index 288e2866daed..2ba8cbca04c9 100644
--- a/drivers/mtd/spi-nor/debugfs.c
+++ b/drivers/mtd/spi-nor/debugfs.c
@@ -14,7 +14,6 @@
 #define SNOR_F_NAME(name) [ilog2(SNOR_F_##name)] = #name
 static const char *const snor_f_names[] = {
 	SNOR_F_NAME(HAS_SR_TB),
-	SNOR_F_NAME(NO_OP_CHIP_ERASE),
 	SNOR_F_NAME(BROKEN_RESET),
 	SNOR_F_NAME(4B_OPCODES),
 	SNOR_F_NAME(HAS_4BAIT),
@@ -144,10 +143,8 @@ static int spi_nor_params_show(struct seq_file *s, void *data)
 		}
 	}
 
-	if (!(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
-		string_get_size(params->size, 1, STRING_UNITS_2, buf, sizeof(buf));
-		seq_printf(s, " %02x (%s)\n", params->die_erase_opcode, buf);
-	}
+	string_get_size(params->size, 1, STRING_UNITS_2, buf, sizeof(buf));
+	seq_printf(s, " %02x (%s)\n", params->die_erase_opcode, buf);
 
 	seq_puts(s, "\nsector map\n");
 	seq_puts(s, " region (in hex)   | erase mask | overlaid\n");

---
base-commit: 598149737c4965eb8e0b160faed32827a2d9eb77
change-id: 20260731-no_op_chip_erase-500cb8a7abe9

Best regards,
--  
Takahiro Kuwano <takahiro.kuwano@infineon.com>

