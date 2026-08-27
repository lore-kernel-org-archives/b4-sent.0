From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 27 Aug 2026 09:52:49 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sc8280xp-x13s: Add DP0/DP1 audio
 playback support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-x13s-dpaudio-v1-2-da73414c6ab5@oldschoolsolutions.biz>
References: <20260827-x13s-dpaudio-v1-0-da73414c6ab5@oldschoolsolutions.biz>
In-Reply-To: <20260827-x13s-dpaudio-v1-0-da73414c6ab5@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787817176; l=1351;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=7xkjdxOijSp8eM/DKmvoe1hNzfXCqUIYUtM74xYVJGw=;
 b=1iaEPMNaAOFOZtYc0BXthpLHOKrtbjEjgfwWY2HfhD/umsVxNMJpsk9O110OstDMcoPDoW7ag
 uqfjJt2VvVyDbilHT+CVyguKfajGGrdAg4bTc57xytBlpxstQayV9+e
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The X13s sound card has no DAI links for the Type-C DisplayPort
controllers, so those playback paths never show up. Add DP0 and DP1
links using the existing mdss0_dp DAIs and DISPLAY_PORT_RX_{0,1}.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts     | 32 ++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
index 467e14ca21e56..bd4b4cb6245cf 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
@@ -1215,6 +1215,38 @@ &sound {
 		"VA DMIC2", "MIC BIAS3",
 		"TX SWR_ADC1", "ADC2_OUTPUT";
 
+	dp0-dai-link {
+		link-name = "DP0 Playback";
+
+		codec {
+			sound-dai = <&mdss0_dp0>;
+		};
+
+		cpu {
+			sound-dai = <&q6apmbedai DISPLAY_PORT_RX_0>;
+		};
+
+		platform {
+			sound-dai = <&q6apm>;
+		};
+	};
+
+	dp1-dai-link {
+		link-name = "DP1 Playback";
+
+		codec {
+			sound-dai = <&mdss0_dp1>;
+		};
+
+		cpu {
+			sound-dai = <&q6apmbedai DISPLAY_PORT_RX_1>;
+		};
+
+		platform {
+			sound-dai = <&q6apm>;
+		};
+	};
+
 	wcd-playback-dai-link {
 		link-name = "WCD Playback";
 		cpu {

-- 
2.53.0

