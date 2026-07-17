From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Fri, 17 Jul 2026 09:23:08 +0200
Subject: [PATCH v4 10/12] arm64: dts: rockchip: rk3588s-nanopi-r6: add
 comment to gmac phy-mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-nanopi-m6-v4-10-b31391a72e41@gmail.com>
References: <20260717-nanopi-m6-v4-0-b31391a72e41@gmail.com>
In-Reply-To: <20260717-nanopi-m6-v4-0-b31391a72e41@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784272993; l=906;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=QZV8naTWO4Z+iXnYHi+nrsqgVGR4DEKSmwg8FlaLRgw=;
 b=tYfTv2yqkLDSCkvEfKNfqWf4ODEA0oGLjxqwQ3om+1OaOzCTUsXFk+DHDoF59UnrYdmlmQ+Q8
 M9u7GalHOMSCHe8lioqgjjBQeeGGoEfEr+UbJsnpKzP7bJ8iKTiU0Y5
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add comment to explain rgmii-rxid phy-mode usage. Note that the actual
delay in ns is not known. The tx_delay value of 0x42 comes from vendor
DT.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
index 309cac8902db..b33e7b15d05e 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
@@ -199,7 +199,7 @@ &cpu_l3 {
 &gmac1 {
 	clock_in_out = "output";
 	phy-handle = <&rgmii_phy1>;
-	phy-mode = "rgmii-rxid";
+	phy-mode = "rgmii-rxid"; /* Vendor provided tx delay value below */
 	phy-supply = <&vcc_3v3_s3>;
 	pinctrl-0 = <&gmac1_miim
 		     &gmac1_tx_bus2

-- 
2.55.0

