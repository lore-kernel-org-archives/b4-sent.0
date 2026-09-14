From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Mon, 14 Sep 2026 13:50:37 +0900
Subject: [PATCH 2/2] mtd: spi-nor: spansion: Assign .fixups to s25fs256s1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-s25fs256s-fixup-v1-2-e94019455c1e@infineon.com>
References: <20260914-s25fs256s-fixup-v1-0-e94019455c1e@infineon.com>
In-Reply-To: <20260914-s25fs256s-fixup-v1-0-e94019455c1e@infineon.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alexander Sverdlin <alex@sverdlin.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789361446; l=1111;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=rZ/ppqGkp79oofIgjp+2euFFx00lpMqR81jL20uurYg=;
 b=afD1LcUOLiZftmqkrFPqF/KTxnZRF8mPVBKSA7bPSLo5RV0+1PoKwVJ43wwJoIYUhPzYS2+9K
 HdcB9jBYcG0Aunc9iUZNcFjr34pqfo7BPM4UpUqY4k9as8A8K6FV1OQ
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

s25fs256s1 has incorrect SFDP entries, like s25fs512s and s25fs128s1.
Assign the common s25fs_s_nor_fixups to s25fs256s1 to fix its page size
and sector map.

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi-nor/spansion.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/mtd/spi-nor/spansion.c b/drivers/mtd/spi-nor/spansion.c
index 6a62ca6f6451..bc50881d5648 100644
--- a/drivers/mtd/spi-nor/spansion.c
+++ b/drivers/mtd/spi-nor/spansion.c
@@ -1148,6 +1148,7 @@ static const struct spi_nor_fixups spansion_nor_fixups = {
 static const struct spi_nor_fixup spansion_fixups[] = {
 	{ .fixups = &spansion_nor_fixups },
 	{ .id = SNOR_ID(0x01, 0x02, 0x20, 0x4d, 0x00, 0x81), .fixups = &s25fs_s_nor_fixups },
+	{ .id = SNOR_ID(0x01, 0x02, 0x19, 0x4d, 0x01, 0x81), .fixups = &s25fs_s_nor_fixups },
 	{ .id = SNOR_ID(0x01, 0x20, 0x18, 0x4d, 0x01, 0x81), .fixups = &s25fs_s_nor_fixups },
 	{ .id = SNOR_ID(0x01, 0x60, 0x17), .fixup_flags = SPI_NOR_4B_OPCODES },
 	{ .id = SNOR_ID(0x01, 0x60, 0x18), .fixup_flags = SPI_NOR_4B_OPCODES },

-- 
2.43.0

