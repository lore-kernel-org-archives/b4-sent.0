From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:56 +0530
Subject: [PATCH 14/14] arm64: dts: qcom: sm8450: Add 'global' interrupt to
 the PCIe RC node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-14-5f3765cc873a@linaro.org>
References: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
In-Reply-To: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2237;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=gNxsaYyTdguve7w+Y8w7ph9rzM45Fb14SQIqKjXqzUk=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYkibGlsd3Gj04rNd09RrIryyaw6cU5eY9bfz5ialA+ovz
 lRdvH2LvZPRmIWBkYtBVkyRJX2ps1ajx+kbSyLUp8MMYmUCmcLAxSkAFznC/r+ePWP2j8B7p3wk
 PzIz1LC/Xi9r7d5W8cTtt2fkowOvbjN+ff98NePf7fbPls/k+8bYGCtsMOXYshu6sl+L0wrCvKz
 CVG0/KYVFhkgdLWXf5iERxvt2mYXe3INmfCVFwlNiL4otsYuvNvVdWZb47/JGB0d+4dJt7QtiTv
 qq2yjdWWrsFOZvGSJ3+nHM9nQL78+dJwp0+7vLL093z/e3mKJ645ri0qnny4JLJtp8dZgwkVudf
 b7MvNrPl6oPVFyctifC3e9agEpIQVPeYzHfyLCyGt8vt39X8rqfVT92ZKczy5KyF6fT6+eZnllz
 fdd8y5sPYtz0Szx/9d8tOLLKtJY1P8er33DezpkeHbPbAQ==
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qcom PCIe RC controllers are capable of generating 'global' SPI interrupt
to the host CPUs. This interrupt can be used by the device driver to
identify events such as PCIe link specific events, safety events, etc...

Hence, add it to the PCIe RC node along with the existing MSI interrupts.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/sm8450.dtsi | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450.dtsi b/arch/arm64/boot/dts/qcom/sm8450.dtsi
index 9bafb3b350ff..90d16cb83669 100644
--- a/arch/arm64/boot/dts/qcom/sm8450.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450.dtsi
@@ -1780,7 +1780,8 @@ pcie0: pcie@1c00000 {
 			msi-map = <0x0 &gic_its 0x5980 0x1>,
 				  <0x100 &gic_its 0x5981 0x1>;
 			msi-map-mask = <0xff00>;
-			interrupts = <GIC_SPI 141 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 141 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 142 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 143 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 144 IRQ_TYPE_LEVEL_HIGH>,
@@ -1788,7 +1789,8 @@ pcie0: pcie@1c00000 {
 				     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "msi0",
+			interrupt-names = "global",
+					  "msi0",
 					  "msi1",
 					  "msi2",
 					  "msi3",
@@ -1942,7 +1944,8 @@ pcie1: pcie@1c08000 {
 			msi-map = <0x0 &gic_its 0x5a00 0x1>,
 				  <0x100 &gic_its 0x5a01 0x1>;
 			msi-map-mask = <0xff00>;
-			interrupts = <GIC_SPI 307 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts = <GIC_SPI 306 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 307 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 308 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 309 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 312 IRQ_TYPE_LEVEL_HIGH>,
@@ -1950,7 +1953,8 @@ pcie1: pcie@1c08000 {
 				     <GIC_SPI 314 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 374 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "msi0",
+			interrupt-names = "global",
+					  "msi0",
 					  "msi1",
 					  "msi2",
 					  "msi3",

-- 
2.25.1

