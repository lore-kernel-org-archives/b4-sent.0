From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:39:41 +0100
Subject: [PATCH 4/6] arm64: dts: imx8mq-librem5: Limit uSDHC2 frequency to
 50MHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-l5-dtb-fixes-v1-4-f491881a7fe7@puri.sm>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1216;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=irl0zhAfm+ZidJ+mS4bm54p88aI15LNArncdYbrSJ70=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGhUa/B36vt29Ky4lgETJGIUeQ0rm65f0UdJ
 asJVvLUtAaJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoQAKCRDo8jXPO9vD
 /2w3EACl0zjF+MMlFtfaFDFk1Y+cQQHLZ22n6aJaMgKrMq+ocfwXWavoV/XvyutYmAPpyAIBBSi
 oSTL9U1qVWzv9v+mnmaO2TRVS/QtVxxlT4Teqg8HdmWEuACgveNenz3IVAef2N/QYIm2Inw49Xs
 Wc7n3mmo+O5OpZ7SMbn2uPbPxtdil6hQUTePXKCqe609IHNzc5/NdI6AX9+Ahm8qXyCY6Zs8Muc
 ljY5uW+A7/FGxKlpdIdQWefVBMzKH/5QayxErwI1dWRIRTsqEZjP02wvBCWBhAXH0XZDYwfVZN7
 2dq69it3T9skgza68vQlmdjz/zKfD1Jsw6+PY1NK2eth/vLAsfTiapq74/MLzIjBezfgtCwoJOi
 vzSosG96x1riMq/cGA/31QtzxoK3FmFoseX7Anjm0N9TQ81darAs4wdJ95fE9ODhhBmlMDI8b+x
 zSaGfmX2alecTymxvsKgtqvi8A49NbRm8HrKbYzMeGmvelGIsKEU8TgY7bq+ewEozHL8aJS4ycB
 4DgZFlwM7zADiU6fy7Oa+DWNv0Ne54+oKUVJmiIpVBax9cfiAsMnTJMh6G1I9ux8yR4gnmCehNK
 TFjnGGwRWgRlBgbg7TRBLqcU8jYr8WxOgm8OCZkEHYMAiI93mwNIrhuumnRzWdpPfRS2cibbnfF
 aKivrdCcZgPhIog==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SparkLAN card has stability issues at 100MHz. It still appears to be
able to max out its throughput this way, so limit the frequency to
ensure stable operation.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index 8c37b1293699..0e3c103dd7ff 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -1424,7 +1424,7 @@ &usdhc1 {
 
 &usdhc2 {
 	assigned-clocks = <&clk IMX8MQ_CLK_USDHC2>;
-	assigned-clock-rates = <200000000>;
+	assigned-clock-rates = <50000000>;
 	pinctrl-names = "default", "state_100mhz", "state_200mhz";
 	pinctrl-0 = <&pinctrl_usdhc2>;
 	pinctrl-1 = <&pinctrl_usdhc2_100mhz>;
@@ -1434,7 +1434,7 @@ &usdhc2 {
 	mmc-pwrseq = <&usdhc2_pwrseq>;
 	post-power-on-delay-ms = <20>;
 	cd-gpios = <&gpio2 12 GPIO_ACTIVE_LOW>;
-	max-frequency = <100000000>;
+	max-frequency = <50000000>;
 	disable-wp;
 	cap-sdio-irq;
 	keep-power-in-suspend;

-- 
2.52.0

