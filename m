From: Andrea Scian <andrea.scian@dave.eu>
Date: Wed, 04 Feb 2026 18:41:45 +0100
Subject: [PATCH v3 2/2] mtd: rawnand: pl353: Add message about ECC mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-pl353-soft-ecc-support-v3-2-fd8ee7595cc1@dave.eu>
References: <20260204-pl353-soft-ecc-support-v3-0-fd8ee7595cc1@dave.eu>
In-Reply-To: <20260204-pl353-soft-ecc-support-v3-0-fd8ee7595cc1@dave.eu>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andrea Scian <andrea.scian@dave.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770226919; l=1229;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=mFOVwp9FgeabNIemoScL8JgY/55GfGdOi+dmhdTS6v8=;
 b=ALtkDl7uC/+psoQZRq0MRd0+db0BPslbHhrRHdceughAs8Re8enbDMqxdnewH+RrYfa40zd3w
 KxNiSz9loJoDJ9mlRdzCSV5f+Vf/CvofgVLH0Sfe2RePFAlortGBkrU
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
index 7f012b7c3eaec..947fd86ac5fa2 100644
--- a/drivers/mtd/nand/raw/pl35x-nand-controller.c
+++ b/drivers/mtd/nand/raw/pl35x-nand-controller.c
@@ -970,15 +970,18 @@ static int pl35x_nand_attach_chip(struct nand_chip *chip)
 
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
 		chip->ecc.write_page_raw = nand_monolithic_write_page_raw;
 		break;
 	case NAND_ECC_ENGINE_TYPE_ON_HOST:
+		dev_dbg(nfc->dev, "Using hardware ECC\n");
 		ret = pl35x_nand_init_hw_ecc_controller(nfc, chip);
 		if (ret)
 			return ret;

-- 
2.43.0

