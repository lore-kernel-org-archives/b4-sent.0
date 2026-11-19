From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Thu, 19 Nov 2026 23:40:04 +0100
Subject: [PATCH 1/6] arm64: dts: qcom: sm8550-samsung-gts9wifi: Enable CDSP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-gts9wifi-followups-v1-1-2e2388589a62@dxdmail.cc>
References: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
In-Reply-To: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795128013; l=877;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=NnJjHpakdpxyyCZ6oFrLlypqqGlSBONU2v6+sLCEUd0=;
 b=HSIW++4ax0tLWO5zg/pur07sUSuGMeU7bTsW3qAPEdC/lJSQOP5Zz+7mRTLRiXNYh2wO67JfF
 EATqFW3CvHuAXNrldTf1BEs+6dSHJPjo6Y29J09CgQhk8yXnXKYQLMO
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the CDSP with the Samsung-signed firmware shipped on the device.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
index 1e8bfafcc8b1..8e906b7e2af4 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
@@ -714,6 +714,13 @@ &remoteproc_adsp {
 	status = "okay";
 };
 
+&remoteproc_cdsp {
+	firmware-name = "qcom/sm8550/Samsung/gts9wifi/cdsp.mbn",
+			"qcom/sm8550/Samsung/gts9wifi/cdsp_dtb.mbn";
+
+	status = "okay";
+};
+
 &sdhc_2 {
 	cd-gpios = <&pm8550_gpios 12 GPIO_ACTIVE_LOW>;
 	pinctrl-0 = <&sdc2_default>, <&sdc2_card_det_n>;

-- 
2.56.1

