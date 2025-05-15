From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 15 May 2025 21:46:05 +0400
Subject: [PATCH] mtd: spinand: esmt: fix id code for F50D1G41LB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-spinand-esmt-v1-1-37507b7335b8@outlook.com>
X-B4-Tracking: v=1; b=H4sIAFwoJmgC/x3MQQqAIBBA0avErBNUMKmrRItBp5pFJk5EIN09a
 fkW/1cQKkwCU1eh0M3CZ2owfQdhx7SR4tgMVlunnXFKMidMUZEcl/LDGgZE9NqM0JJcaOXn383
 L+35eF3moXgAAAA==
X-Change-ID: 20250515-spinand-esmt-76fc6aaa7019
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Martin Kurbanov <mmkurbanov@salutedevices.com>, 
 Ezra Buehler <ezra.buehler@husqvarnagroup.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 robimarko@gmail.com, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747331167; l=1761;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=Bw7bpiUiZpTxxhtD+xg0nBao9Wz8H2pesY3n+hLtv0Y=;
 b=TB7980Qcxb+4Xz2tPA3TAkYBEvGxcrLGn3YFB35SRxhwW3A2Ru/l1chsBs0UlKVw+R8PK3Z3j
 71BFt4VyfteB/5sxdDFUSzVxCRpVK1x9kGkLowFAggW5UNUGtf0o9O0
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Upon detecting the ID for the ESMT F50D1G41LB chip, the fifth byte
returned is always 0x00 instead of the expected JEDEC continuation code
of 0x7f. This causes detection to fail:

[    0.304399] spi-nand spi0.0: unknown raw ID c8117f7f00
[    0.508943] spi-nand: probe of spi0.0 failed with error -524

So let's revert back to the 4 byte ID code for this chip
specifically.

Fixes: 4bd14b2fd8a8 ("mtd: spinand: esmt: Extend IDs to 5 bytes")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
drivers/mtd/nand/raw/nand_esmt.c mentions that the 5th byte is used to
set ECC strength requirements for the detected chip, so no JEDEC
continuation code is actually expected. I don't know if this there was
a change in design or approach somewhere along the way, hence I fixed
the ID for this chip only.
---
 drivers/mtd/nand/spi/esmt.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mtd/nand/spi/esmt.c b/drivers/mtd/nand/spi/esmt.c
index 299d0e507c29fcde1c38d2fdebc0cc755825dade..9e286612a296c75831f7b95a010a5fe47579c36d 100644
--- a/drivers/mtd/nand/spi/esmt.c
+++ b/drivers/mtd/nand/spi/esmt.c
@@ -199,7 +199,7 @@ static const struct spinand_info esmt_c8_spinand_table[] = {
 		     SPINAND_FACT_OTP_INFO(2, 0, &f50l1g41lb_fact_otp_ops)),
 	SPINAND_INFO("F50D1G41LB",
 		     SPINAND_ID(SPINAND_READID_METHOD_OPCODE_ADDR, 0x11, 0x7f,
-				0x7f, 0x7f),
+				0x7f),
 		     NAND_MEMORG(1, 2048, 64, 64, 1024, 20, 1, 1, 1),
 		     NAND_ECCREQ(1, 512),
 		     SPINAND_INFO_OP_VARIANTS(&read_cache_variants,

---
base-commit: 484803582c77061b470ac64a634f25f89715be3f
change-id: 20250515-spinand-esmt-76fc6aaa7019

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

