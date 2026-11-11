From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 07:19:50 +0000
Subject: [PATCH v2 2/3] arm64: dts: rockchip: add the SPI NOR flash supply
 on Orange Pi 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-opi5-dts-v2-2-821f666418a6@gmail.com>
References: <20261111-opi5-dts-v2-0-821f666418a6@gmail.com>
In-Reply-To: <20261111-opi5-dts-v2-0-821f666418a6@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794381589; l=1541;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=9AwdsnGfZOnrDAgXOfqgNderVhk3/vp9FG3EwftKGrU=;
 b=RhOdbp4OjjH909fs+0CrOvJW2bTfSGyvtpLiF19yu7WiUnQ8cYh+GNImj0oVekqQKA3GE9lUE
 u4j/fgevyICCYYIA4NMuLetlWruPnqxKVWCo2WNbX4zeJH+ZiO5riG5
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

Describe the supply on the flash node in rk3588s-orangepi-5.dtsi, where
the node and the regulator are defined. The rail is always-on, so
nothing changes functionally; the flash just gets its real supply
instead of a dummy one. Only the Orange Pi 5 enables the flash: on the
5B and 5 Pro the FSPI M0 pins are used by the eMMC and the controller
stays disabled.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtsi
index 2db6ee95e504..c7d892e4f961 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5.dtsi
@@ -302,6 +302,7 @@ flash@0 {
 		spi-max-frequency = <100000000>;
 		spi-rx-bus-width = <4>;
 		spi-tx-bus-width = <1>;
+		vcc-supply = <&vcc_1v8_s3>;
 	};
 };
 

-- 
2.55.0

