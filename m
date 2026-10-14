From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 14 Oct 2026 18:33:07 +0200
Subject: [PATCH 7/9] arm64: dts: rockchip: rk3588s-nanopi: rename gmac1
 reset pin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nanopi-m6-improvements-v1-7-e713f71eb4d3@gmail.com>
References: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
In-Reply-To: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791995685; l=1121;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=WtATwbQABKVY4tLFdbXIynQTMB75uVl3gBt3XPQsrKw=;
 b=y5mvhJ2yoRh9AD4k14R+VjYXo4zI6vfesUROGPLsbB5nNirUtfticeo6qcZRum1dT8Lbf9Cps
 X1qZH/93LJRCbvzaavWw3KVxuumgRToZ1bZH5cCVH+lRv2lxvB3h+6I
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gmac1_rstn matches the signal name in the schematics, which simplifies
cross-referencing.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index 56264ff3b409..2789c3d9bcc4 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -274,7 +274,7 @@ rgmii_phy1: ethernet-phy@1 {
 		compatible = "ethernet-phy-id001c.c916";
 		reg = <0x1>;
 		pinctrl-names = "default";
-		pinctrl-0 = <&rtl8211f_rst>;
+		pinctrl-0 = <&gmac1_rstn>;
 		reset-assert-us = <20000>;
 		reset-deassert-us = <100000>;
 		reset-gpios = <&gpio3 RK_PB7 GPIO_ACTIVE_LOW>;
@@ -346,7 +346,7 @@ usb_host_pwren: usb-host-pwren { /* usb20_host_pwren on M6 */
 	};
 
 	rtl8211f {
-		rtl8211f_rst: rtl8211f-rst {
+		gmac1_rstn: gmac1-rstn {
 			rockchip,pins = <3 RK_PB7 RK_FUNC_GPIO &pcfg_pull_none>;
 		};
 	};

-- 
2.56.0

