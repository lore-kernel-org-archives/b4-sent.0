From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 12 Nov 2026 16:00:25 +0530
Subject: [PATCH] arm64: dts: qcom: hamoa: Move the PCIe and UART graph
 nodes to the board DTs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261112-hamoa-dt-fix-v1-1-55efbac840f4@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Mj3YzE3PxE3ZQS3bTMCt3kNMPUFHOLFNPkFFMloJaColSgMNi46Fg
 Iv7g0KSs1uQRkhlJtLQAsnzSWcAAAAA==
X-Change-ID: 20261112-hamoa-dt-fix-cf1ed78d5cd5
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wei Deng <wei.deng@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3438;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=iCfDZaL8nz6DHQyS69tVEpDrn39W3So5QT0E2mCMxdo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq9ZVFyu6UOClUClpU70LbBWy61mYBJlM9dAtMI
 esfIXKYx12JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCavWVRQAKCRBVnxHm/pHO
 9ejrCACm5a7HRjI1e4yu4369/mzDsID7D5YIhQL3rvcD5tEdkqPS1ZNUSzg/k3wWNzgylJs7B7/
 DdiCX6LIQaDIYnD8b8PKGVnWFYJ+DMfBuZPPRpmuBkLseC14epmUCMtPApVC/bGL1V/36w3H+/d
 39+Ke6dxtKgH4KqS9k/Z6rzIKObv6aIr7EeI3zHjHpuJUP+6HTrSVJYS9lUz1ClFN5UihpAwk0i
 Re/srQZyNsctb1jzyqYQfcP4uzid6+uK9rMZkMY9Pxwp3yyNNQcGdyhfZPMje8qE2ZPNTb4SLGG
 DT2KFOayvvAkJ6olkAr/hURjp93HstKnS45UFupGEnbU+YHn
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hamoa.dtsi describes an empty port/endpoint pair under the pcie4 Root Port
and another one under uart14 node. Both belong to the M.2 Key E connector
and only the Hamoa and Purwa IoT EVKs ever wire them up. Every other board
including hamoa.dtsi inherits two dead nodes they never connect.

Apart from the dead nodes, the change also confuses the pwrctrl driver.

So drop both pairs from the SoC dtsi and describe them in the two board
DTs, next to the connector they belong to.

Fixes: 014501d141ed ("arm64: dts: qcom: hamoa: Add graph port/endpoint anchors to pcie4_port0 and uart14")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts | 16 ++++++++++------
 arch/arm64/boot/dts/qcom/hamoa.dtsi        | 10 ----------
 arch/arm64/boot/dts/qcom/purwa-iot-evk.dts | 16 ++++++++++------
 3 files changed, 20 insertions(+), 22 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts b/arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts
index d0433cc3623f..dd6920461323 100644
--- a/arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts
+++ b/arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts
@@ -1033,10 +1033,12 @@ &pcie3_port0 {
 &pcie4_port0 {
 	reset-gpios = <&tlmm 146 GPIO_ACTIVE_LOW>;
 	wake-gpios = <&tlmm 148 GPIO_ACTIVE_LOW>;
-};
 
-&pcie4_port0_ep {
-	remote-endpoint = <&m2_e_pcie_ep>;
+	port {
+		pcie4_port0_ep: endpoint {
+			remote-endpoint = <&m2_e_pcie_ep>;
+		};
+	};
 };
 
 &pcie5 {
@@ -1504,10 +1506,12 @@ wcn_usb_sw_n: wcn-usb-sw-n-state {
 
 &uart14 {
 	status = "okay";
-};
 
-&uart14_ep {
-	remote-endpoint = <&m2_e_uart_ep>;
+	port {
+		uart14_ep: endpoint {
+			remote-endpoint = <&m2_e_uart_ep>;
+		};
+	};
 };
 
 &uart21 {
diff --git a/arch/arm64/boot/dts/qcom/hamoa.dtsi b/arch/arm64/boot/dts/qcom/hamoa.dtsi
index 48f47aa6ba3c..3f773b1409aa 100644
--- a/arch/arm64/boot/dts/qcom/hamoa.dtsi
+++ b/arch/arm64/boot/dts/qcom/hamoa.dtsi
@@ -2032,11 +2032,6 @@ &clk_virt SLAVE_QUP_CORE_1 QCOM_ICC_TAG_ALWAYS>,
 				pinctrl-names = "default";
 
 				status = "disabled";
-
-				port {
-					uart14_ep: endpoint {
-					};
-				};
 			};
 
 			i2c15: i2c@a9c000 {
@@ -3813,11 +3808,6 @@ pcie4_port0: pcie@0 {
 				#address-cells = <3>;
 				#size-cells = <2>;
 				ranges;
-
-				port {
-					pcie4_port0_ep: endpoint {
-					};
-				};
 			};
 		};
 
diff --git a/arch/arm64/boot/dts/qcom/purwa-iot-evk.dts b/arch/arm64/boot/dts/qcom/purwa-iot-evk.dts
index a811d8ca2dbf..5600c5523421 100644
--- a/arch/arm64/boot/dts/qcom/purwa-iot-evk.dts
+++ b/arch/arm64/boot/dts/qcom/purwa-iot-evk.dts
@@ -1016,10 +1016,12 @@ &pcie3_port0 {
 &pcie4_port0 {
 	reset-gpios = <&tlmm 146 GPIO_ACTIVE_LOW>;
 	wake-gpios = <&tlmm 148 GPIO_ACTIVE_LOW>;
-};
 
-&pcie4_port0_ep {
-	remote-endpoint = <&m2_e_pcie_ep>;
+	port {
+		pcie4_port0_ep: endpoint {
+			remote-endpoint = <&m2_e_pcie_ep>;
+		};
+	};
 };
 
 &pcie5 {
@@ -1524,10 +1526,12 @@ wcn_usb_sw_n: wcn-usb-sw-n-state {
 
 &uart14 {
 	status = "okay";
-};
 
-&uart14_ep {
-	remote-endpoint = <&m2_e_uart_ep>;
+	port {
+		uart14_ep: endpoint {
+			remote-endpoint = <&m2_e_uart_ep>;
+		};
+	};
 };
 
 &uart21 {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-hamoa-dt-fix-cf1ed78d5cd5

Best regards,
--  
மணிவண்ணன் சதாசிவம்

