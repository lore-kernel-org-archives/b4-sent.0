From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:03 +0100
Subject: [PATCH 06/11] arm64: dts: qcom: sdm845-google: Enable vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-6-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=892; i=david@ixit.cz;
 h=from:subject:message-id; bh=7CBgv18ArIrBQNH4lCvE3E/2X60T84ZTgUfqUmKu+ko=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvv5xQ1k7s4cFeL5ZqPIxziSgGitRTmeU24
 5sg/WzYggKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 chb0EACUTL7lE5X5Q7FTtXZFrl+epB3s3olPUiP/HWtks0Vblmg6JoQFCCtnneEeqBLOf52z/TR
 aC+em7aBcpWRM0Np4h2HPJiqdG8NiLibkGhJ6ldEFRSFJcit/eCi66iguTn1pUgU/itbEKpv7em
 LKSXLktslC23r6txip2w6WgIVxqyeirFnt2I0iTQ5myuRZmI8RgK3c+d6jW9Clfuti9KLlhQyRs
 zS8WRKqfXoL3cFfUfK9lXFlDX/Sy/m2VtypSr4ug8vpgS0LdeXBUhyfqyPIFeMpj0AoImUAMZSj
 dHn3+SuU4wZ83kBacXf5a0sQftZdfD83LtyNDQfAxRWsra4C0UuIz+NTnRR0D/OKdY2dBMSsiFQ
 cc3Pi3Mm7RoUnkqZy8GXNyF8L37WrhznOf24q28IrVcsyFujJufmFF7+nEuCp7DxcW2tHK/YkZu
 SZ5s9NvKidYhE0gZZlKoaRrOs+vdnQNgXblXFsFQjU/07FciKH04D63QF1ORVSUWXGAklFmlVcd
 NvVj19MYaidU3J64Jl9m2EvpQJAsasPrqNOweGxp0x1NMLjeuVFCqBEnCnDsO4RJ7MLUsZX0mhu
 AR9ChUa9lSM1IOBNShuZHij4+dh+cq9wMaUARcPrw6CeK8370KwAovHggTLRqSF7o5Y7L35fKw4
 2o6eVEFG83vQnnQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..1cffe3c7cf76a 100644
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

