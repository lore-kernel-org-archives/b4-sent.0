From: Rex Fu <Rex.Fu@amd.com>
Date: Fri, 17 Apr 2026 14:41:49 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: add interrupt properties for
 PDB PCA9555
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-anacapa-pca9555-irq-v1-1-9a6d28b1b656@amd.com>
X-B4-Tracking: v=1; b=H4sIACzW4WkC/yXMQQ6CMBCF4auQWTvJFKhNvYpxMZRRx0WtLRISw
 t0puvyS9/4VimSVApdmhSyzFn3HCnNqIDw5PgR1rIaW2jP1xiFHDpwYU2BvrUXNH+zI09ibunE
 E9Zmy3HX5Va+3v8t3eEmYjhRs2w40R47BdwAAAA==
X-Change-ID: 20260417-anacapa-pca9555-irq-3090d4120270
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Rex Fu <Rex.Fu@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776408109; l=2007;
 i=Rex.Fu@amd.com; s=20260417; h=from:subject:message-id;
 bh=o8qWPDdSQIz2wmiJKXl6X/Ju2Iig3de8Ah1xPVk1Lb4=;
 b=9MQxnVgP2xpf8cl0ReSJT9bCAGSgrGLhuJrX1lJDGwcxn2Z0N5+8gjRkpTj50taQzIWiLxU4L
 Rb3uKLvuM8zCiSq+XVL/I8mP31UxsiKnatCzhTZShNcZeUVeGzJucDu
X-Developer-Key: i=Rex.Fu@amd.com; a=ed25519;
 pk=26ECoh24fxrbXDKgA4hCmgg0xjQ+IxU97kXb46ovwgc=
X-Endpoint-Received: by B4 Relay for Rex.Fu@amd.com/20260417 with auth_id=738
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt-parent and interrupts properties to the PDB PCA9555
nodes in the anacapa DTS.

Signed-off-by: Rex Fu <Rex.Fu@amd.com>
---
Single DTS update for the PDB PCA9555 interrupt wiring on anacapa.
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..7319f2319bb7 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -481,6 +481,9 @@ gpio@22 {
 				gpio-controller;
 				#gpio-cells = <2>;
 
+				interrupt-parent = <&sgpiom0>;
+				interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
+
 				gpio-line-names =
 					"RPDB_FAN_FULL_SPEED_R_N", "RPDB_I2C_TEMP75_U8_ALERT_R_N",
 					"RPDB_I2C_TMP432_U29_ALERT_R_N", "RPDB_GLOBAL_WP",
@@ -500,6 +503,9 @@ gpio@24 {
 				gpio-controller;
 				#gpio-cells = <2>;
 
+				interrupt-parent = <&sgpiom0>;
+				interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
+
 				gpio-line-names =
 					"RPDB_EAM2_PRSNT_MOS_N_R", "RPDB_EAM3_PRSNT_MOS_N_R",
 					"RPDB_PWRGD_P50V_HSC4_SYS_R",
@@ -529,6 +535,9 @@ gpio@22 {
 				gpio-controller;
 				#gpio-cells = <2>;
 
+				interrupt-parent = <&sgpiom0>;
+				interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
+
 				gpio-line-names =
 					"LPDB_FAN_FULL_SPEED_R_N","LPDB_I2C_TEMP75_U8_ALERT_R_N",
 					"LPDB_I2C_TMP432_U29_ALERT_R_N","LPDB_GLOBAL_WP",
@@ -546,6 +555,9 @@ gpio@24 {
 				gpio-controller;
 				#gpio-cells = <2>;
 
+				interrupt-parent = <&sgpiom0>;
+				interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
+
 				gpio-line-names =
 					"LPDB_P50V_FAN1_R2_PG","LPDB_P50V_FAN2_R2_PG",
 					"LPDB_P50V_FAN3_R2_PG","LPDB_P50V_FAN4_R2_PG",

---
base-commit: 76b4ec8efdc3887cdbf730da2e55881fc1a18770
change-id: 20260417-anacapa-pca9555-irq-3090d4120270

Best regards,
--  
Rex Fu <Rex.Fu@amd.com>

