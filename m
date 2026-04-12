From: David Heidelberg <david@ixit.cz>
Date: Sun, 12 Apr 2026 18:35:37 +0200
Subject: [PATCH v3 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260412-pixel3-camera-v3-2-e26b090a6110@ixit.cz>
References: <20260412-pixel3-camera-v3-0-e26b090a6110@ixit.cz>
In-Reply-To: <20260412-pixel3-camera-v3-0-e26b090a6110@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1445; i=david@ixit.cz;
 h=from:subject:message-id; bh=7WqIva9DadD3+mE9XaAACC/Zf/TxomU1o2iRVVPNDnE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp28nYNrbKrzoa5xsx6fbxZcVifQuIoxyLbLirx
 pOgU0xEEhOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadvJ2AAKCRBgAj/E00kg
 cmOJEACyFZ69DC7UXyxsYpnMuY1nIm1/9c8/mYNEDQ1AkBJKmfFRIZgIYkv3TShdAwkL2uHwehi
 M16tUxEqjIE36S3tVTd0G1aWsIOxo4wNPuyM9Br0mHldpVPj9eLBu5zl8DS5IRHtfGfBHP/GSFa
 Mwe9K4XpHf4jBLtxE4LuhHLdF4Sr8OSvGp91iCbpIleVQKnm7TwjY9kmi8kQl7ZTJ0b28EpRNl6
 sK0nHuhyozWK6OM+wv8WsM9K7gLJwzdMasdNA8+9UDGRYK07LsOQessFluVsfwTyvkLdWI0OErf
 dQ20knknHluMRW8I07k8ksa2Ssw3BPn5idX1VChcpKKsbmWFtVkEH1QFHmrrDnY+Q3w1f1Vtvys
 DMdw3oCOjg17Y0oXq0YHKSo+cfgC5BTdm/hX+mzvmZrMBkR5P0PketaPi60DhTjrDIzDQsP6YTt
 hCE99NKTAcXo3bSKznBu7QOK8YJ8IFN3/ZsLKqG77zvyDB1lBzRiagwMFHfG5ZSjmv+qGq44SLl
 iZGNvWWGKakOw0OHvtsCJlLT1zzGJEmg2W0y2uT1/Pg34vXFkWc0wGBNBwSlNhiik5QJh4nRVtJ
 zTXcqumg9hpSIMcnOAAJMC8zbKO9tW6DzxX/+KTbOZoFXzStC1IBFbXSTcoCwx1uV199yxKgtbT
 Y4AweDRGP7KdAKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 flash LED block and describe the white flash LED
used for the rear camera.

Configure the LED in flash mode with hardware limits matching the
original device configuration, including maximum current and timeout.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 070023a9813ce..e9d9842cb8674 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -6,6 +6,7 @@
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
@@ -596,6 +597,19 @@ &pmi8998_charger {
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	led-1 {
+		function = LED_FUNCTION_FLASH;
+		color = <LED_COLOR_ID_WHITE>;
+		led-sources = <2>;
+		led-max-microamp = <500000>;
+		flash-max-microamp = <750000>;
+		flash-max-timeout-us = <1280000>;
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };

-- 
2.53.0

