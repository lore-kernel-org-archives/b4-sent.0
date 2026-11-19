From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Thu, 19 Nov 2026 23:40:05 +0100
Subject: [PATCH 2/6] arm64: dts: qcom: sm8550-samsung-gts9wifi: Add GPIO
 vibrator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-gts9wifi-followups-v1-2-2e2388589a62@dxdmail.cc>
References: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
In-Reply-To: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795128013; l=1114;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=LNUGNkotVCwE1oY6OrzDcZJUYNIfY57QMi/3bSwKTao=;
 b=yYmfAn/ldoSlJGnJQOy5sEd3RNTETVwppDlYOHDW7qw1Mgu2sC0OmQ5wwKO/d9SJqEDpbivAR
 x+oPHPXlHCwDizIvKwRVBLQgO4BZdknI+kBSrczDApI2+EY16snO9DU
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vibration motor is switched on and off by TLMM GPIO 18. Describe
it as a gpio-vibrator.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
index 8e906b7e2af4..3832ea0deb46 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
@@ -161,6 +161,13 @@ platform {
 		};
 	};
 
+	vibrator {
+		compatible = "gpio-vibrator";
+		enable-gpios = <&tlmm 18 GPIO_ACTIVE_HIGH>;
+		pinctrl-0 = <&vib_en>;
+		pinctrl-names = "default";
+	};
+
 	wcn6855-pmu {
 		compatible = "qcom,wcn6855-pmu";
 
@@ -800,6 +807,13 @@ tdm0_ws_active: tdm0-ws-active-state {
 		bias-disable;
 	};
 
+	vib_en: vib-en-state {
+		pins = "gpio18";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	wlan_en: wlan-en-state {
 		pins = "gpio80";
 		function = "gpio";

-- 
2.56.1

