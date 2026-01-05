From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:39:39 +0100
Subject: [PATCH 2/6] arm64: dts: imx8mq-librem5: Set vibrator's PWM
 frequency to 20kHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-l5-dtb-fixes-v1-2-f491881a7fe7@puri.sm>
References: <20260105-l5-dtb-fixes-v1-0-f491881a7fe7@puri.sm>
In-Reply-To: <20260105-l5-dtb-fixes-v1-0-f491881a7fe7@puri.sm>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kernel@puri.sm, Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=749;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=mWjiGD93KU5JQ4pA+53e2M04IxEsYMuhokGFrksgrDY=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGgqttq+Ouq2hv/6Dn4UoLGmbKx102d0r23m
 sd7dnppWf+JAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoAAKCRDo8jXPO9vD
 /850D/9l1AIG6Fq3262RjmKQIbLMBPF2FY+th7kkzgYFngWz0A5u2NRdh6boDdtnOGnRS0V00zH
 NbkDdMa2HxNrHyeym7aY3yl8u2CjCY9u95MPSF2tP3KzdKneriMf+n3aRvDcuL8B+51umwjyCQ4
 PkLfg197GmTBl4TLrSPBI1tsEJ43/LjKUjpWrIuq7N9V55TiJ8oXVQU++8MfQuN5CxgpAhoiR5t
 bcvc+Hup+gU7OUbrGwAI0+Y2ydK9Zf/KrPBJLIVC+XvbjL8KULTVpk7GYQeejaBlaQfK4Xn1G3Y
 nmh0sGLTNIq7FQlIkWOw7R0xHiQuXO2iJb2aOzYN7/PkLmB4ayhOQjMxf9kNzb/dEuVOZzQ04wo
 C3mHsMCScHznwjqnhp9FVkWBLSe4mUjSYVM7+TZB22qRAmkcgoQeoH7A4LFcB59Zmb/PJxO/Msx
 lH0Tq+bU7+UuWNx8E6COQcBQ6IJFwuoRjBrGL+nBNzSzP+P94NQ6s1NvhrDBKn6GxLkL1bWDy/m
 JScZEu9klnyXrChzl9BcE+Wvw1O/euoK9IeMTMiKbhDYb9QlBzKHiGkJ4YLYeFRxcTDl6Cyjn6j
 Dl6Mj8m6uQxtNhobkxrxZ3YaFSHTdPi0Mj1wkrT3ibSFY62aLmO5VlkLzZ4/KcpYxLP1CKLXTjP
 GtGUtV4z6JBxWaQ==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

1Hz as used previously was way too long.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index ce039bd701c2..b92b5f7b2bd7 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -287,7 +287,7 @@ bm818_codec: sound-wwan-codec {
 
 	vibrator {
 		compatible = "pwm-vibrator";
-		pwms = <&pwm1 0 1000000000 0>;
+		pwms = <&pwm1 0 50000 0>;
 		pwm-names = "enable";
 		vcc-supply = <&reg_vdd_3v3>;
 	};

-- 
2.52.0

