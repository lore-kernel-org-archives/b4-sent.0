From: Carl Lee <carl.lee@amd.com>
Date: Tue, 31 Mar 2026 16:02:28 +0800
Subject: [PATCH v3] ARM: dts: aspeed: anacapa: Add eeprom device node for
 NFC adaptor board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260331-arm-dts-aspeed-anacapa-add-eeprom-device-v3-1-2bb2226fbb4e@amd.com>
X-B4-Tracking: v=1; b=H4sIAJN/y2kC/52NOw6DMBAFr4JcZyN/+Mipco8oxeLdBBdgZCMrE
 eLuMTTpKec9aWYViaPnJG7VKiJnn3yYCphLJdyA05vBU2GhpW6lkRYwjkBLAkwzMwFO6HBGQCJ
 gnmMob9E4BlSIPcsWTdOLopsjv/znSD2ehQeflhC/RzmrfT0RyQok1I202ijJkts7jnR1YRR7I
 uuzWg0KrHIdEdd9Z+mv3bbtB6vL7to1AQAA
X-Change-ID: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774944151; l=1502;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=tK4ZlqqLdi/4bQSFXDH6JCKjm/zDadASdjOjaR1GT4A=;
 b=SaG/KqMDLIxRikW7LI9c8QOG9XIn/wzre1v8BpnxvZL8oSWTfadp8FR8SP4Lf7sUfnMLULhG0
 NjbP5yWI7GmC0NzJJoaRnpZ72jo1n6xtViWE2VC6hqD6/Q/kYVsRVaK
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add eeprom device node for NFC adaptor board FRU.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Add eeprom device node to store FRU data for NFC adapter
board on Anacapa platform.
---
Changes in v3:
- Fix node ordering to follow ascending unit address
- Update commit message to match actual changes
- Link to v2: https://lore.kernel.org/r/20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v2-1-91c7dde4b79d@amd.com

Changes in v2:
- Remove PRoT module eeprom commit since it is already included in another series under review.
- Only include NFC adapter board eeprom node.
- Link to v1: https://lore.kernel.org/r/20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-0-45092310e0e6@amd.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..57fd81e931d6 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -824,6 +824,11 @@ nfc@28 {
 
 				enable-gpios = <&sgpiom0 241 GPIO_ACTIVE_HIGH>;
 			};
+
+			eeprom@50 {
+				compatible = "atmel,24c128";
+				reg = <0x50>;
+			};
 		};
 	};
 };

---
base-commit: a0ae2a256046c0c5d3778d1a194ff2e171f16e5f
change-id: 20260309-arm-dts-aspeed-anacapa-add-eeprom-device-a1aabe06a35b

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

