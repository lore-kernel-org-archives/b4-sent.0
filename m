From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Fri, 17 Jul 2026 09:23:06 +0200
Subject: [PATCH v4 08/12] arm64: dts: rockchip: rk3588s-nanopi-r6: add
 gmac1 add phy-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-nanopi-m6-v4-8-b31391a72e41@gmail.com>
References: <20260717-nanopi-m6-v4-0-b31391a72e41@gmail.com>
In-Reply-To: <20260717-nanopi-m6-v4-0-b31391a72e41@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784272993; l=746;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=cbMRGCjK0cqeVUY3RIsYZSs7mBZYvBiBTtHs1FmJ/94=;
 b=ZnRgRgisL/g9rcTeSEO7p9vVAGRpab0QuLj3vnVlT/BTHqHnEd9GZQT7kr0ClemfbYKctbbtb
 pWgo/2thcMFC90774z5QIB1fhKjLSwwRN22ESyUN0RNxVVQ9R7aPOxf
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTL8211F Ethernet phy is powered from the VCC_3V3_S3 rail.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
index 30e09352bbe9..97a495eab7d5 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi
@@ -210,6 +210,7 @@ &gmac1 {
 	clock_in_out = "output";
 	phy-handle = <&rgmii_phy1>;
 	phy-mode = "rgmii-rxid";
+	phy-supply = <&vcc_3v3_s3>;
 	pinctrl-0 = <&gmac1_miim
 		     &gmac1_tx_bus2
 		     &gmac1_rx_bus2

-- 
2.55.0

