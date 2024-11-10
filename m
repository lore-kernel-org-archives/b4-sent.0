From: maud spierings <maud_spierings@hotmail.com>
Date: Sun, 10 Nov 2024 13:46:12 +0100
Subject: [PATCH] enable the gpu node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241110-qcom-asus-gpu-v1-1-13d7b05784b8@hotmail.com>
X-B4-Tracking: v=1; b=H4sIABOrMGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQ0MD3cLk/FzdxOLSYt30glJdC3ODZPNkIyNLY9NkJaCegqLUtMwKsHn
 RsbW1AMtWuORfAAAA
X-Change-ID: 20241110-qcom-asus-gpu-870c7c22935c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, maud spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731242781; l=1072;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=r3QqlTk6/PdijpA+1hzU7uSYno80RzxewgsClzl2Gxo=;
 b=uz7Ftt5vnXmdUh012LFdLEbFGUKoaVnsAceQDCjeb1yYRh2yL3NhijBx8qekuLKRIKLTrHVSj
 lohsU+0kM6CAzhd0g59n/a23dmGmQ5y+UirXSPhHAymGi1ZLnnu+LY0
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

enable the gpu node on the snapdragon powered asus vivobook s15

---
enables the gpu on the asus vivobook s15

Signed-off-by: maud spierings <maud_spierings@hotmail.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index 8515c254e15868a5d7f378b0dc0bf8f339fc7b19..f25991b887de3fca0092c5f81c881c5d8bd71aac 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -328,6 +328,14 @@ vreg_l3j_0p8: ldo3 {
 	};
 };
 
+&gpu {
+	status = "okay";
+
+	zap-shader {
+		firmware-name = "qcom/x1e80100/ASUSTeK/vivobook-s15/qcdxkmsuc8380.mbn";
+	};
+};
+
 &i2c0 {
 	clock-frequency = <400000>;
 	status = "okay";

---
base-commit: 929beafbe7acce3267c06115e13e03ff6e50548a
change-id: 20241110-qcom-asus-gpu-870c7c22935c

Best regards,
-- 
maud spierings <maud_spierings@hotmail.com>

