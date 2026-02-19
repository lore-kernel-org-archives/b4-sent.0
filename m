From: Dirk Chen <dirkchen@amd.com>
Date: Thu, 19 Feb 2026 23:44:47 +0800
Subject: [PATCH v3] ARM: dts: aspeed: anacapa: Add retimer EEPROMs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260219-b4-anacapa-dts-fix-v3-1-4f70fd2d1070@amd.com>
X-B4-Tracking: v=1; b=H4sIAO4vl2kC/33NOQ7CMBAF0KtEU2NkOyZbxT0QxXgjLrLIjixQl
 LszSQMFohnpf+m/WSG5GFyCrlghuhxSmEYK5akA0+P4cCxYyiC5rDgdphXDEQ3OyOySmA9PJnn
 tvWux1NwADefoqD7Q251yH9IyxdfxI4u9/ctlwQSZVmkuhGou6oqDPZtpgB3L8htofwKSAO+Uq
 rDmZaP9B9i27Q2awI6R8wAAAA==
X-Change-ID: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Dirk Chen <dirkchen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771515902; l=1779;
 i=dirkchen@amd.com; s=20260202; h=from:subject:message-id;
 bh=e6uon8fDwRBTubN8ywUAkYjtYXx6mIWRj19Qi3Y6T6g=;
 b=yPhRCyA6wRLeJlcr0K5q0+OqpgObOJe/AzDQSJiYDKvOW5cRhT9MUc8VQfNRlWLPZMUt0q/EO
 hdK+ttB1juxBEjXrPe59DC/BQLuAYSuWc+elt78/2d3j+BRmO5H9K/+
X-Developer-Key: i=dirkchen@amd.com; a=ed25519;
 pk=NBIyLsVg/YYtGLruq9XLdLWx2PP/1MH4jDDQ1V+7wes=
X-Endpoint-Received: by B4 Relay for dirkchen@amd.com/20260202 with auth_id=622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Anacapa board features Atmel 24C2048 EEPROMs on i2c0 and i2c1, which
are used to store retimer configurations. Add the corresponding device
tree nodes to support these components.

Signed-off-by: Dirk Chen <dirkchen@amd.com>
---
Changes in v3:
- Reorder I2C device nodes by ascending address (place eeprom@50
  before i2c-mux@70)
- Link to v2: https://lore.kernel.org/r/20260209-b4-anacapa-dts-fix-v2-1-fe446a7038bf@amd.com

Changes in v2:
- Improved commit description to clarify that the change reflects
  actual hardware as requested by the reviewer.
- Removed mentions of other platforms to avoid confusion.
- Link to v1: https://lore.kernel.org/r/20260202-b4-anacapa-dts-fix-v1-1-20d4b0114854@amd.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 221af858cb6b..1502773d9c30 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -300,6 +300,12 @@ &gpio1 {
 &i2c0 {
 	status = "okay";
 
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
+
 	i2c-mux@70 {
 		compatible = "nxp,pca9546";
 		reg = <0x70>;
@@ -334,6 +340,12 @@ i2c0mux0ch3: i2c@3 {
 &i2c1 {
 	status = "okay";
 
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
+
 	i2c-mux@70 {
 		compatible = "nxp,pca9546";
 		reg = <0x70>;

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c

Best regards,
-- 
Dirk Chen <dirkchen@amd.com>

