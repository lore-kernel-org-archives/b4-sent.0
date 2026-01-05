From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:39:42 +0100
Subject: [PATCH 5/6] arm64: dts: imx8mq-librem5: Set cap-power-off-card for
 usdhc2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-l5-dtb-fixes-v1-5-f491881a7fe7@puri.sm>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=751;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=3FmSteF4kPJyYTm0fb0Nk+/Wxx/y4JRs2j8lvXT5ndg=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGhv1BbnzOMrNgXf2F2pqaDZuF2imhh/5Gfo
 HC/cycG2waJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoQAKCRDo8jXPO9vD
 /9ckEACMLR31FW9Rh+tgbacz/tzzqFw90zuYdeYeu0//kRl5pLccTfrBRioSptiQxRI3NbBgUN+
 6eq6rD/MZoFwEV+ReR1VTjiB4gh4+nNcE0uXyFsCsU8qgdw5NQKPgTUm4FviecoKvLS1jpIjmzG
 PqDj/P8y7kujaU06lHxA9YjZzHxDnl05hYc6ry3YQI/cLmPMEDpL7Su7e/X/M1AU3GP7dNPBGZJ
 nDbOZ8VQ227IfaJn7n/ktdWWTdWQS6WWYWaeSA0NgqCOxAtKoQlJU414nbgpwwNQDIWTmi13pl5
 Hc9Rn0iHaVGedwvrlxb6GoR2yELakDpe5Ma/atvRmxnnG1E4kBzMYEb1JWtx6IzcXWwcjJyHNvR
 V1tCDvnuJIT7ir68qCkFA7qwFTrPZlN1raoSAOQOoDbuDcbHROO0M94vVjhrmMlbmqh7BdlJkju
 xWgMngrIgB8cB/3bFyhjOimNrSt2tGqDZ9bnbvIfBH9H/HE3qS54pK9nqz2Ip6lSDXMG+8M+QY8
 PogIo9dIkgqvuY0omhWoKwDKtJSybKlZhXzycB7Z6RBghUDtSeXEWTYJLjNOBVdemKv2/+4ofdS
 LZ0XQXRl1MKNS7EFmT6ERJG6/vg/bV7Fwnt43WHfkKFtzyQ0tw2G+tqhPtE2VNvg8GFogE//pL+
 +hSsDVq1CISEuyA==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is needed for brcmfmac to turn the card off in suspend
since 8c3170628a9ce24a59647bd24f897e666af919b8.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index 0e3c103dd7ff..22b1a29ad440 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -1437,6 +1437,7 @@ &usdhc2 {
 	max-frequency = <50000000>;
 	disable-wp;
 	cap-sdio-irq;
+	cap-power-off-card;
 	keep-power-in-suspend;
 	wakeup-source;
 	status = "okay";

-- 
2.52.0

