From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Mon, 14 Sep 2026 13:50:36 +0900
Subject: [PATCH 1/2] mtd: spi-nor: spansion: Remove s25fs256s0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-s25fs256s-fixup-v1-1-e94019455c1e@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789361446; l=1387;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=pC764isHWSwUhqkcJDPq348qqcspEvCp/PJEhckABAE=;
 b=xeZWmnO0p1VtbkZpMy3oreJH6iuRIcRaqHDLsyQKPUvPcNBzUDdA/ENxEB7dfhFp0S8VcoY4W
 0p11DtqFcQrAiAN4/3/YF4KOR/NhhXI73HR2JTblBZVAEF1+2lQuANq
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Spansion ID table lists s25fs256s0 and s25fs256s1 as variants
distinguished by id[4] (0x00 for 256 KB sectors and 0x01 for 64 KB
sectors), following an incorrect statement in the datasheet.

The sector size of s25fs256s is configurable between 256 KB and 64 KB.
The factory default is 64 KB, and id[4] is always 0x01 regardless of the
configured sector size. Remove the invalid s25fs256s0 entry from the ID
table.

Fixes: 075fd6dff24a ("mtd: spi-nor: spansion: Differentiate between s25fl256s and s25fs256s")
Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi-nor/spansion.c | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/drivers/mtd/spi-nor/spansion.c b/drivers/mtd/spi-nor/spansion.c
index 6938fe26969c..6a62ca6f6451 100644
--- a/drivers/mtd/spi-nor/spansion.c
+++ b/drivers/mtd/spi-nor/spansion.c
@@ -873,13 +873,6 @@ static const struct flash_info spansion_nor_parts[] = {
 		.sector_size = SZ_256K,
 		.no_sfdp_flags = SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ,
 		.mfr_flags = USE_CLSR,
-	}, {
-		.id = SNOR_ID(0x01, 0x02, 0x19, 0x4d, 0x00, 0x81),
-		.name = "s25fs256s0",
-		.size = SZ_32M,
-		.sector_size = SZ_256K,
-		.no_sfdp_flags = SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ,
-		.mfr_flags = USE_CLSR,
 	}, {
 		.id = SNOR_ID(0x01, 0x02, 0x19, 0x4d, 0x01, 0x80),
 		.name = "s25fl256s1",

-- 
2.43.0

