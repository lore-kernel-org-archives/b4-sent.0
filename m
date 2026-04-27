From: Alexandre MINETTE <contact@alex-min.fr>
Date: Mon, 27 Apr 2026 21:34:53 +0200
Subject: [PATCH v2 7/8] ARM: dts: qcom: pm8921: Add USB ID extcon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-mainline-send-v1-sending-v2-7-dcaa9178007b@alex-min.fr>
References: <20260427-mainline-send-v1-sending-v2-0-dcaa9178007b@alex-min.fr>
In-Reply-To: <20260427-mainline-send-v1-sending-v2-0-dcaa9178007b@alex-min.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777318488; l=903;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=Gn6Eztd/7RPnADkDDebRSs2mfCn3XMgtJiOIqNDSy/U=;
 b=0789+vbLD3zGGtqh4rM6+kxfuzK7OcAqvzOgfsoTItyYED9NqJvizjeA6cta8pbP2CgURPoFM
 NHtdpUqKBrlCagJutgKiJOWz1BbAPRxCF7Wd3KCJp8hFSR8mZOiUjY5
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

