From: Andrea Scian <andrea.scian@dave.eu>
Date: Wed, 04 Feb 2026 18:41:44 +0100
Subject: [PATCH v3 1/2] mtd: rawnand: pl353: Fix software ECC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-pl353-soft-ecc-support-v3-1-fd8ee7595cc1@dave.eu>
References: <20260204-pl353-soft-ecc-support-v3-0-fd8ee7595cc1@dave.eu>
In-Reply-To: <20260204-pl353-soft-ecc-support-v3-0-fd8ee7595cc1@dave.eu>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andrea Scian <andrea.scian@dave.eu>, stable@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770226919; l=1000;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=A80dHB4AMIcsHk3PCD1NFYNrqV41Ik2X1cY9lUFAPTA=;
 b=iAQcNioIIB5TAEIv9MmTY44uveT4rvHhfdbQpBSpr7ostFz/xAFDnN7lF94kScPxOIGsQm562
 KpwdPwUU+/7BzpHKEJ0WuSgJqx8o+mjJKfGi9ysnyQ19rw26BL0jy6l
X-Developer-Key: i=andrea.scian@dave.eu; a=ed25519;
 pk=PMQL72nEsyoiJCobnq0uEXwUFpVmkwoWIx317WvaQOU=
X-Endpoint-Received: by B4 Relay for andrea.scian@dave.eu/20260121 with auth_id=613
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to set also write_page_raw in ecc structure to allow
choosing SW ECC instead of HW one, otherwise write operation fail.

Fixes: 08d8c62164a322 ("mtd: rawnand: pl353: Add support for the ARM PL353 SMC NAND controller")
Signed-off-by: Andrea Scian <andrea.scian@dave.eu>
Cc: stable@kernel.org
---
 drivers/mtd/nand/raw/pl35x-nand-controller.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/mtd/nand/raw/pl35x-nand-controller.c b/drivers/mtd/nand/raw/pl35x-nand-controller.c
index 11bd90e3f18cb..7f012b7c3eaec 100644
--- a/drivers/mtd/nand/raw/pl35x-nand-controller.c
+++ b/drivers/mtd/nand/raw/pl35x-nand-controller.c
@@ -976,6 +976,7 @@ static int pl35x_nand_attach_chip(struct nand_chip *chip)
 		fallthrough;
 	case NAND_ECC_ENGINE_TYPE_NONE:
 	case NAND_ECC_ENGINE_TYPE_SOFT:
+		chip->ecc.write_page_raw = nand_monolithic_write_page_raw;
 		break;
 	case NAND_ECC_ENGINE_TYPE_ON_HOST:
 		ret = pl35x_nand_init_hw_ecc_controller(nfc, chip);

-- 
2.43.0

