From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Thu, 12 Nov 2026 19:34:56 +0100
Subject: [PATCH] arm64: dts: rockchip: fix pcie wlan chip on
 rk3588-h96-max-v58
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-fix-h96-max-v58-wlan-v1-1-7e918fc85b88@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBCF4auQWTsJMwKhXsW4KGUKY7SaVoGEc
 HeqLL/kvX+FJFElwaVYIcqkSV8hg04FuNGGQVD7bOCSGyJi7Cr0uuBoGnzaBae6xflhA3LNZ1e
 RL43xkN/vKHn3L19vh9O3u4v7/HKwbTvC0Tj4ewAAAA==
X-Change-ID: 20261112-b4-fix-h96-max-v58-wlan-2523c41f099f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Alexey Charkov <alchark@gmail.com>, Alexey Charkov <alchark@flipper.net>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794508523; l=1890;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=ls/b1TaJr55nJIaXg9urdpu9Pz+PccgRCIwOKYKwuzY=;
 b=l3ZyBULPRW1p+jSeI4lEhokzzAiNlGuxxpGKDusbTYb0Khn8w05MIb1mv2VuShv1r2Qr/5UqA
 XsVJy3jpg9VD1L3xa/Jbje78bpPdpYYqcqj3eWgWgyF4IUDfsxeiUUZ
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct the gpio used for regulator-3v3-pcie. This pin was found digging
through the vendor dts. Also add the this regulator to the pcie port so
it will actually be enabled.

After this fix the BCM43752 shows up in lspci and WiFi works with the
correct firmware.
0002:21:00.0 Network controller: BCM43752 802.11ax Dual Band Wireless LAN Controller (rev 02)

Fixes: b53864811b35 ("arm64: dts: rockchip: Add H96 Max V58 TV Box based on RK3588 SoC")
Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts b/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
index 3811f9a73bb6c..e869f7ecf93ce 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts
@@ -79,7 +79,7 @@ vcc_1v1_nldo_s3: regulator-1v1 {
 	pcie_3v3: regulator-3v3-pcie {
 		compatible = "regulator-fixed";
 		enable-active-high;
-		gpios = <&gpio4 RK_PA1 GPIO_ACTIVE_HIGH>;
+		gpios = <&gpio3 RK_PD5 GPIO_ACTIVE_HIGH>;
 		pinctrl-0 = <&pcie2_0_pow>;
 		pinctrl-names = "default";
 		regulator-name = "pcie_3v3";
@@ -319,6 +319,7 @@ &pcie2x1l0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&pcie2_0_rst>;
 	reset-gpios = <&gpio4 RK_PA5 GPIO_ACTIVE_HIGH>;
+	vpcie3v3-supply = <&pcie_3v3>;
 	status = "okay";
 
 	pcie@0,0 {
@@ -373,7 +374,7 @@ pcie2_0_rst: pcie2-0-rst {
 		};
 
 		pcie2_0_pow: pcie2-0-pow {
-			rockchip,pins = <4 RK_PA1 RK_FUNC_GPIO &pcfg_pull_none>;
+			rockchip,pins = <3 RK_PD5 RK_FUNC_GPIO &pcfg_pull_none>;
 		};
 	};
 

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-b4-fix-h96-max-v58-wlan-2523c41f099f

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

