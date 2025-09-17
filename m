From: Michael Riesch <michael.riesch@collabora.com>
Date: Wed, 17 Sep 2025 17:38:56 +0200
Subject: [PATCH v11 16/17] arm64: dts: rockchip: add mipi csi-2 receiver
 node to rk356x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-rk3568-vicap-v11-16-af0eada54e5d@collabora.com>
References: <20240220-rk3568-vicap-v11-0-af0eada54e5d@collabora.com>
In-Reply-To: <20240220-rk3568-vicap-v11-0-af0eada54e5d@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Thomas Petazzoni <thomas.petazzoni@bootlin.com>, 
 Gerald Loacker <gerald.loacker@wolfvision.net>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Markus Elfring <Markus.Elfring@web.de>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Alexander Shiyan <eagle.alexander923@gmail.com>, 
 Val Packett <val@packett.cool>, Rob Herring <robh@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758123529; l=1644;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=mp3pf9RuqEGrye/HxgD+x+5GeyykIBGgvJ6m8tMl1hs=;
 b=Dp0dy1jjVh7QZr9Viym/ViFATmbF25T6MXpeYbETF3q+CsmM9Rpr2ss+NarQHxpOR6IDguezc
 04RcRQ4mXVtCsWQUYRNxBEh3yYbr3sHQC8MxZ6hcPj036OpaYXv+weF
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device tree node for the RK356x MIPI CSI-2 Receiver.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/boot/dts/rockchip/rk356x-base.dtsi | 34 +++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi b/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
index e0e4dc85a3a9..4c3dbcabd834 100644
--- a/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
@@ -564,6 +564,36 @@ gpu: gpu@fde60000 {
 		status = "disabled";
 	};
 
+	csi: csi@fdfb0000 {
+		compatible = "rockchip,rk3568-mipi-csi";
+		reg = <0x0 0xfdfb0000 0x0 0x10000>;
+		interrupts = <GIC_SPI 8 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 9 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "irq1", "irq2";
+		clocks = <&cru PCLK_CSI2HOST1>;
+		phys = <&csi_dphy>;
+		power-domains = <&power RK3568_PD_VI>;
+		resets = <&cru SRST_P_CSI2HOST1>;
+		status = "disabled";
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			csi_in: port@0 {
+				reg = <0>;
+			};
+
+			csi_out: port@1 {
+				reg = <1>;
+
+				csi_output: endpoint {
+					remote-endpoint = <&vicap_mipi_input>;
+				};
+			};
+		};
+	};
+
 	vicap: video-capture@fdfe0000 {
 		compatible = "rockchip,rk3568-vicap";
 		reg = <0x0 0xfdfe0000 0x0 0x200>;
@@ -592,6 +622,10 @@ vicap_dvp: port@0 {
 
 			vicap_mipi: port@1 {
 				reg = <1>;
+
+				vicap_mipi_input: endpoint {
+					remote-endpoint = <&csi_output>;
+				};
 			};
 		};
 	};

-- 
2.39.5

