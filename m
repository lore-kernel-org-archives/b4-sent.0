From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Thu, 03 Sep 2026 23:23:22 +0200
Subject: [PATCH v6 10/12] arm64: dts: rockchip: rk3588s-nanopi-r6: add
 comment about gmac phy-mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-nanopi-m6-v6-10-37416bbd6862@gmail.com>
References: <20260903-nanopi-m6-v6-0-37416bbd6862@gmail.com>
In-Reply-To: <20260903-nanopi-m6-v6-0-37416bbd6862@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, diederik@cknow-tech.com, 
 jonas@kwiboo.se, Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788470612; l=906;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=W9OP4Riybt39A0bIhFgCbk7q5TKSgnKTP3QXL026djI=;
 b=X45i6lJzWBlp05s9gXNgNlJHSk81RhKn4xfFxbtHowlF0C+EJYmAjTu1xmXHl8Z4gueHvOV1R
 KQE5Kx651A5Arhzsguy3h3Y+76G0f5ZpC3KxgFNPY5eKfTqeG1k/v4e
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
index 5a42e7dadc92..94f218a48078 100644
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

