From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 21 Apr 2026 11:45:13 +0200
Subject: [PATCH 7/8] ARM: dts: qcom: pm8921: Add USB ID extcon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260421-mainline-send-v1-sending-v1-7-bcb0857724de@alex-min.fr>
References: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
In-Reply-To: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 iommu@lists.linux.dev, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776764711; l=952;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=FvTFZEThbXRu0uHZzqdt1WJa7o3nJrMB1bwxpbqanvE=;
 b=5NhOvPBczl2AAI2Xr7ELaj2yqlM0OrBP6Ix7L3xNccD1muns4qrExAm8Rw3KQ8EADd9Yd82YQ
 U4+LkDFLXDTBH3vxi3heZczB3fb/HRw6Q6ke5Aj4QA3sd04zzvK3eWZ
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PM8921 USB ID interrupt as a disabled extcon provider. Boards
can enable it when their USB controller consumes the PMIC USB ID state
for OTG role detection.

The interrupt corresponds to PM8921 USB_ID_IN, block 6 bit 1.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 arch/arm/boot/dts/qcom/pm8921.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/pm8921.dtsi b/arch/arm/boot/dts/qcom/pm8921.dtsi
index 535cb6a2543f..935383d6a594 100644
--- a/arch/arm/boot/dts/qcom/pm8921.dtsi
+++ b/arch/arm/boot/dts/qcom/pm8921.dtsi
@@ -41,6 +41,13 @@ rtc@11d {
 			allow-set-time;
 		};
 
+		usb_id: usb-detect {
+			compatible = "qcom,pm8921-misc";
+			interrupt-names = "usb_id";
+			interrupts-extended = <&pm8921 49 IRQ_TYPE_EDGE_BOTH>;
+			status = "disabled";
+		};
+
 		pm8921_keypad: keypad@148 {
 			compatible = "qcom,pm8921-keypad";
 			reg = <0x148>;

-- 
2.43.0

