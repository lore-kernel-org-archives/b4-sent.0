From: Carl Lee <carl.lee@amd.com>
Date: Mon, 09 Mar 2026 11:46:17 +0800
Subject: [PATCH v2] ARM: dts: aspeed: anacapa: Add eeprom device node for
 NFC adaptor board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v2-1-91c7dde4b79d@amd.com>
X-B4-Tracking: v=1; b=H4sIAIhCrmkC/52NQQ6CMBBFr0Jm7ZhpkSa48h6ExdCO0gW0aQnRk
 N7dyhFcvv+T9w7IkrxkuDcHJNl99mGtoC8N2JnXl6B3lUGTNtRSj5wWdFtGzlHEIa9sOTKycyg
 SU6hv1VhBVsyTkOG2m6DqYpKnf5+pYaw8+7yF9DnLu/qtf0R2hYS3jnrdKhIS8+DFXW1YYCylf
 AFca4/l3gAAAA==
X-Change-ID: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773027984; l=1346;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=4s2WZE7z3QJxXI/iwi/VjWJKQZJpdVWFD4P2EAdFysk=;
 b=NpUojOD+pYSQF7vSOrQb0hN1vZm56HiHxHGz+afcDYeGmB1rM7LVBDX2hAgXGEKrQpaX8Lhot
 4rC5mTqDpcECGWKDsWLyuIEAngdgoTW/wK9VHefT7DqR8dA2EJBgn3y
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add eeprom device node for NFC adaptor board FRU.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Add eeprom device nodes used to store FRU data for the PRoT
module and NFC adapter board on Anacapa platform.
---
Changes in v2:
- Remove PRoT module eeprom commit since it is already included in another series under review.
- Only include NFC adapter board eeprom node.
- Link to v1: https://lore.kernel.org/r/20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-0-45092310e0e6@amd.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..69c41532fdfb 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -815,6 +815,11 @@ i2c13mux0ch7: i2c@7 {
 			#address-cells = <1>;
 			#size-cells = <0>;
 
+			eeprom@50 {
+				compatible = "atmel,24c128";
+				reg = <0x50>;
+			};
+
 			nfc@28 {
 				compatible = "nxp,nxp-nci-i2c";
 				reg = <0x28>;

---
base-commit: a0ae2a256046c0c5d3778d1a194ff2e171f16e5f
change-id: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

