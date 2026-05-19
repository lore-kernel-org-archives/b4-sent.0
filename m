From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 19 May 2026 09:16:37 +0200
Subject: [PATCH v3 7/8] ARM: dts: qcom: pm8921: Add USB ID extcon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-mainline-send-v1-sending-v3-7-3dd7aa125353@alex-min.fr>
References: <20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr>
In-Reply-To: <20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr>
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
 iommu@lists.linux.dev, phone-devel@vger.kernel.org, 
 Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779174999; l=1141;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=7LFsLsEUiYEeh3bW/vbTHCTwzetxBuEF5Bgg6PKOt0I=;
 b=yCJ9eifEYu/jios1gp2u4NSu25jxUULeTqywdYHiosDCBM7LTZDJkiHGBM79I0YtLqq2beTgt
 v9okRz/c/mkCU3PbN4EyuYOaE8TnKH1tNG4E18/PoZYAxkFXHLcN9sZ
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PM8921 exposes the USB ID signal through the PMIC interrupt controller as
USB_ID_IN. Add an extcon child for this interrupt so USB controllers can
consume it for role detection.

Unlike PM8941, the PM8921 USB ID interrupt path has no known register
resource. The downstream PM8xxx misc device is also instantiated without
one, and the mainline extcon driver only consumes the named USB ID
interrupt. Keep the node non-addressable and describe only the interrupt.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 arch/arm/boot/dts/qcom/pm8921.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/pm8921.dtsi b/arch/arm/boot/dts/qcom/pm8921.dtsi
index 535cb6a2543f..30366536f580 100644
--- a/arch/arm/boot/dts/qcom/pm8921.dtsi
+++ b/arch/arm/boot/dts/qcom/pm8921.dtsi
@@ -121,6 +121,13 @@ ref_muxoff: adc-channel@f {
 				reg = <0x00 0x0f>;
 			};
 		};
+
+		usb_id: usb-detect {
+			compatible = "qcom,pm8921-misc";
+			interrupt-names = "usb_id";
+			interrupts-extended = <&pm8921 49 IRQ_TYPE_EDGE_BOTH>;
+			status = "disabled";
+		};
 	};
 };
 

-- 
2.43.0

