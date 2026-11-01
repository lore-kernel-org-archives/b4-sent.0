From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Sun, 01 Nov 2026 23:00:53 +0100
Subject: [PATCH 2/3] arm64: dts: rockchip: rk3588s-nanopi: switch to
 generic eth phy compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-nanopi-m6v2-v1-2-e401ea64b394@gmail.com>
References: <20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com>
In-Reply-To: <20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570476; l=947;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=LlnCbbgiuToElbilUWpX/P/5aagrWhUu+VZZ4pw6CDA=;
 b=6r49hQV1GiJbQRNgRFAS/qwjocmblPV1giqOE2nGW7zep3X7dR33B7QnaJGZLo/P/d+Vye0VA
 NCSSWtlwmbBAhNQNJwAYGj0ICgSkGXI1FJpnp3xDj+EJJztAoUgD5on
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use generic Ethernet phy compatible for all NanoPi 6 boards. This allows
us to easily support the new MotorComm YT8531C phy used on NanoPi M6V2.

Note that the Rockchip vendor DTS has used the generic compatible for a
long time.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index 22b0cdee22b40..4977ccb668f39 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -269,7 +269,7 @@ &i2s5_8ch {
 
 &mdio1 {
 	rgmii_phy1: ethernet-phy@1 {
-		compatible = "ethernet-phy-id001c.c916";
+		compatible = "ethernet-phy-ieee802.3-c22";
 		reg = <0x1>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&rtl8211f_rst>;

-- 
2.56.0

