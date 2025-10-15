From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 15 Oct 2025 15:36:59 +0800
Subject: [PATCH] spi: amlogic: fix spifc build error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251015-fix-spifc-a4-v1-1-08e0900e5b7e@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABpP72gC/x2MQQqAMAzAvjJ6ttBOHeJXxINo1V5UVhBB9neLx
 xCSF0yyikEfXshyq+l5OHAVYN6nYxPUxRkixZaJW1z1Qbt0nXFqkLo6ifBClBJ4cmVx/++GsZQ
 PwDhbkl4AAAA=
To: Liang Yang <liang.yang@amlogic.com>, Feng Chen <feng.chen@amlogic.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Guenter Roeck <linux@roeck-us.net>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760513827; l=1872;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=ib4K3AKweceHACtvQk2qAu1Cu/KOa08Hppl4rd6zBYY=;
 b=8MdBsfApJXW2O9AH4npOlocTZ3FbpagtH4/ZTFZY9aaslApccjLdZcT/BXHUPBJGo1s0YlV/W
 lFZuormMTOvBtGgqksRN9YUyQZCgOPpnnO2bEryepLQwFmbybNKJmvI
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is an error building when
Compiler version: gcc (GCC) 14.3.0
Assembler version: GNU assembler (GNU Binutils) 2.44
"
 Error log:
 WARNING: modpost: missing MODULE_DESCRIPTION() in arch/arm/probes/kprobes/test-kprobes.o
 ERROR: modpost: "__ffsdi2" [drivers/spi/spi-amlogic-spifc-a4.ko] undefined!
"

Use __ffs API instead of __bf_shf to be safer.

Reported-by: Guenter Roeck <linux@roeck-us.net>
Closes: https://lore.kernel.org/all/f594c621-f9e1-49f2-af31-23fbcb176058@roeck-us.net/
Fixes: 4670db6f32e9 ("spi: amlogic: add driver for Amlogic SPI Flash Controller")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix build err for spifc.
---
 drivers/spi/spi-amlogic-spifc-a4.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/spi/spi-amlogic-spifc-a4.c b/drivers/spi/spi-amlogic-spifc-a4.c
index 4338d00e56a6..35a7c4965e11 100644
--- a/drivers/spi/spi-amlogic-spifc-a4.c
+++ b/drivers/spi/spi-amlogic-spifc-a4.c
@@ -286,7 +286,7 @@ static int aml_sfc_set_bus_width(struct aml_sfc *sfc, u8 buswidth, u32 mask)
 
 	for (i = 0; i <= LANE_MAX; i++) {
 		if (buswidth == 1 << i) {
-			conf = i << __bf_shf(mask);
+			conf = i << __ffs(mask);
 			return regmap_update_bits(sfc->regmap_base, SFC_SPI_CFG,
 						  mask, conf);
 		}
@@ -566,7 +566,7 @@ static int aml_sfc_raw_io_op(struct aml_sfc *sfc, const struct spi_mem_op *op)
 	if (!op->data.nbytes)
 		goto end_xfer;
 
-	conf = (op->data.nbytes >> RAW_SIZE_BW) << __bf_shf(RAW_EXT_SIZE);
+	conf = (op->data.nbytes >> RAW_SIZE_BW) << __ffs(RAW_EXT_SIZE);
 	ret = regmap_update_bits(sfc->regmap_base, SFC_SPI_CFG, RAW_EXT_SIZE, conf);
 	if (ret)
 		goto err_out;

---
base-commit: 4412ab501677606436e5c49e41151a1e6eac7ac0
change-id: 20251015-fix-spifc-a4-0836ee1d0066

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

