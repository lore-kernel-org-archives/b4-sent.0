From: Biswapriyo Nath <nathbappai@gmail.com>
Date: Mon, 19 Jan 2026 15:13:07 +0000
Subject: [PATCH 5/5] arm64: dts: qcom: sm6125-xiaomi-ginkgo: Enable debug
 UART
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-xiaomi-ginkgo-features-v1-5-3c8fae984bda@gmail.com>
References: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
In-Reply-To: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Biswapriyo Nath <nathbappai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768835583; l=1079;
 i=nathbappai@gmail.com; s=20260118; h=from:subject:message-id;
 bh=So7Suu1OGUJTmgzGz2EHPUQLhQmg/zXB63gWW3YsqKE=;
 b=0IHWbUEHxlEgzZpXjcPy5Dg59dwaRpe6fLc+8bhtzOJSDHaDXIKBRRh4K8LP3CuME+vKnauq0
 Gba5cpfCUGUBwGdJgL4jofTEx5osieJrpT33KntkcuLRoPeQNuUaUO8
X-Developer-Key: i=nathbappai@gmail.com; a=ed25519;
 pk=slmb/9yXbet+KTiT3EYLCp0p0MEOYa3EdjUXP+HXfjg=
X-Endpoint-Received: by B4 Relay for nathbappai@gmail.com/20260118 with auth_id=607
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the debug uart node in xiaomi ginkgo exposed as test points.

Signed-off-by: Biswapriyo Nath <nathbappai@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
index 673bc92c7..18aecd9ff 100644
--- a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
@@ -26,6 +26,10 @@ / {
 
 	qcom,msm-id = <QCOM_ID_SM6125 0x10000>;
 
+	aliases {
+		serial0 = &uart4;
+	};
+
 	chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
@@ -124,6 +128,10 @@ &pon_resin {
 	status = "okay";
 };
 
+&qupv3_id_0 {
+	status = "okay";
+};
+
 &rpm_requests {
 	regulators-0 {
 		compatible = "qcom,rpm-pm6125-regulators";
@@ -300,6 +308,10 @@ &tlmm {
 	gpio-reserved-ranges = <0 4>, <30 4>;
 };
 
+&uart4 {
+	status = "okay";
+};
+
 &usb3 {
 	status = "okay";
 };

-- 
2.52.0

