From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 14 Mar 2024 15:24:35 +0300
Subject: [PATCH] arm64: dts: rockchip: set PHY address of MT7531 switch to
 0x1f
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240314-for-rockchip-mt7531-phy-address-v1-1-743b5873358f@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAILs8mUC/x3NwQrCMAyA4VcZORtYu07FVxEPtU1sENeSDFHG3
 t3i8bv8/wZGKmRwGTZQeotJXTrcYYBU4vIglNwNfvRhnFxAropa0zMVafhaT/PksJUvxpyVzPA
 ej8kzczjPDL3SlFg+/8P1tu8/dVn8KXEAAAA=
To: Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710419077; l=1281;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=M6V6hLjoM7rYDNZJdf1WFKDQWTTCt8rVO23htitTxhE=;
 b=2C08ammmunglRmpdQwiQIKW95QKlBhYoQev+0BRPUVhkzTQFI6N+micHOVYOIUijFf9m8Nq5H
 HOqI2PamNGKAh9GUhP/ia6vPJ89x+92kMEyCixwO2Hq4svAgbQeGko7
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7531 switch listens on PHY address 0x1f on an MDIO bus. I've got two
findings that support this. There's no bootstrapping option to change the
PHY address of the switch. The Linux driver hardcodes 0x1f as the PHY
address of the switch. So the reg property on the device tree is currently
ignored by the Linux driver.

Therefore, describe the correct PHY address on Banana Pi BPI-R2 Pro that
has this switch.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
index 7b5f3904ef61..03d6d920446a 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
@@ -525,9 +525,9 @@ &mdio0 {
 	#address-cells = <1>;
 	#size-cells = <0>;
 
-	switch@0 {
+	switch@1f {
 		compatible = "mediatek,mt7531";
-		reg = <0>;
+		reg = <0x1f>;
 
 		ports {
 			#address-cells = <1>;

---
base-commit: 0276d797531ea2d1865a04fbe54c659608f5788f
change-id: 20240314-for-rockchip-mt7531-phy-address-ba6c2fff485f

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

