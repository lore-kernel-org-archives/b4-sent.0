From: Carl Lee <carl.lee@amd.com>
Date: Mon, 09 Feb 2026 10:25:59 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: add NFC device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-add-nfc-device-v1-1-748d1a98b2b5@amd.com>
X-B4-Tracking: v=1; b=H4sIALZFiWkC/x2MQQqAIBAAvxJ7bkElg/pKdFB3t/ZioRBB9Pek4
 8DMPFC5KFeYuwcKX1r1yA1s30HaQ94YlRqDM240zkwYiDBLQmpyYuQgYofoyUeBFp2FRe9/uKz
 v+wHAUqHJYAAAAA==
X-Change-ID: 20260209-add-nfc-device-eaff14b5d5bf
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770603961; l=1030;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=fAioY0/uBa8OFcIA56wyA/W2gJNy1rdRQAUCDykPe7E=;
 b=he7DbyjQeooaxxeK62Gnonp0ve5OOlWEu63CG4Dw+dnDtFlATMjIVxFTXipgfGB1C+smjB4Bh
 ojMR4pX3PcvBYSKqdYCsaux087oN5zOjEO1cODH5RIkYk7ZYMO2Kn4B
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add NFC NXP NCI device support to NFC tag reading

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 221af858cb6b..7349d25434e6 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -802,6 +802,16 @@ i2c13mux0ch7: i2c@7 {
 			reg = <7>;
 			#address-cells = <1>;
 			#size-cells = <0>;
+
+			nfc@28 {
+				compatible = "nxp,nxp-nci-i2c";
+				reg = <0x28>;
+
+				interrupt-parent = <&sgpiom0>;
+				interrupts = <156 IRQ_TYPE_LEVEL_HIGH>;
+
+				enable-gpios = <&sgpiom0 241 GPIO_ACTIVE_HIGH>;
+			};
 		};
 	};
 };

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260209-add-nfc-device-eaff14b5d5bf

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

