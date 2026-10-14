From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 14 Oct 2026 18:33:09 +0200
Subject: [PATCH 9/9] arm64: dts: rockchip: rk3588s-nanopi-m6: rename pcie2
 power rail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nanopi-m6-improvements-v1-9-e713f71eb4d3@gmail.com>
References: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
In-Reply-To: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791995685; l=1347;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=sa5+w9akUhc5UnYTeKWIOEz5rjtnoSRpmbzGcB+u7yU=;
 b=S9y6ZtmyOvHQtvQQ3RbtPmpquB7+uHS1JIHD0tDq1fzByb33nuRGpCC0nLBIpHPgHT7gRSFlw
 ZK6IvbFglwhCPJUDKZ/dwkjDGARX5g1LfxqTfkoYkjluFxMTCoAC9ar
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vcc3v3_pcie matches the signal name in the schematics, which simplifies
cross-referencing.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
index ca115d8e108a..dd61c61fe7d7 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi
@@ -36,13 +36,13 @@ user_led: led-1 {
 		};
 	};
 
-	vcc_3v3_pcie: regulator-vcc-3v3-pcie {
+	vcc3v3_pcie: regulator-vcc3v3-pcie {
 		compatible = "regulator-fixed";
 		enable-active-high;
 		gpios = <&gpio3 RK_PC6 GPIO_ACTIVE_HIGH>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&pcie20x1_2_con_pwren>;
-		regulator-name = "vcc_3v3_pcie";
+		regulator-name = "vcc3v3_pcie";
 		regulator-min-microvolt = <3300000>;
 		regulator-max-microvolt = <3300000>;
 		vin-supply = <&vcc5v0_sys>;
@@ -95,7 +95,7 @@ &pcie2x1l1 { /* M.2 E-key 2230 */
 
 &pcie2x1l2 { /* M.2 M-key 2280 */
 	pinctrl-0 = <&pcie20x1_2_perstn_m0>, <&pcie20x1m0_clkreqn>, <&pcie20x1m0_waken>;
-	vpcie3v3-supply = <&vcc_3v3_pcie>;
+	vpcie3v3-supply = <&vcc3v3_pcie>;
 };
 
 &pinctrl {

-- 
2.56.0

