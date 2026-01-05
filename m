From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:39:43 +0100
Subject: [PATCH 6/6] arm64: dts: imx8mq-librem5: Don't set mic-cfg for
 wm8962
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-l5-dtb-fixes-v1-6-f491881a7fe7@puri.sm>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=847;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=iFYwHw0xgQRdhe+3vnkoxkuFJ0xjTKuaUaWtu79bHaw=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGhzVlyX3SOiwl0zjSkdqxo5SJDUEfUGn+Yx
 cg4R3ha+9SJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoQAKCRDo8jXPO9vD
 /xOLD/9WUc6hoI0nps0Y5JE1FvDpvYojnUw7HY8XWbPpo0MCODdQzM7mFlqnoJCcRwezi11j2SR
 atDjtGdYpFlyVhU+erBM+5kwCoQulFI/+wb0Gu/qIsUJaOkAvHZ5e+xjMo6EBg4E74K7PuQn4A7
 J7+E9xo9Hl07CNGhcs5xQ9QqdoaYs+/3z5VIrKA2DK3fXXEs32VXoN9vohnAhM6G1B26edOWMIw
 9BPHoLtX0x/m0FsniLRUsCLtuyLI7YGNgIqP0xjnBO5eiqDYQn0RvwD1GM1CfL6xBF+P/JlEIOZ
 Lj/COX0MjnTXSuPr5OSBjJ5cKWbQZsSGRjy8ZjA3JY25PmSvD5pWfiiKiNCRuST+bBHe/7X2lfa
 EHmaB17AOBnQe3VngkSZztCwzcTbRrbN0fage/BfdKfuSKAQ4lQoBOT9IGUtIGebdrwlzwivFsA
 9ejJ7g8+98PJeu8o2zsSsOVg7AcrAdpDZmFxp4zMpmMs6ravcMAIHQWAnt34V9C+z76w4YsNSDa
 vfCkOGe5huJXv/Co1zedudRe4npKTANU9+38stpyDbSSpVRsP9nl1q6p+5xfRcma0w4kIUduH0U
 i3j+1kIK1SjJGYTmNKucPVu7kAXqP1mvBuY1JYpN+F1rhI1CsKG0jDbARViuowdSOm8QDxE5Roz
 AjqXxh4SWLby+2Q==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The default values are fine, and MICDET_ENA is handled by the driver on
its own anyway.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index 22b1a29ad440..b6f7daebadf2 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -1085,7 +1085,6 @@ codec: audio-codec@1a {
 		assigned-clock-parents = <&clk IMX8MQ_AUDIO_PLL1_OUT>;
 		assigned-clock-rates = <24576000>;
 		#sound-dai-cells = <0>;
-		mic-cfg = <0x200>;
 		DCVDD-supply = <&reg_aud_1v8>;
 		DBVDD-supply = <&reg_aud_1v8>;
 		AVDD-supply = <&reg_aud_1v8>;

-- 
2.52.0

