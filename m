From: Andrea Scian <andrea.scian@dave.eu>
Date: Mon, 26 Jan 2026 17:58:56 +0100
Subject: [PATCH v2 2/2] mtd: rawnand: pl353: Add message about ECC mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-pl353-soft-ecc-support-v2-2-fcd74b6e955f@dave.eu>
References: <20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu>
In-Reply-To: <20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Amit Kumar <amit.kumar-mahapatra@amd.com>, 
 Andrea Scian <andrea.scian@dave.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769446742; l=1273;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=W54VDp3ZuMb3O2+EOIc9KMGJG7f9MGc6xwP0ApOENno=;
 b=0PXv3vemO7XV8diJRAX7vegCXBaskah1elabJYQNWe3Q7S3LuwMXE2yPJAjFxFnL/EORJsiRQ
 mVMyImAcEanBHy3xPkySpIIDoajRo7IENyT8qSfWnm+vriOqqLGvOTr
X-Developer-Key: i=andrea.scian@dave.eu; a=ed25519;
 pk=PMQL72nEsyoiJCobnq0uEXwUFpVmkwoWIx317WvaQOU=
X-Endpoint-Received: by B4 Relay for andrea.scian@dave.eu/20260121 with auth_id=613
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This just add some information on kernel log about the selected ECC

Signed-off-by: Andrea Scian <andrea.scian@dave.eu>
---
 drivers/mtd/nand/raw/pl35x-nand-controller.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/mtd/nand/raw/pl35x-nand-controller.c b/drivers/mtd/nand/raw/pl35x-nand-controller.c
index fcb62b9ec947b..cbef4f0084844 100644
--- a/drivers/mtd/nand/raw/pl35x-nand-controller.c
+++ b/drivers/mtd/nand/raw/pl35x-nand-controller.c
@@ -970,16 +970,19 @@ static int pl35x_nand_attach_chip(struct nand_chip *chip)
 
 	switch (chip->ecc.engine_type) {
 	case NAND_ECC_ENGINE_TYPE_ON_DIE:
+		dev_dbg(nfc->dev, "Using on-die ECC\n");
 		/* Keep these legacy BBT descriptors for ON_DIE situations */
 		chip->bbt_td = &bbt_main_descr;
 		chip->bbt_md = &bbt_mirror_descr;
 		fallthrough;
 	case NAND_ECC_ENGINE_TYPE_NONE:
 	case NAND_ECC_ENGINE_TYPE_SOFT:
+		dev_dbg(nfc->dev, "Using software ECC (Hamming 1-bit/512B)\n");
 		chip->ecc.algo = NAND_ECC_ALGO_HAMMING;
 		chip->ecc.write_page_raw = nand_monolithic_write_page_raw;
 		break;
 	case NAND_ECC_ENGINE_TYPE_ON_HOST:
+		dev_dbg(nfc->dev, "Using hardware ECC\n");
 		ret = pl35x_nand_init_hw_ecc_controller(nfc, chip);
 		if (ret)
 			return ret;

-- 
2.43.0

