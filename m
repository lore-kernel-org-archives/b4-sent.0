From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 18 Nov 2026 22:45:30 +0100
Subject: [PATCH 3/4] arm64: dts: rockchip: use i2c-gpio for hdmi ddc on
 rk3588-h96-max-v58
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-dw-hdmi-qp-bridge_attach-v1-3-e370920bc7f3@gmail.com>
References: <20261118-dw-hdmi-qp-bridge_attach-v1-0-e370920bc7f3@gmail.com>
In-Reply-To: <20261118-dw-hdmi-qp-bridge_attach-v1-0-e370920bc7f3@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexey Charkov <alchark@gmail.com>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Nicolas Frattaroli <nicolas.frattaroli@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795038370; l=2059;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=ZKHrf9fZfya43GZzxlgu/vfQ6CugSi9lV4hIpaRZsLU=;
 b=uyr04LBj1Nkn02R5XunZ6iLLnYc3emIzJl0246OwELe6DeMlNxzvY5CUUxs7ZSy600h8hBtt9
 xRJbf1vdC2qDiR9dNIaXCijrlEPVUkyd/ClCCn1XF0OPfwPmuEaSwKB
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On-chip DDC controller is unreliable on this board so override DDC on
the HDMI connector with i2c-gpio. The root cause of breakage is not
known but on-chip DDC controller refuses to read the EDID.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 .../arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts b/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
index 3811f9a73bb6c..da6282c105255 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
@@ -37,6 +37,7 @@ chosen {
 
 	hdmi0-con {
 		compatible = "hdmi-connector";
+		ddc-i2c-bus = <&i2c_gpio_ddc>;
 		type = "a";
 
 		port {
@@ -46,6 +47,16 @@ hdmi0_con_in: endpoint {
 		};
 	};
 
+	/* on-chip DDC controller is unreliable on this board */
+	i2c_gpio_ddc: i2c-ddc {
+		compatible = "i2c-gpio";
+		pinctrl-names = "default";
+		pinctrl-0 = <&i2c_ddc_scl &i2c_ddc_sda>;
+		scl-gpios = <&gpio4 RK_PB7 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		sda-gpios = <&gpio4 RK_PC0 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		i2c-gpio,delay-us = <5>;
+	};
+
 	ir-receiver {
 		compatible = "gpio-ir-receiver";
 		gpios = <&gpio0 RK_PD4 GPIO_ACTIVE_LOW>;
@@ -211,8 +222,7 @@ &gpu {
 
 &hdmi0 {
 	frl-enable-gpios = <&gpio4 RK_PB1 GPIO_ACTIVE_LOW>;
-	pinctrl-0 = <&hdmim0_tx0_cec &hdmim0_tx0_hpd
-		     &hdmim0_tx0_scl &hdmim0_tx0_sda &hdmi0_tx_on_h>;
+	pinctrl-0 = <&hdmim0_tx0_cec &hdmim0_tx0_hpd &hdmi0_tx_on_h>;
 	pinctrl-names = "default";
 	status = "okay";
 };
@@ -347,6 +357,14 @@ hdmi {
 		hdmi0_tx_on_h: hdmi0-tx-on-h {
 			rockchip,pins = <4 RK_PB1 RK_FUNC_GPIO &pcfg_pull_none>;
 		};
+
+		i2c_ddc_scl: i2c-ddc-scl {
+			rockchip,pins = <4 RK_PB7 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		i2c_ddc_sda: i2c-ddc-sda {
+			rockchip,pins = <4 RK_PC0 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
 	};
 
 	hym8563 {

-- 
2.56.0

