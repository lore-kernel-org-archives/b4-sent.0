From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 19 Jan 2026 12:58:53 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-sony-xperia-tama: Add
 bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-akatsuki-uart-v1-2-238f4da4fa56@protonmail.com>
References: <20260119-akatsuki-uart-v1-0-238f4da4fa56@protonmail.com>
In-Reply-To: <20260119-akatsuki-uart-v1-0-238f4da4fa56@protonmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768823932; l=989;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=oJfa2XZX/bnhQI4FpuzAOMxaAeuoSQqJQXp6FVFBsCo=;
 b=a/0z+yHib1x0aFIOKRMxjXjdkZYOLrvT5bGZkBat/lOzbNC21peavZUojSS53cpiRTOZzPnG8
 CVMlK64CRVbCP02aP5a2ddJeio6qkgwqGgvm9Gbb4q5W2V2dxm+mlIV
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the bluetooth interface on the uart6

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
index 68841e036c20..f23f9757a08b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
@@ -755,6 +755,23 @@ int-pins {
 
 &uart6 {
 	status = "okay";
+
+	bluetooth {
+		compatible = "qcom,wcn3990-bt";
+
+		/*
+		 * This path is relative to the qca/
+		 * subdir under lib/firmware.
+		 */
+		firmware-name = "akatsuki/crnv21.bin";
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

