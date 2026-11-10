From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:19:34 +0000
Subject: [PATCH 2/3] arm64: dts: rockchip: add the SPI NOR flash supply on
 Orange Pi 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-opi5-dts-v1-2-582b63d074be@gmail.com>
References: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
In-Reply-To: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295172; l=1366;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=mzXbVS79UzYXahnmbISsnP+6U3ALGoRgMaY2cMlZvTQ=;
 b=+FPgB3ZEYjghW5Ml7ddBaHziBdOTRwx38KffnN1n/XyQYZlugjsRp1Tn8qSkcS7LlTNMbG5D3
 sHX9GaaMPVFCq2uVbkcq5X5/X9aktgYP87pGOcMpRcawR8IDn+HxX9g
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SPI NOR flash on the Orange Pi 5 has no vcc-supply, so spi-nor
falls back to a dummy regulator:

  spi-nor spi5.0: supply vcc not found, using dummy regulator

The flash reports JEDEC ID 20 41 18, an XMC XM25QU128C, which is a
1.8 V part, and it is wired to FSPI M0, whose pins (GPIO2_A0,
GPIO2_D0-D6) are in the 1.8 V eMMC I/O domain. That domain and the
serial flash are fed from VCC_1V8_S3 (RK806 BUCK10), as in Rockchip's
RK3588 reference design; it is also the rail other RK3588 boards with a
1.8 V flash use (e.g. NanoPC-T6).

Describe the supply. The rail is always-on, so nothing changes
functionally; the flash just gets its real supply instead of a dummy
one. Only the Orange Pi 5 enables the flash: on the 5B and 5 Pro the
FSPI M0 pins are used by the eMMC.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts
index d76bdf1b5e90..d67c876c8013 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dts
@@ -33,4 +33,8 @@ &pcie2x1l2 {
 
 &sfc {
 	status = "okay";
+
+	flash@0 {
+		vcc-supply = <&vcc_1v8_s3>;
+	};
 };

-- 
2.55.0

