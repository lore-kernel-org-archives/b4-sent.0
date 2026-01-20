From: Petr Hodina <petr.hodina@protonmail.com>
Date: Tue, 20 Jan 2026 13:24:25 +0100
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-sony-xperia-tama: Add
 bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-akatsuki-uart-v2-2-867ee7f042d0@protonmail.com>
References: <20260120-akatsuki-uart-v2-0-867ee7f042d0@protonmail.com>
In-Reply-To: <20260120-akatsuki-uart-v2-0-867ee7f042d0@protonmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768911867; l=963;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=PIDGO22caa5A8sUuRwlD1y0Ysd8fRqY2U65aBFBKHCM=;
 b=UFGOkqRZtKU6SlpW+Q0DC7x8sUOzMFSFWkGBjxZjy6qeFB9u8OHbA7YaxeSs3/zy6yt+tPlEv
 CLs/5DCKJiGCppHHso0gsLzG1KPMaCDC6AJ7P41ngiSOWQugD0IYEfx
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the bluetooth interface on the uart6

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
index 68841e036c20..4c63286d8b04 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
@@ -755,6 +755,19 @@ int-pins {
 
 &uart6 {
 	status = "okay";
+
+	bluetooth {
+		compatible = "qcom,wcn3990-bt";
+
+		firmware-name = "Sony/tama/crnv21.bin";
+
+		vddio-supply = <&vreg_s3a_1p3>;
+		vddxo-supply = <&vreg_s5a_1p9>;
+		vddrf-supply = <&vreg_l17a_1p3>;
+		vddch0-supply = <&vreg_l25a_3p0>;
+
+		max-speed = <3200000>;
+	};
 };
 
 &uart9 {

-- 
2.52.0

