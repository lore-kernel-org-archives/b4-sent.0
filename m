From: Alex Wang <alex.ts.wang@fii-foxconn.com>
Date: Thu, 23 Oct 2025 18:26:56 +0800
Subject: [PATCH] dt: aspeed: clemente: move hdd_led to its own gpio-leds
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-leo-dts-add-shunt-resistor-v1-1-5d9980aba308@fii-foxconn.com>
X-B4-Tracking: v=1; b=H4sIAO8C+mgC/x3MQQqEMAxA0atI1gZqpYN4FXFRTEYDQytJFUG8u
 2WWDz7/BmMVNhibG5RPMcmpomsbWLaYVkahavDOh875Hn+ckYphJELbjlRQ2cRKVvRDLdwnBoo
 MdbArf+X6z6f5eV6VPZlpbAAAAA==
X-Change-ID: 20251023-leo-dts-add-shunt-resistor-2810206a5dae
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 george.kw.lee@fii-foxconn.com, Alex Wang <alex.ts.wang@fii-foxconn.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761215247; l=1426;
 i=alex.ts.wang@fii-foxconn.com; s=20251023; h=from:subject:message-id;
 bh=nhjdaQhGONa6qRe6C17O9kT3BPIniN47qBnafl7NHt8=;
 b=un87bQXpomsn/0FLsOCFLiEpZ+BJAggKp/q9MiS5J3KjRJmifLf7SQcSV3kCAhfv3Qyd3/5/9
 gX5dDcKJ9s/AEHQk5fY+7RY7xwxkO6/DDYnjudaSMejQr96SpfDXuRx
X-Developer-Key: i=alex.ts.wang@fii-foxconn.com; a=ed25519;
 pk=m/IrKXb14uSdDm4KGXemjNIxgL6TrqXCc9NX09SUJp0=
X-Endpoint-Received: by B4 Relay for alex.ts.wang@fii-foxconn.com/20251023 with auth_id=551
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gpio-leds driver requires all GPIOs in a group to be available;
if any GPIO in the group is missing the whole group will not be
created. The hdd_led GPIO is only present after standby power is
enabled, which can prevent other LEDs in the same group from being
created and blocks properly setting 'bmc_ready_noled'.

Move the 'hdd_led' node into a separate gpio-leds group so that other
LEDs are not blocked and the 'bmc_ready_noled' flag can be set
correctly.

Signed-off-by: Alex Wang <alex.ts.wang@fii-foxconn.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
index 450446913e36..c58922695f46 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
@@ -96,7 +96,12 @@ led-3 {
 			gpios = <&gpio0 ASPEED_GPIO(P, 5) (GPIO_ACTIVE_HIGH|GPIO_TRANSITORY)>;
 		};
 
-		led-hdd {
+	};
+
+	hdd-leds {
+		compatible = "gpio-leds";
+
+		led-0 {
 			label = "hdd_led";
 			gpios = <&io_expander13 1 GPIO_ACTIVE_LOW>;
 		};

---
base-commit: b5dd162282164dc202541ce6551cf705d345820e
change-id: 20251023-leo-dts-add-shunt-resistor-2810206a5dae

Best regards,
-- 
Alex Wang <alex.ts.wang@fii-foxconn.com>

