From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:04 +0100
Subject: [PATCH 07/11] arm64: dts: qcom: sdm845-oneplus: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-7-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1021; i=david@ixit.cz;
 h=from:subject:message-id; bh=qtK8U0DG1cRkdsACHAr+c1jMalJb+5fDCyLN85kWDvA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvumnNkjX9xEkWmSZ03N2FQLW1h7MKYlPAb
 XF0klZkU26JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 crq+EACg6Q0/DvGX7+HThl0wRuAbMDl1EQfhjxmcDDlxUq/vORmUwxVfpyUFldpcSFZlBTYlzzW
 GM8+XbKePDKCY5XXcUZ0JEmUB9b0o6UnnAkvlEzXveYSwwWo2y8FWRDC+GJXBVOVgKTfDNFD4Q1
 T6ovUgq9h97lesdOLVaQYjHVawqI17yPArry2BNA/nvrlwzTgD+YjnMwFnNQ5draqjOMvwRDvpm
 jwgD1vFDYv+yvn+4jcQVDR1XdBsNjfvDv5vfyaE55nuXbLiHJZLKNIThMg77B0+WANso1U12UEV
 54nTjMg2+m54LvdkDPQ5rWrZ5GG2qo/3K/B+hfGzTza5gL15kDBG3bzm6CJgsdCVcnjA2+clIZf
 9XC0mFbJgcUsEFCrWmZyVsqq6NmfB8d+gs7VNY20UmPbg33M0QiVre86+6deTp2K9UjjXFHXNr9
 e7FzDtNolJ9mhRnrEpJsHb7LYjXKkH6OUKdhguH8FyFaSJNnNx7FJtjFc1p2Lguh38mKpy69U6R
 mzLn7z0VcR0znXZF+fvx5Yxt7Lt1zGTOOvBNYukCPZKpJ2YLgQzZO43cxadT1NMBHNarRtKxS81
 DdTWKqYTmB7/MQ1j9E1MnDZm2Qj0Brl5Em0pHY04D8vKyUcWOmklsyVgoerkPntQ+iVdIcnJh3j
 Vo0GQGrfLh3Kjxw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 1df09da3c4d71..4996ce24fee36 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -660,16 +660,23 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <500000>;
 		flash-max-microamp = <1500000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <1>;
 	};
 
 	dai@23 {
 		reg = <QUATERNARY_MI2S_TX>;

-- 
2.55.0

