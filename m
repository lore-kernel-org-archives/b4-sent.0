From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:01 +0100
Subject: [PATCH v3 07/12] arm64: dts: qcom: sdm845-google: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-7-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=853; i=david@ixit.cz;
 h=from:subject:message-id; bh=3zA9zU8QD5bgQ4Qh8shKYoahEuzHYEn4sy0F1hyRj2g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1bcWmiz6YqSfFByl8hyykX2F8eiNAIW6iuY
 ootX0Ac2uiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 cr3ED/9AHkfN7jEtdqQaKDKcESMhhZjpTzQrVaklKnov2jBR7j6BfMwBFVCdwuY8v/oplJ3tEs4
 qbZpok4jjpTznl2bCtRGwfIg2wg3hisZmAtmAKhF9Jy03DwQQS1Htgw3ayLieYJBQeRygLLD1/X
 qZTREBQt2MmAjMVU3jeYhzsDfGXKlVfEz+4ihkuYuIvURbHNNsTdV3v+Sg6PqAU0IzwKL7DQDd0
 I9162APcxamdo44V+I1eLiFCa1aeu91loQ9usNeDKzf0DhSzm5lIqmTqTgvJVKYZSAgjq+NG99l
 7tSpWk4uc1WM9icwBnGzhpHEQEl/Y7cYPswcEYeqh1nSXnUWd4Po5XXvAbfi6/s0a2/HLUq/1Wc
 lCqczitgpwywtJmho9barvHvqZTH6uioUmCMifGtTmogtnZ7u2W0rdpy8lBl8hANOtHprzewg8S
 X7p5GlM+RJcxJzxgIkAXdF+ZoEppxsNHDPqzvQJlnTrtXEezaD4Za6CMxGzC6PjvzE2xP+oxgj2
 SFK2T5WVI1GZQrxq7Kr73FK1dEYq7xhplxlpWtjwa/liBeYkQGnaVkZQDLJQ2zUIafb/5FxbLjA
 CrNFjMRl8dTbUDjt6Xl/Q+lJodENR4dnHe0XTVYnzrhewzCSiQdN01D+crixfzUacf4bUWZCDWz
 FImy0UenHBJ47Bg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 VBUS regulator on Pixel 3 and 3 XL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 3c9656b88b696..417c767a1821d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -451,16 +451,23 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
 };
 

-- 
2.55.0

