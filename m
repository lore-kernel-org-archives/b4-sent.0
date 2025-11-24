From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:37 +0100
Subject: [PATCH RFC 4/8] arm64: dts: qcom: pm660: Add fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-4-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=889; i=david@ixit.cz;
 h=from:subject:message-id; bh=Oehd4AB8jVMo0BM0kTNmlPXaU9PB0xpePJ4WKe1viNY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPgIuRTPoGf/YpDS0NtfGU0NfB4vzFgHeiCl
 kqK2+FlNR2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 cvyeEACBX6kgWzktd3wBY99dGZqC7osuD5Wg2AiGpJRcnNwSaQTQonaHdhzPFzf4TtuABXY+87s
 YrQzr+S2gZioisyz7ppEo9usGCi+zvsZx6hxMHTfst5/jHcX9OhY5KbNnXdlzLRcwmeJcJ1Wb2w
 TZeEk9PAMW/+730BKlpyvN0QnA3nOYqMlQSlS2y6F1vr2k/tV9o+3I25OUV/XPEtw+KC/5H68z1
 y6wtapPz97VeKBbgFgqTrxyjBnyaN82X2CI6yDPJ/p7ny2lNLUJeRtNk2OU/WCwmKHz69JaxbJ0
 YGJc6iiJFzGPBVIiZwAhHXwI1AZ4pyKQ/2erQKcjb5H5RQMaebVYPy4EIkk37uuybRBapAzs0z1
 mIQIT05vG1pgKcrzX5Rv88/dFHl1XUfFRJ+NKWQSuuQSRrcNpX6kn9mMpmZ1T68TO5QUnAikFM0
 p9dU2pPNYhmEEH2Ogg+sCHaVz5feAmylgwolATlXzMDxFBqzaBXVHAv8psAZR2IkkJ6u3I1VUi8
 wkmB6os8ufY9ANh0qgLoLrIMd9cVFWkSiohKjBzXy2xs/rXCiHJ+ynnBBtT0S/yx1Pr635JXgb0
 qTqnrNHGizhfOasey+avZmNQ8YZ1P8j21AUIF+jc/1HyDBT0JtKqmLlZB4D+V3Yl3zNhZ8koUKU
 LBX3bGntOl+3Veg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

The PM660 has the same fuel gauge as PMI8998. Add support for
PM660 battery monitoring.

Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pm660.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pm660.dtsi b/arch/arm64/boot/dts/qcom/pm660.dtsi
index 156b2ddff0dcb..ce53f5ddc4bdf 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -197,6 +197,16 @@ channel@85 {
 			};
 		};
 
+		pm660_fg: fuel-gauge@4000 {
+			compatible = "qcom,pmi8998-fg";
+			reg = <0x4000>;
+
+			interrupts = <0x0 0x40 0x3 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "soc-delta";
+
+			status = "disabled";
+		};
+
 		pm660_rradc: adc@4500 {
 			compatible = "qcom,pm660-rradc";
 			reg = <0x4500>;

-- 
2.51.0

