From: David Heidelberg <david@ixit.cz>
Date: Tue, 11 Nov 2025 13:34:23 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: xiaomi-beryllium: Add firmware-name
 qualifier to WiFi node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251111-xiaomi-beryllium-firmware-v1-2-836b9c51ad86@ixit.cz>
References: <20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz>
In-Reply-To: <20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Selvaraj <foss@joelselvaraj.com>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=833; i=david@ixit.cz;
 h=from:subject:message-id; bh=PLFjs1iQMEpbEN9hhCiOw/xCedAmYh/qG3YE5NSot4M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEy1Okb3cPXX9Y89695Vx+MeosWDF6xW2cVz7g
 tOCsy9+c/2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRMtTgAKCRBgAj/E00kg
 chboD/9HkOnD7mNoc5x0SjLwvUIyjfP/XAyPuo2/fo+b0CgXiafeRyWnTQfk1HQIvAIpTHLaSaY
 cxSWPVxwlrYuaMN41qSBgsCA5GMp0CqGE7v4W/AU3jdEPe5dcueeVM++tDa9cJ1aQPmKG9QQR8d
 fg0pcCErXfEGhm8kXen5sMS2cDj0dd1EolMARMjpAfQW4P8Eq9CcjXq47NiDr6NNooZ2NEEVoMS
 qWLuB4EOYaNe35it/XMxsvrIZ73JIEavQOsvIr/MOZf0rIKhq1wRN+D3AIC0IcC/5VcCncOlTYm
 jy1qEeriVgzGlsaTHX+Mi7C2C1fGhjLy/LUj3yxldJ5c0nNMoQjSAUDOHkBgZ80t8Z5+7esNeAv
 p7OboW1JODXeyNpjQsIT3KcUEoRZaLQmeLkx1AA+FoAXTl1W1HW6htvZHorBr5/dy9aW9p64L3i
 AITU84iFvvuUJ4QrZkItmSdy6CyUfRDsJCezzrs2mgQLurZcCN+kddATl68a3feqzK7bt5tJaeE
 ObeaBHO7sulWi4kFy2keGxX8pzjY+R4shMHOMua/KF7820ouNQJpV0kxYdcYY6E074EVxgEZdrM
 DWeaMLM/4VTt+yd+GZiAHXgfHXRwSPZw0K4cfRocMljeo09chzWtM6cJ31EavNaBaRcUvC8fIAG
 0N5XwRaWjFwru2Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add firmware-name property to the WiFi device tree node to specify
board-specific lookup directory.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e979..9b0b0446f4ad3 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -631,6 +631,8 @@ &wcd9340 {
 &wifi {
 	status = "okay";
 
+	firmware-name "sdm845/Xiaomi/beryllium";
+
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
 	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;

-- 
2.51.0

