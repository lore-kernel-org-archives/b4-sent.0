From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:01 +0100
Subject: [PATCH 04/11] arm64: dts: qcom: pmi8998: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-4-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1178; i=david@ixit.cz;
 h=from:subject:message-id; bh=HpvL6iFTwrelyJpOxklGc3G9PcqLuzIuZ5tvJd9wb+c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvX660ezv4WbP314Ec4yNJVhTKt2nRttV2f
 EGDQsFCJB6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 cg6oEACYSSRn0je6bPBHxaafWX0LcMljCeYF+zilR36komre2XX4m703G6rYow8qbisD4kNZClU
 wFqQr/U016Dqx9FOELaxZ1G+GaXP9cb5XmpDThPdhM8xq6YvcXaJ8CKSbwfsnEPVYXBqF7dB6R3
 G45IjpCqlcXNmhv1ahvf3IpyGdX/3/3c2rZXU8aUMnir4jTeKhjVagnz4nxVcIJ5AyZR0l+awTM
 hqbe83sEsIvEQjJp8R5XZbImUxSTuSpKZMYpuWlxVeSoEBmyc0l1PtFUvNuAvPvqkXoByKCZ7nw
 4FEnJRlOfZs3kJqrgeSidJW0nvvsgMxH284Xmo87iSuhmX/cPEGg8xoH/RSbjCe0vAIxiLm4GJC
 iT1qBnSxKgEHlN3UxSHIN6aJ3sz706QuFALWMr4xhIwXgnXUSbqxAS9npHuNjcNDrXygEb7FsiE
 bzt7qejpw9kH2Dn2lU6II9n9+DkPELNHTfrzYGS/ewSCH51d1crDK4ayPLldXYlTzF2RCVomEtO
 ZQqdDwONac7UNxwxN0HlRJER5Mi2tPqbYRnBVYOzKNnTJPjhHSVRlpYZdKXdvCQ01WfxngGif5a
 xt85hRjiKyJg8oGrxGgwekTmrNyhzAiCnzjIdqgG8SSZen4cr9q/qVXI3seKFOfOnM/yCsxpRzk
 AINIqMmoKwyuPmA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required DTS node for the USB VBUS output regulator, which is
available on PMI8998. This will provide the VBUS source to connected
peripherals.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd420..86640ea6e592c 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -24,16 +24,23 @@ pmi8998_charger: charger@1000 {
 
 			io-channels = <&pmi8998_rradc 3>,
 				      <&pmi8998_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pmi8998_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pmi8998-vbus-reg", "qcom,pm8150b-vbus-reg";
+			reg = <0x1100>;
+
+			status = "disabled";
+		};
+
 		pmi8998_gpios: gpio@c000 {
 			compatible = "qcom,pmi8998-gpio", "qcom,spmi-gpio";
 			reg = <0xc000>;
 			gpio-controller;
 			gpio-ranges = <&pmi8998_gpios 0 0 14>;
 			#gpio-cells = <2>;
 			interrupt-controller;
 			#interrupt-cells = <2>;

-- 
2.55.0

