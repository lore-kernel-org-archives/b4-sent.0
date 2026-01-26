From: Andrea Scian <andrea.scian@dave.eu>
Date: Mon, 26 Jan 2026 17:58:55 +0100
Subject: [PATCH v2 1/2] mtd: rawnand: pl353: Fix software ECC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-pl353-soft-ecc-support-v2-1-fcd74b6e955f@dave.eu>
References: <20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu>
In-Reply-To: <20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Amit Kumar <amit.kumar-mahapatra@amd.com>, 
 Andrea Scian <andrea.scian@dave.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769446742; l=930;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=pjp7e5XqvjwdI+0l+aByZIcrYrWvIGxc1jaHj+aNu4Q=;
 b=XqkcYEu2zoXUaDXq30sYtPT/NnekjpeCT3cOKfKNN1+YiL3zej8d3DiZpVfT9Nx5rwkAb/U0/
 +74MntHAS0kDFwCdVVtOXNPlXeXK0I9a+KuigMg+5RjWATmN6WcPJxW
X-Developer-Key: i=andrea.scian@dave.eu; a=ed25519;
 pk=PMQL72nEsyoiJCobnq0uEXwUFpVmkwoWIx317WvaQOU=
X-Endpoint-Received: by B4 Relay for andrea.scian@dave.eu/20260121 with auth_id=613
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to set another couple of fields in ecc structure to allow
choosing SW ECC instead of HW one, otherwise write operation fail.

Signed-off-by: Andrea Scian <andrea.scian@dave.eu>
---
 drivers/mtd/nand/raw/pl35x-nand-controller.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/mtd/nand/raw/pl35x-nand-controller.c b/drivers/mtd/nand/raw/pl35x-nand-controller.c
index 11bd90e3f18cb..fcb62b9ec947b 100644
--- a/drivers/mtd/nand/raw/pl35x-nand-controller.c
+++ b/drivers/mtd/nand/raw/pl35x-nand-controller.c
@@ -976,6 +976,8 @@ static int pl35x_nand_attach_chip(struct nand_chip *chip)
 		fallthrough;
 	case NAND_ECC_ENGINE_TYPE_NONE:
 	case NAND_ECC_ENGINE_TYPE_SOFT:
+		chip->ecc.algo = NAND_ECC_ALGO_HAMMING;
+		chip->ecc.write_page_raw = nand_monolithic_write_page_raw;
 		break;
 	case NAND_ECC_ENGINE_TYPE_ON_HOST:
 		ret = pl35x_nand_init_hw_ecc_controller(nfc, chip);

-- 
2.43.0

