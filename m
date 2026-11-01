From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Sun, 01 Nov 2026 22:55:24 +0100
Subject: [PATCH v2 6/9] arm64: dts: rockchip: rk3588s-nanopi: rename usb
 host power pin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-nanopi-m6-improvements-v2-6-a24769efda23@gmail.com>
References: <20261101-nanopi-m6-improvements-v2-0-a24769efda23@gmail.com>
In-Reply-To: <20261101-nanopi-m6-improvements-v2-0-a24769efda23@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570136; l=1219;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=CflUJdIxsWjoqVlMu/6/MIyqLpRBfOQA+mPJNxxQcPE=;
 b=KjeqjJSow57CVCI8aelfifw5cndUKU7bXvhqttUKf+NoTCbNEUQZ3RSESyXKIFyR/aO9CeAQS
 +MX1CrhBOwcCXrx0BDICFCzG8wV0kAQ5MVAc+SAN7m38mh86sVPxlFw
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

usb_host_pwren matches the signal name in the schematics, which
simplifies cross-referencing. In M6/M6V2 this pin was renamed to
usb20_host_pwren.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index 1d37862edb5b5..56264ff3b409d 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -79,7 +79,7 @@ vcc5v0_host_20: regulator-vcc5v0-host-20 {
 		enable-active-high;
 		gpios = <&gpio4 RK_PB5 GPIO_ACTIVE_HIGH>;
 		pinctrl-names = "default";
-		pinctrl-0 = <&vcc5v0_host20_en>;
+		pinctrl-0 = <&usb_host_pwren>;
 		regulator-name = "vcc5v0_host_20";
 		regulator-min-microvolt = <5000000>;
 		regulator-max-microvolt = <5000000>;
@@ -340,7 +340,7 @@ sdmmc_pwren: sdmmc-pwren {
 	};
 
 	usb {
-		vcc5v0_host20_en: vcc5v0-host20-en {
+		usb_host_pwren: usb-host-pwren { /* usb20_host_pwren on M6 */
 			rockchip,pins = <4 RK_PB5 RK_FUNC_GPIO &pcfg_pull_none>;
 		};
 	};

-- 
2.56.0

