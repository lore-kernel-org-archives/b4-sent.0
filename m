From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:08 +0200
Subject: [PATCH v5 7/7] arm64: dts: qcom: sdm845-google: Add WCD9340 codec
 and microphone capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-7-7ffb32c980bf@ixit.cz>
References: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
In-Reply-To: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4206; i=david@ixit.cz;
 h=from:subject:message-id; bh=s0JlhQpLgoJtR5H5Po2ltSAeqAV+BYppQyxD+ybwcos=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFVbYMqMj+/OuZZTrhinnHc7nMhI4O7jiIP
 zxYxdrOpzmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 cntlEADRps8DGSpz0v+/fv6UsFJjNbTWF+r8XzuDksSSYpojdDhhtiWb5jcDxzv9ef/XXp6Mt9u
 OAx7bGtqOce0ukUdCcxVG0bYXmCHSZS75Q6TwbrfIu1NRlPYsItrxi43V+Q9Zxhb+1vDx6ji1QF
 2ZDDZrQZaMm6KjiQdN5tzcWDDSFSdr+BLwNzqsYsTLC+dgWLb+SGe2MmlinRtuN0iZ43Cb7Aq6B
 R38I5tRuDFu8xacFyTWSJU/F5D+TqLdzUPLQ9i2tiL63Pp1ZLBgT19DjM4dWGuMN106ijwq6OJ2
 sxeiCr79vHd9PGBM1/m82G+GJ1G3iohrI1H74HDAQpIkXcmC2XpgGwo1mG/xUihTj7sZMybStuV
 odhE1ZWKikmF0G7WK7vTj0MX7ksTgGgRLpGNVQBw2aU4QeaOvLHQujaNQfTAYS/dzC4AFIzWZaO
 GRTWLfxgxROPHWiEysv6NHVGXRXZ7oddMpRqvzlHbAP33mJP0OhIYu82isMnSU4PjbfbkMkI06w
 mYxWGBLOkjaIy/NGAl8Ppqq7ff/XTCTY5FozajZjkILlmkX8J+s1bYI7Ua61MywP6FHrs39R4Ks
 Dux/aDhMomQlB1rDySIgodQ9tTMAiDaBkfjDwPdLQOONTRKp0FSglRMUdA/Drt2GzLj7pFPEboU
 NWWk67TSbk/3Gkg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Pixel 3 sound card so far only drove the two CS35L36 speaker
amplifiers. Wire in the WCD9340 codec , add a SLIMbus capture link
for it and route the three digital microphones

Based on work done by Casey Tunturi.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 58 ++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 68d26c1a06d0c..8e303a91bfaa2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -4,18 +4,20 @@
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 #include <dt-bindings/sound/qcom,q6afe.h>
 #include <dt-bindings/sound/qcom,q6asm.h>
+#include <dt-bindings/sound/qcom,wcd934x.h>
 
 #include "sdm845.dtsi"
+#include "sdm845-wcd9340.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
 /delete-node/ &cdsp_mem;
 /delete-node/ &mba_region;
 /delete-node/ &slpi_mem;
@@ -512,16 +514,20 @@ dai@72 {
 		qcom,tdm-data-align = <0>;
 	};
 };
 
 &q6asmdai {
 	dai@0 {
 		reg = <MSM_FRONTEND_DAI_MULTIMEDIA1>;
 	};
+
+	dai@1 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA2>;
+	};
 };
 
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
@@ -539,40 +545,81 @@ &qup_uart9_tx {
 
 &sound {
 	compatible = "qcom,sdm845-sndcard";
 	model = "Pixel 3";
 	pinctrl-0 = <&quat_mi2s_active>, <&quat_mi2s_sd0_active>,
 		    <&quat_mi2s_sd1_active>;
 	pinctrl-names = "default";
 
+	audio-routing = "DMIC0", "MCLK", /* Top mic */
+			"DMIC0", "MIC BIAS1",
+			"DMIC3", "MCLK", /* Top-edge mic */
+			"DMIC3", "MIC BIAS3",
+			"DMIC4", "MCLK", /* Bottom mic */
+			"DMIC4", "MIC BIAS4";
+
 	/* mm[0-9]-dai-link nodes must be positioned first regardless of sorting */
 	mm1-dai-link {
 		link-name = "MultiMedia1";
 
 		cpu {
 			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA1>;
 		};
 	};
 
+	mm2-dai-link {
+		link-name = "MultiMedia2";
+
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA2>;
+		};
+	};
+
 	cs35l36-dai-link {
 		link-name = "Speaker Playback";
 
 		codec {
 			sound-dai = <&cs35l36_bottom>, <&cs35l36_top>;
 		};
 
 		cpu {
 			sound-dai = <&q6afedai QUATERNARY_TDM_RX_0>;
 		};
 
 		platform {
 			sound-dai = <&q6routing>;
 		};
 	};
+
+	slimcap-dai-link {
+		link-name = "SLIM Capture 1";
+
+		codec {
+			sound-dai = <&wcd9340 AIF1_CAP>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_0_TX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+};
+
+&swm {
+	/*
+	 * Nothing hangs off the codec's SoundWire bus on this board: the
+	 * speakers are CS35L36 amplifiers on QUAT_TDM. With an empty bus the
+	 * controller reports port mismatches and frame-generator timeouts on
+	 * every boot.
+	 */
+	status = "disabled";
 };
 
 &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
 	nfc_default: nfc-default-state {
 		enable-pins {
@@ -718,16 +765,27 @@ &usb_1_qmpphy {
 };
 
 &venus {
 	firmware-name = "qcom/sdm845/Google/blueline/venus.mbn";
 
 	status = "okay";
 };
 
+&wcd9340 {
+	/* PM8998 LN_BB_CLK2 feeds the Pixel Visual Core on this board */
+	clocks = <&rpmhcc RPMH_LN_BB_CLK3>;
+	reset-gpios = <&tlmm 64 GPIO_ACTIVE_HIGH>;
+	vdd-buck-supply = <&vreg_s4a_1p8>;
+	vdd-buck-sido-supply = <&vreg_s4a_1p8>;
+	vdd-tx-supply = <&vreg_s4a_1p8>;
+	vdd-rx-supply = <&vreg_s4a_1p8>;
+	vdd-io-supply = <&vreg_s4a_1p8>;
+};
+
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
 	vdd-1.8-xo-supply = <&vreg_pmu_xo>;
 	vdd-1.3-rfa-supply = <&vreg_pmu_rf>;
 	vdd-3.3-ch0-supply = <&vreg_pmu_ch0>;
 
 	qcom,snoc-host-cap-8bit-quirk;
 

-- 
2.55.0

