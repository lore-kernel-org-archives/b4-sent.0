From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Aug 2026 15:56:39 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: sdm845-oneplus: Move touchscreen
 y-axis to the right place
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-oneplus-ts-quirk-v1-1-0cdbcea195a2@ixit.cz>
References: <20260819-oneplus-ts-quirk-v1-0-0cdbcea195a2@ixit.cz>
In-Reply-To: <20260819-oneplus-ts-quirk-v1-0-0cdbcea195a2@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcus Ramberg <marcus@means.no>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1678; i=david@ixit.cz;
 h=from:subject:message-id; bh=a26dFcsPpf6CwuMLNOgEu1hKIlbknD00ls5SVdmciH0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhbYXXkV/2Zya80zeMIArO0EKbodiGcYgeC78/
 0SxsvvnQRSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoW2FwAKCRBgAj/E00kg
 coXvD/0V3NLx/uHdrMtUasUnu3nwb7M1koU5+RM41ygBKcHxnMD+9E2dCSaPrOPx7zJC2QjcumE
 kpeuEvDZSrBpxJPmkVvBapisT/RcgT80wqARKmSCYt+agbSEiSuszlKAWqVkUxK3fgYjXJhMBxm
 WF8hIU+t1AiQwa3nD9OUVdWq3bQSrVS3D7GYNbRT+XL+HcgQNH5ACc2vCflG5MZ7WYDB585+qR5
 SHxR+BiPPX4wZRXs+EtIZaBnhurOoPJR8W43qH7lBL5S+CTXI8IW8HyY3I7q/7lXdEJt1Q8SZ1A
 AhsV+RqnqEHsUGkd6sRcOqKy/q9Cu1sLuCGa/blbXQTCfQX3XokJLjOgkHpJDGN5QC3MiM74WZr
 s17DoxU39jrxbBvzb4Bw2KfyDUhKcgV9+frAKmUCf9i/ih7TnYnLAGUUle8KH0T4RByG7oMRt+Z
 /f0liWawjArQTMESk6THnpicWP7bmaeHDUoXAXBr8KvAfg+9kOJVSl2TPKXpENpswaLB2xtSacn
 zJBt3WrQTGrxjLHRJIzIUvwPXO6w3hBtplN3CYzesFSBIkjY5okshtyjH/EbSv9tuD1DYm2MUjE
 KkS2UWDQezDhZucJ3a2M72MG+/ahgxfLAYfBL1Fa9eZZm6h18IOPGnOSuAeAib2fQPqnj3RkZDL
 iBtKEDFydm98Irg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This value belongs only to enchilada, fajita sets it's own (as the width
/ y-axis differs).

No functional change.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 1 -
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 4 ++++
 2 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 439779f308e38..fead66d60e58d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -538,17 +538,16 @@ synaptics-rmi4-i2c@20 {
 		rmi4-f01@1 {
 			reg = <0x01>;
 			syna,nosleep-mode = <1>;
 		};
 
 		rmi4_f12: rmi4-f12@12 {
 			reg = <0x12>;
 			touchscreen-x-mm = <68>;
-			touchscreen-y-mm = <144>;
 			syna,sensor-type = <1>;
 			syna,rezero-wait-ms = <200>;
 		};
 	};
 };
 
 &ipa {
 	firmware-name = "qcom/sdm845/OnePlus/enchilada/ipa_fws.mbn";
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index 3b30d79706fe7..be346286e19b3 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -90,16 +90,20 @@ led@4 {
 
 		led@5 {
 			reg = <5>;
 			color = <LED_COLOR_ID_RED>;
 		};
 	};
 };
 
+&rmi4_f12 {
+	touchscreen-y-mm = <144>;
+};
+
 &sound {
 	model = "OnePlus 6";
 	audio-routing = "RX_BIAS", "MCLK",
 			"AMIC2", "MIC BIAS2",
 			"AMIC3", "MIC BIAS4",
 			"AMIC4", "MIC BIAS1",
 			"AMIC5", "MIC BIAS4";
 };

-- 
2.55.0

