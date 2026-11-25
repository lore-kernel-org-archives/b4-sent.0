From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 25 Nov 2026 11:17:44 +0100
Subject: [PATCH 4/4] arm64: dts: qcom: glymur: Describe the PCIe thermal
 inputs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-glymur-thermal-fix-v1-4-b93a9feae156@oss.qualcomm.com>
References: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
In-Reply-To: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1696;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ZJdaduTk3N5k77RqvSkUVPMcjS8LQRuYo7/mT0mao2c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBrBrXO5rubwpqmuuItaW3qXKpFo5HiwqgL6+ptk
 IkZdZLlTqGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCawa1zgAKCRBVnxHm/pHO
 9eSWB/4mX+m4XO+3doi+juA7wBm7jYpXi/ZFjYA2dwhmvZp68hEvoKfRr+VYh1vx49Z4PILNRGJ
 sk6yrl0ZMS2HTAkHTk50HdDfgv4VBlP8fkW/RL6UZ7+RQEDdPVyZVRX1+8Nfcx0w7adPvWUPkMF
 q+boqD0phfuaQ6batSIHc5kbfZWDk35IXbazb7X9pod9NMJlEXkjpoOceop6tBilpIx+4vU6YPR
 MOHW+UMsyGohCMztc9KneVI8fdJ7MWsvSLFrCOOdeOEVMSz3UnXha7VicKmRefqTm4H5DM49ujn
 bloHGZFB7j0c3h/OynCKzFGcgeM2EikuPBoCgEr/j4lQT90H
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PCIe PHY instances on Glymur benefit from periodic recalibration to
compensate for temperature-related drift and maintain stable link
operation. The controller driver triggers the recalibration with a link
speed switch once the temperature change on a polled sensor exceeds the
defined threshold, but for that it needs to know which sensors track the
PHY temperature and the drift temperature.

So add a property to identify the relevant temperature sensors,
'qcom,pcie-recalibration-thermal-zones', to PCIe domain 5 pointing at the
aoss-6 zone and to PCIe domain 7 pointing at the nsphmx-0 zone, as those
are the zones whose sensors track the respective PHY temperature. Both
zones are allowed a drift temperature of 25 degC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/glymur.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/glymur.dtsi b/arch/arm64/boot/dts/qcom/glymur.dtsi
index 65a398c0a992..6fb254abf81a 100644
--- a/arch/arm64/boot/dts/qcom/glymur.dtsi
+++ b/arch/arm64/boot/dts/qcom/glymur.dtsi
@@ -3127,6 +3127,8 @@ pcie5: pcie@1b40000 {
 
 			operating-points-v2 = <&pcie5_opp_table>;
 
+			qcom,pcie-recalibration-thermal-zones = <&thermal_aoss_6 25000>;
+
 			msi-map = <0x0 &gic_its 0xd0000 0x10000>;
 			iommu-map = <0x0 &pcie_smmu 0x50000 0x10000>;
 
@@ -3615,6 +3617,8 @@ pcie3b: pcie@1b80000 {
 
 			operating-points-v2 = <&pcie3b_opp_table>;
 
+			qcom,pcie-recalibration-thermal-zones = <&thermal_nsphmx_0 25000>;
+
 			msi-map = <0x0 &gic_its 0xf0000 0x10000>;
 			iommu-map = <0x0 &pcie_smmu 0x70000 0x10000>;
 

-- 
2.43.0

