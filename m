From: Guo Hao <guohaoprc@163.com>
Date: Wed, 15 Jul 2026 11:32:26 +0800
Subject: [PATCH] board: ti: am62x: Fix build without TI_I2C_BOARD_DETECT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-am62x-no-board-detect-v1-1-2969faec1001@163.com>
X-B4-Tracking: v=1; b=H4sIAEn/VmoC/yXMQQqDMBCF4avIrDuQhJqAVyldJM5op2BSEi2Ce
 HejLj9479+gcBYu0DUbZP5LkRQr9KOB/uPjyChUDUYZq5xu0U/WrBgThuQzIfHM/Yw2GA7PwRE
 pC/X7yzzIenVf79tlCd86PWOw7wdLA5TIeQAAAA==
X-Change-ID: 20260715-am62x-no-board-detect-6b2eb4f7dd06
To: "Guillaume La Roque (TI.com)" <glaroque@baylibre.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, u-boot@lists.denx.de
Cc: Bryan Brattlof <bb@ti.com>, Tom Rini <trini@konsulko.com>, 
 Yao Zi <me@ziyao.cc>, Patrice Chotard <patrice.chotard@foss.st.com>, 
 Vishal Mahaveer <vishalm@ti.com>, Peng Fan <peng.fan@nxp.com>, 
 Guo Hao <guohaoprc@163.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784086442; l=1266;
 i=guohaoprc@163.com; s=20260715; h=from:subject:message-id;
 bh=G3Mhs8J9V0d8ZQoA8QQUSCj8yZ5UWak1KQPX0gCC1AU=;
 b=nrcf05D4qL4qyJzyCjsuwoWV4+aSgvTjGIeBeabyBWiLkVOc136XhKDX+I1CpLVew2J4o8BG3
 daZsRZYN/FNDhr4Vc5GRGVlKUf+KLvoEV3jNsDklQscul8VVCqGfQPe
X-Developer-Key: i=guohaoprc@163.com; a=ed25519;
 pk=LuAU/SLdnwHV0emUu69VagQyjh4bAVGO89ZPeHKJCrA=
X-Endpoint-Received: by B4 Relay for guohaoprc@163.com/20260715 with auth_id=873
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

setup_board_eeprom_env() and setup_serial_am6() are only available when
TI_I2C_BOARD_DETECT is enabled.

IS_ENABLED() does not remove the guarded statements during preprocessing,
so disabling TI_I2C_BOARD_DETECT results in an implicit function
declaration error. Use a preprocessor condition to match the condition
used for the function definition.

Fixes: ff1b83c095c2 ("board: am62x: Add support for reading eeprom data")
Signed-off-by: Guo Hao <guohaoprc@163.com>
---
 board/ti/am62x/evm.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/board/ti/am62x/evm.c b/board/ti/am62x/evm.c
index 49e58ad6d6c..f54abb56384 100644
--- a/board/ti/am62x/evm.c
+++ b/board/ti/am62x/evm.c
@@ -125,10 +125,10 @@ invalid_eeprom:
 #if CONFIG_IS_ENABLED(BOARD_LATE_INIT)
 int board_late_init(void)
 {
-	if (IS_ENABLED(CONFIG_TI_I2C_BOARD_DETECT)) {
-		setup_board_eeprom_env();
-		setup_serial_am6();
-	}
+#if CONFIG_IS_ENABLED(TI_I2C_BOARD_DETECT)
+	setup_board_eeprom_env();
+	setup_serial_am6();
+#endif
 
 	ti_set_fdt_env(NULL, NULL);
 	return 0;

---
base-commit: 501d76ca801343cce6dafb17740a8b679ed17072
change-id: 20260715-am62x-no-board-detect-6b2eb4f7dd06

Best regards,
--  
Guo Hao <guohaoprc@163.com>

