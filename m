From: Janne Grunau <j@jannau.net>
Date: Wed, 11 Jun 2025 22:30:31 +0200
Subject: [PATCH] arm64: dts: apple: t8103: Fix PCIe BCM4377 nodename
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-arm64_dts_apple_wifi-v1-1-fb959d8e1eb4@jannau.net>
X-B4-Tracking: v=1; b=H4sIAGbnSWgC/x3MTQqAIBBA4avErBMaM4OuEiGSUw30IxoVhHdPW
 n6L916IFJgidMULgS6OfOwZWBYwLnafSbDLBlnJptKIwoZNK+POaKz3K5mbJxZOYSNRtbImDTn
 1gSZ+/m0/pPQBKqY7WGYAAAA=
X-Change-ID: 20250611-arm64_dts_apple_wifi-d415214723e6
To: Sven Peter <sven@kernel.org>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mark Kettenis <kettenis@openbsd.org>, 
 Marc Zyngier <maz@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1444; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=wHLTjbA+ZQtpL0eNy1zcPArF/Oix96dlxYfH46ebBpY=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgzP51kRH8Mu3v4jEB23riR0deCkgE6+c2cMvr65PcVSe
 0ccb9X0jlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABMJ2MzIcLts4jqju75O01+L
 W7AzLZr3XaNW7reybOvtzn/v4/9UeDP8D1O7tNy9eNnCJpMtf/9daq65scqR77nMzOoP0rJxOVf
 4GQE=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following `make dtbs_check` warnings for all t8103 based devices:

arch/arm64/boot/dts/apple/t8103-j274.dtb: network@0,0: $nodename:0: 'network@0,0' does not match '^wifi(@.*)?$'
        from schema $id: http://devicetree.org/schemas/net/wireless/brcm,bcm4329-fmac.yaml#
arch/arm64/boot/dts/apple/t8103-j274.dtb: network@0,0: Unevaluated properties are not allowed ('local-mac-address' was unexpected)
        from schema $id: http://devicetree.org/schemas/net/wireless/brcm,bcm4329-fmac.yaml#

Fixes: bf2c05b619ff ("arm64: dts: apple: t8103: Expose PCI node for the WiFi MAC address")
Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
index 8e82231acab59ca0bffdcecfb6681f59661fcd96..0c8206156bfefda8a32c869787b2e0c8e67a9d17 100644
--- a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
@@ -71,7 +71,7 @@ hpm1: usb-pd@3f {
  */
 &port00 {
 	bus-range = <1 1>;
-	wifi0: network@0,0 {
+	wifi0: wifi@0,0 {
 		compatible = "pci14e4,4425";
 		reg = <0x10000 0x0 0x0 0x0 0x0>;
 		/* To be filled by the loader */

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250611-arm64_dts_apple_wifi-d415214723e6

Best regards,
-- 
Janne Grunau <j@jannau.net>

