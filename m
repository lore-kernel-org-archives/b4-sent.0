From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 15:10:17 +0100
Subject: [PATCH v2 2/3] arm64: dts: qcom: sc8180x: add IMEM node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sc8180x-dts-ipa-v2-2-e919ed1643c1@gmail.com>
References: <20261126-sc8180x-dts-ipa-v2-0-e919ed1643c1@gmail.com>
In-Reply-To: <20261126-sc8180x-dts-ipa-v2-0-e919ed1643c1@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795702215; l=1181;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=rDI8dY7d2yAfqJnRnUuDpYfbnBT2kMndnLO0zvD8B3Q=;
 b=jQr9IKkUH8ADF2LBEVmig2kTt3UH3oHL3CXoxmXm/oGn9xJeqYxkCt1ejIHfPOviCM74Uh3oJ
 M7M1kpwSZfUCRGyNBo8WFLDRLyNdlANNFpob4xkR1xsTEaYZI5aEwWI
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SC8180X IMEM SRAM node (sram@14680000) and describe the 8 KiB
IPA modem tables region (0x146bd000) as a child slice so IPA can map
it via the devicetree sram phandle.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8180x.dtsi | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8180x.dtsi b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
index be79608b7161a0786463fe93e22798080ebba93c..7865054a3fafb85e34daa31b985e3c66f8d7e03f 100644
--- a/arch/arm64/boot/dts/qcom/sc8180x.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
@@ -3623,6 +3623,21 @@ spmi_bus: spmi@c440000 {
 			#interrupt-cells = <4>;
 		};
 
+		sram@14680000 {
+			compatible = "qcom,sc8180x-imem", "mmio-sram";
+			reg = <0x0 0x14680000 0x0 0x40000>;
+			ranges = <0x0 0x0 0x14680000 0x40000>;
+
+			no-memory-wc;
+
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			ipa_modem_tables: modem-tables-sram@3d000 {
+				reg = <0x3d000 0x2000>;
+			};
+		};
+
 		apps_smmu: iommu@15000000 {
 			compatible = "qcom,sc8180x-smmu-500", "arm,mmu-500";
 			reg = <0 0x15000000 0 0x100000>;

-- 
2.47.3

