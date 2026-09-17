From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Thu, 17 Sep 2026 14:02:15 +0900
Subject: [PATCH] mtd: spi-nor: sfdp: Increase SFDP data size limit to 16
 KiB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-sfdp_size-v1-1-c1cdb1003f48@infineon.com>
X-B4-Tracking: v=1; b=H4sIAFZ0q2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0Nz3eK0lIL44syqVN00yxRTg+QUA1NjyxQloPqCotS0zAqwWdGxEH5
 xaVJWanIJyACl2loAVFtAnm0AAAA=
X-Change-ID: 20260917-sfdp_size-f9d50cd0539d
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789621347; l=1832;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=jgdfCpo97xb3riAigqfD6paumJXjsCSiN5EBCeoaUd8=;
 b=EYyWvTs7HkUROsN5diVtZwPfmb2LAcsPLbkL0iMzPO9AymQzBW+5TD0aj2cK07tiktx2QJBK/
 f/1qsUw8CyaDgSVnWlSUe+PDsMRdrkst37+t75YXntzbuawrrFDhLtn
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The size of SFDP data read and cached is limited to avoid allocating
too much memory. The current limit is PAGE_SIZE, but the Spansion S25FS256S
has parameter tables at offsets beyond 4 KiB.

Increase the limit to 16 KiB to support such devices by introducing the
SFDP_MAX_SIZE macro.

Suggested-by: Miquel Raynal <miquel.raynal@bootlin.com>
Suggested-by: Michael Walle <mwalle@kernel.org>
Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi-nor/sfdp.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/mtd/spi-nor/sfdp.c b/drivers/mtd/spi-nor/sfdp.c
index 641f17ad51a0..5d5bb6e587bf 100644
--- a/drivers/mtd/spi-nor/sfdp.c
+++ b/drivers/mtd/spi-nor/sfdp.c
@@ -115,6 +115,12 @@ struct sfdp_bfpt_erase {
 
 #define SFDP_4BAIT_DWORD_MAX	2
 
+/*
+ * Limit the total size of SFDP to a reasonable value to avoid allocating too
+ * much memory just of because the flash returned some insane values.
+ */
+#define SFDP_MAX_SIZE	SZ_16K
+
 struct sfdp_4bait {
 	/* The hardware capability. */
 	u32		hwcaps;
@@ -1594,14 +1600,10 @@ int spi_nor_parse_sfdp(struct spi_nor *nor)
 				  SFDP_PARAM_HEADER_PARAM_LEN(param_header));
 	}
 
-	/*
-	 * Limit the total size to a reasonable value to avoid allocating too
-	 * much memory just of because the flash returned some insane values.
-	 */
-	if (sfdp_size > PAGE_SIZE) {
+	if (sfdp_size > SFDP_MAX_SIZE) {
 		dev_dbg(dev, "SFDP data (%zu) too big, truncating\n",
 			sfdp_size);
-		sfdp_size = PAGE_SIZE;
+		sfdp_size = SFDP_MAX_SIZE;
 	}
 
 	sfdp = devm_kzalloc(dev, sizeof(*sfdp), GFP_KERNEL);

---
base-commit: a96edc3f0b4f036a5b6ebc9b1eca4273ef5ce2d0
change-id: 20260917-sfdp_size-f9d50cd0539d

Best regards,
--  
Takahiro Kuwano <takahiro.kuwano@infineon.com>

