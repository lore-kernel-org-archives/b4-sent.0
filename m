From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:19:33 +0000
Subject: [PATCH 1/3] arm64: dts: rockchip: use rgmii-id for the Orange Pi
 5/5B ethernet PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-opi5-dts-v1-1-582b63d074be@gmail.com>
References: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
In-Reply-To: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295172; l=1895;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tvDxnxzJS+qXTLT+S+2SEXSC6rLShYZjDQnh9IALLos=;
 b=KKWIzOxcaNMe8ftleSNYT2RAzatFYKNDsM0hJ+ZT9gzxNp9n6GiVSLnuWoGh6GB7QIT2+iaZ5
 WBWjPYSD2T4BbFAIEdJQJaG+N4pYaqM2vVK9II35mxoc0otEw4FLRuy
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Orange Pi 5 and 5B have a Motorcomm YT8531C RGMII PHY on gmac1
(the PHY driver binds as "YT8531 Gigabit Ethernet"). The board neither
uses extra long clock traces for TX nor for RX, yet the device tree
describes it as "rgmii-rxid", which according to ethernet-controller.yaml
means that the PCB provides the TX delay, and then makes the MAC insert
the TX delay with tx_delay = <0x42>. The setting was copied from the
vendor kernel, which uses the MAC delay lines everywhere.

Describe the PCB correctly as "rgmii-id" and drop tx_delay, so that the
MAC adds no delay and the PHY adds both: motorcomm.c programs its
default 1950 ps for RX (as now) and for TX. This is the setup the
binding recommends, and the one the same vendor's Orange Pi CM5
(rk3588s-orangepi-cm5-base.dts), with a YT8531C on gmac1 of the same
SoC, already uses in mainline.

Besides being the correct description, this removes the MAC from the
timing path for both directions, so no board-specific delay-line value
is needed any more.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
index c153e7248727..7c1fd5905553 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
@@ -97,14 +97,13 @@ vcc_3v3_sd_s0: regulator-vcc-3v3-sd-s0 {
 &gmac1 {
 	clock_in_out = "output";
 	phy-handle = <&rgmii_phy1>;
-	phy-mode = "rgmii-rxid";
+	phy-mode = "rgmii-id";
 	pinctrl-0 = <&gmac1_miim
 			&gmac1_tx_bus2
 			&gmac1_rx_bus2
 			&gmac1_rgmii_clk
 			&gmac1_rgmii_bus>;
 	pinctrl-names = "default";
-	tx_delay = <0x42>;
 	status = "okay";
 };
 

-- 
2.55.0

