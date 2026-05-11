From: Colin Huang <u8813345@gmail.com>
Date: Mon, 11 May 2026 17:47:56 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: add JTAG CPLD TRST pin to SGPIO
 map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-add-jtag-trst-pin-v1-1-b0be2f7b2da5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMulAWoC/x3MTQqAIBBA4avIrBtQsR+6SrQwnWpamKhEEN09a
 fkt3nsgU2LKMIoHEl2c+QwVqhHgdhs2QvbVoKXuZKsUWu/xKHbDknLByAFbI5feD8aSdlC7mGj
 l+39O8/t+z6YwNmMAAAA=
X-Change-ID: 20260511-add-jtag-trst-pin-540b7d84ae2c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778492878; l=1269;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=bBz3YS2LvMQAba2/yKKCExHR35pJbolOWMc0cULsHQc=;
 b=7eqrmaxmn6l4gBcvbL2EZFv54EpM2ExzQR73yUeUFlCbjQgpzwSnkXTmVVMzLP6g6IACqMNDx
 USyAryJvHoVAj1X87q8+El6BZfM90iU21bwytKBspw7Ok3OtcRg0YIX
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add JTAG_CPLD_TRST_R_N to the sgpiom0 pin name table on
Facebook Anacapa BMC.

This exposes the CPLD JTAG TRST signal through SGPIO,
allowing proper JTAG reset control during debug.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
Add JTAG_CPLD_TRST_R_N to the SGPIO M0 pin name table on
Facebook Anacapa BMC.

This exposes the CPLD JTAG TRST signal through SGPIO,
allowing proper JTAG reset control during debug.
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..9a43e0c87257 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -882,7 +882,7 @@ &sgpiom0 {
 	/* C0-C7 line 32-47 */
 	"RSVD_RMC_GPIO3", "", "", "",
 	"", "", "", "",
-	"LEAK_DETECT_RMC_N", "", "", "",
+	"LEAK_DETECT_RMC_N", "JTAG_CPLD_TRST_R_N", "", "",
 	"", "", "", "",
 
 	/* D0-D7 line 48-63 */

---
base-commit: b333a0f1c857411d83a02aa6f1d9ecc7666d6179
change-id: 20260511-add-jtag-trst-pin-540b7d84ae2c

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

