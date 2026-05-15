From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 15 May 2026 17:40:33 -0400
Subject: [PATCH 2/6] ARM: dts: imx: remove redundant bus-width for
 video-mux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-imx25_dts_simple_warning_2-v1-2-b06bff192a05@nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778881235; l=6988;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=lsqAi27NmpHk2hV97xNohJAnacVRFQ+MMLjYxzPWZII=;
 b=AHjVm4kP5ZBOwXAvyxgR1y3F1numoUiNMtCVDVF44m8Uwv2IPBvF/EUr72fiCcFdgBNjZ5XoF
 XiJUvRuwFQOA81ff2FysicwFU/v1pUWvCG/7ThNK/7DhisZ3aOpX9zn
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove redundant bus-width property according to video-mux.yaml to fix
below CHECK_DTBS warnings:
arch/arm/boot/dts/nxp/imx/imx6dl-gw51xx.dtb: ipu1_csi0_mux (video-mux): port@4:endpoint: Unevaluated properties are not allowed ('bus-width' was unexpected)
        from schema $id: http://devicetree.org/schemas/media/video-mux.yaml

The bus-width already set at remote endpoint (camera).

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/imx/imx6dl-gw52xx.dts      | 2 --
 arch/arm/boot/dts/nxp/imx/imx6dl-gw53xx.dts      | 2 --
 arch/arm/boot/dts/nxp/imx/imx6dl-gw54xx.dts      | 2 --
 arch/arm/boot/dts/nxp/imx/imx6q-gw52xx.dts       | 2 --
 arch/arm/boot/dts/nxp/imx/imx6q-gw53xx.dts       | 2 --
 arch/arm/boot/dts/nxp/imx/imx6q-gw54xx.dts       | 4 ----
 arch/arm/boot/dts/nxp/imx/imx6qdl-gw51xx.dtsi    | 2 --
 arch/arm/boot/dts/nxp/imx/imx6qdl-gw551x.dtsi    | 2 --
 arch/arm/boot/dts/nxp/imx/imx6qdl-gw553x.dtsi    | 2 --
 arch/arm/boot/dts/nxp/imx/imx6qdl-sabreauto.dtsi | 2 --
 10 files changed, 22 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/imx/imx6dl-gw52xx.dts b/arch/arm/boot/dts/nxp/imx/imx6dl-gw52xx.dts
index 9ea23dd54f3ce0d8e3abad2c2ced7798a2854489..62b05fe70cd97b16553b65371ee8efb77168d61b 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6dl-gw52xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6dl-gw52xx.dts
@@ -32,12 +32,10 @@ adv7180_to_ipu1_csi1_mux: endpoint {
 };
 
 &ipu1_csi1_from_ipu1_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6dl-gw53xx.dts b/arch/arm/boot/dts/nxp/imx/imx6dl-gw53xx.dts
index 182e8194c2490b520aa065e11933795aaa6d7a71..c1787510d3941d77ca1e9f76560d2e57852bf995 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6dl-gw53xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6dl-gw53xx.dts
@@ -32,12 +32,10 @@ adv7180_to_ipu1_csi1_mux: endpoint {
 };
 
 &ipu1_csi1_from_ipu1_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6dl-gw54xx.dts b/arch/arm/boot/dts/nxp/imx/imx6dl-gw54xx.dts
index a106c4e3e32995f4fe7801f04ce549dd50283c85..934b0325e6f5acffd72f8063bf7d9e5de02b1093 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6dl-gw54xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6dl-gw54xx.dts
@@ -32,12 +32,10 @@ adv7180_to_ipu1_csi1_mux: endpoint {
 };
 
 &ipu1_csi1_from_ipu1_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6q-gw52xx.dts b/arch/arm/boot/dts/nxp/imx/imx6q-gw52xx.dts
index 6e1c493c9c8c49343313a71f0c72570915a311cd..31996ddde117acbe50166da8fbe6a6290a895211 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6q-gw52xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6q-gw52xx.dts
@@ -32,12 +32,10 @@ adv7180_to_ipu2_csi1_mux: endpoint {
 };
 
 &ipu2_csi1_from_ipu2_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu2_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu2_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu2_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6q-gw53xx.dts b/arch/arm/boot/dts/nxp/imx/imx6q-gw53xx.dts
index f13df8e9c8c4b213d4371d93ef6e4a19e969dcd6..f224273fa863ecbc41e14df1f0324b5ef4192a9e 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6q-gw53xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6q-gw53xx.dts
@@ -32,12 +32,10 @@ adv7180_to_ipu2_csi1_mux: endpoint {
 };
 
 &ipu2_csi1_from_ipu2_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu2_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu2_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu2_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6q-gw54xx.dts b/arch/arm/boot/dts/nxp/imx/imx6q-gw54xx.dts
index d5d46908cf6ed8f15ec03584146d7af5b2d9d72d..804ee044be52d716a6e6cfb97b8aa4520d3b9baa 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6q-gw54xx.dts
+++ b/arch/arm/boot/dts/nxp/imx/imx6q-gw54xx.dts
@@ -90,12 +90,10 @@ tda1997x_to_ipu1_csi0_mux: endpoint {
 };
 
 &ipu1_csi0_from_ipu1_csi0_mux {
-	bus-width = <16>;
 };
 
 &ipu1_csi0_mux_from_parallel_sensor {
 	remote-endpoint = <&tda1997x_to_ipu1_csi0_mux>;
-	bus-width = <16>;
 };
 
 &ipu1_csi0 {
@@ -104,12 +102,10 @@ &ipu1_csi0 {
 };
 
 &ipu2_csi1_from_ipu2_csi1_mux {
-	bus-width = <8>;
 };
 
 &ipu2_csi1_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu2_csi1_mux>;
-	bus-width = <8>;
 };
 
 &ipu2_csi1 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw51xx.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw51xx.dtsi
index beff5a0f58ab48d4d7b8f14f9e695763dc2e3bdf..fb18b87adb441e4e11ddab602c3e3a8e302fa81c 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw51xx.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw51xx.dtsi
@@ -384,12 +384,10 @@ adv7180_to_ipu1_csi0_mux: endpoint {
 };
 
 &ipu1_csi0_from_ipu1_csi0_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi0_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi0_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi0 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw551x.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw551x.dtsi
index 6136a95b9259977bd2debb05e2a480cd1e2fb765..55647c1dacfa5d26c386ebf490c50ef825b99e94 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw551x.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw551x.dtsi
@@ -440,12 +440,10 @@ tda1997x_to_ipu1_csi0_mux: endpoint {
 };
 
 &ipu1_csi0_from_ipu1_csi0_mux {
-	bus-width = <16>;
 };
 
 &ipu1_csi0_mux_from_parallel_sensor {
 	remote-endpoint = <&tda1997x_to_ipu1_csi0_mux>;
-	bus-width = <16>;
 };
 
 &ipu1_csi0 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw553x.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw553x.dtsi
index 552114a69f5b9575a3685fcbbae11a7fc2673e45..bdbcad5e35d8258353831f211776e4fd8c2e684d 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-gw553x.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-gw553x.dtsi
@@ -397,12 +397,10 @@ adv7180_to_ipu1_csi0_mux: endpoint {
 };
 
 &ipu1_csi0_from_ipu1_csi0_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi0_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi0_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi0 {
diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-sabreauto.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-sabreauto.dtsi
index b9dde0af3b995feb49fef38fb0fda69eee3a5750..40d8887cb8bc7f3ce1948fbeadbde6c0d4d1ff0c 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-sabreauto.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-sabreauto.dtsi
@@ -245,12 +245,10 @@ accelerometer@1c {
 };
 
 &ipu1_csi0_from_ipu1_csi0_mux {
-	bus-width = <8>;
 };
 
 &ipu1_csi0_mux_from_parallel_sensor {
 	remote-endpoint = <&adv7180_to_ipu1_csi0_mux>;
-	bus-width = <8>;
 };
 
 &ipu1_csi0 {

-- 
2.43.0

