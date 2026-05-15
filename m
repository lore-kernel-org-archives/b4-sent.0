From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 15 May 2026 17:40:34 -0400
Subject: [PATCH 3/6] ARM: dts: imx: Add bus-type for ov5642/ov5640
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-imx25_dts_simple_warning_2-v1-3-b06bff192a05@nxp.com>
References: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
In-Reply-To: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778881235; l=1774;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=HGMs+AFWVIG/7Db0qb4OWvzhAHmrd9vKYw4rG4RNH/M=;
 b=BrOivWXgIRm6WZZQFShvH95LUpQF7Ss1xcHT4UfO/710V+1sIlkj1h/Wd+IZPa2kE/HFX76hq
 udFGBEuy6jEB5qPuPvkaMk0/k8QHcioEeOjEOLfl+n3gl4ScLOt0j3x
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bus-type (MEDIA_BUS_TYPE_PARALLEL) for ov5642/ov5640. i.MX53 and
i.MX6UL only supports parallel csi interface. Fix below CHECK_DTBS
warnings:
  arm/boot/dts/nxp/imx/imx53-smd.dtb: ov5642@3c (ovti,ov5642): port:endpoint: 'bus-type' is a required property

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/imx/imx53-smd.dts         | 2 ++
 arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtsi | 1 +
 2 files changed, 3 insertions(+)

diff --git a/arch/arm/boot/dts/nxp/imx/imx53-smd.dts b/arch/arm/boot/dts/nxp/imx/imx53-smd.dts
index a1e19f9709b2c7c7d02812f2b5c2afd382fb5d86..8c02731c7ba9db794627e085feb8a4e957d8c5c3 100644
--- a/arch/arm/boot/dts/nxp/imx/imx53-smd.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx53-smd.dts
@@ -5,6 +5,7 @@
 
 /dts-v1/;
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/media/video-interfaces.h>
 #include "imx53.dtsi"
 
 / {
@@ -314,6 +315,7 @@ camera: ov5642@3c {
 		port {
 			ov5642_to_ipu_csi0: endpoint {
 				remote-endpoint = <&ipu_csi0_from_parallel_sensor>;
+				bus-type = <MEDIA_BUS_TYPE_PARALLEL>;
 				bus-width = <8>;
 				hsync-active = <1>;
 				vsync-active = <1>;
diff --git a/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtsi b/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtsi
index 3d147b160ecf150f2f3b6afa8b5873fabc2ba96f..32afe4130e21126bf6e476db1091c4a45b8cf5bc 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6ul-14x14-evk.dtsi
@@ -217,6 +217,7 @@ camera@3c {
 		port {
 			ov5640_to_parallel: endpoint {
 				remote-endpoint = <&parallel_from_ov5640>;
+				bus-type = <MEDIA_BUS_TYPE_PARALLEL>;
 				bus-width = <8>;
 				data-shift = <2>; /* lines 9:2 are used */
 				hsync-active = <0>;

-- 
2.43.0

