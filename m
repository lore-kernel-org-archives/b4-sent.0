From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Sun, 11 Oct 2026 20:17:21 +0300
Subject: [PATCH 1/2] arm64: dts: meson-gxbb-odroidc2: read the Ethernet MAC
 address from eFuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-odroidc2-dts-v1-1-f9f0e779af88@gmail.com>
References: <20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com>
In-Reply-To: <20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791739040; l=1170;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=R7e0aTjiNftlxIP1/5F0ydA79ruy5B9DDk0CJljLEms=;
 b=iPE8SJB5MzWCe9Yh8R9RdzmL5sAZ4DtJAaiPDPSw+ODkKm1rsEkElCljy4/M8OICurkyL48Fm
 OSJvRcEW4l5Ax8wYS0r2P5Q738SAIGM+GStXrz5erHBuJ8mpjN1BnAv
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vendor programs a unique factory MAC address into the SoC eFuse at
offset 0x34, which is exactly the eth_mac nvmem cell that meson-gx.dtsi
already describes.  Reference the cell from the Ethernet controller so
the kernel picks up the factory address itself instead of depending on
the bootloader to populate local-mac-address, or falling back to a
random one when it does not.

Verified on an ODROID-C2 booted with a mainline U-Boot that does not
set ethaddr: the interface comes up with the factory MAC address.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
index 5943bc810..639b97ad5 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
@@ -230,6 +230,9 @@ &ethmac {
 	phy-handle = <&eth_phy0>;
 	phy-mode = "rgmii";
 
+	nvmem-cells = <&eth_mac>;
+	nvmem-cell-names = "mac-address";
+
 	amlogic,tx-delay-ns = <2>;
 
 	mdio {

-- 
2.53.0

