From: Alex Wang <alex.ts.wang@fii-foxconn.com>
Date: Thu, 27 Nov 2025 17:44:51 +0800
Subject: [PATCH v2] dt: aspeed: clemente: move hdd_led to its own gpio-leds
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251127-leo-dts-add-shunt-resistor-v2-1-c77dfbfb826c@fii-foxconn.com>
X-B4-Tracking: v=1; b=H4sIAJIdKGkC/42NQQrCMBBFr1Jm7UiSEmldeQ/pIiZTO6CJZGqol
 N7d2BO4fJ/H+ysIZSaBc7NCpsLCKVYwhwb85OKdkENlMMpYrUyLD0oYZkEXAsr0jjNmEpY5ZTR
 dNdTJ2eAIauCVaeRlj1+HytOuffavon/rX9miUaMNfd8pd3Ot6i4jM45p8SnGo09PGLZt+wI3H
 A6KygAAAA==
X-Change-ID: 20251023-leo-dts-add-shunt-resistor-2810206a5dae
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 george.kw.lee@fii-foxconn.com, Alex Wang <alex.ts.wang@fii-foxconn.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764236694; l=2118;
 i=alex.ts.wang@fii-foxconn.com; s=20251023; h=from:subject:message-id;
 bh=XvfoAuDaFi0LEYIxrGZlYJX6g2aVVWHGpukneXb5b2k=;
 b=SXG/ZRsEzAm0y+7zt1tH9Ydnb+YuQ8Z7nkeAo5L/ekXuavdkD1Ale8faYlW8bQmxmf8E7FYoW
 4p9x7BbeD/6BzqaKejgS49RqwnHxC/r9cz33N53NCEPzRlctPJ3nLVM
X-Developer-Key: i=alex.ts.wang@fii-foxconn.com; a=ed25519;
 pk=m/IrKXb14uSdDm4KGXemjNIxgL6TrqXCc9NX09SUJp0=
X-Endpoint-Received: by B4 Relay for alex.ts.wang@fii-foxconn.com/20251023 with auth_id=551
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gpio-leds driver requires all GPIOs in a group to be available;
if any GPIO in the group is not available the whole group will not be
created. The hdd_led GPIO is only present after standby power is
enabled, which can prevent other LEDs in the same group from being
created and blocks properly setting 'bmc_ready_noled'.

Move the 'hdd_led' node into a separate gpio-leds group so that other
LEDs are not blocked and the 'bmc_ready_noled' flag can be set
correctly.

Signed-off-by: Alex Wang <alex.ts.wang@fii-foxconn.com>
---
Changes in v2:
- I changed “missing” to “not available”. The hdd_led and bmc_ready_noled 
do not disappear; it's just that hdd_led only becomes available after 
standby power is enabled, and this process takes some time. The hdd_led 
becomes available only after bmc_ready_noled is supposed to be set, 
which causes bmc_ready_noled to fail to be generated and set in time.

- Standby power is enabled during the BMC boot process.

- The hdd_led will only be configured after the BMC boots, when a 
dedicated service starts and applies the settings.

- Link to v1: https://lore.kernel.org/r/20251023-leo-dts-add-shunt-resistor-v1-1-5d9980aba308@fii-foxconn.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
index dfe8f6d0eeef..ea1bf6f402bd 100644
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
base-commit: c6fea62a8379f9e24b243ea4ba1fd482f8cd0d83
change-id: 20251023-leo-dts-add-shunt-resistor-2810206a5dae

Best regards,
-- 
Alex Wang <alex.ts.wang@fii-foxconn.com>

