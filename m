From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Fri, 20 Nov 2026 01:22:15 -0600
Subject: [PATCH 3/4] arm64: dts: allwinner: a100: Add I2C3 pins on
 PH12/PH13
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-k5c-dt-v1-v1-3-d9681df67bc0@gmail.com>
References: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
In-Reply-To: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Andre Przywara <andre.przywara@arm.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795159332; l=1081;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=UFMjszeV5jY5MlhRImFhFWSmTuLXTuOi5e8vjBXAcxE=;
 b=iko6jvcOP72UNQVCm5to4OaQaKNmcol5fjgeB0J1qSj7zNC5hDY3ktgiefoFh2038NbAEejZ6
 5yNI5UQqjoZDb8NkcI4+v2GW16brogpaCFH5f2YbCd+21HeMhZWsHwr
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The I2C3 controller can use PH12 (SCK) and PH13 (SDA). The KickPi K5C
connects its HYM8563 RTC there.

Add a pin group for them, marked /omit-if-no-ref/ like mmc1_pins, so
it is only kept in the boards that use it.

Claude Code (Anthropic) drafted this change and its message; I
reviewed it and tested it on a KickPi K5C.

Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
index fce91dc2c28..3b53d64f25e 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
@@ -215,6 +215,12 @@ pio: pinctrl@300b000 {
 			interrupt-controller;
 			#interrupt-cells = <3>;
 
+			/omit-if-no-ref/
+			i2c3_ph_pins: i2c3-ph-pins {
+				pins = "PH12", "PH13";
+				function = "i2c3";
+			};
+
 			mmc0_pins: mmc0-pins {
 				pins = "PF0", "PF1", "PF2", "PF3",
 				       "PF4", "PF5";

-- 
2.34.1

