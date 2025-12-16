From: David Heidelberg <david@ixit.cz>
Date: Tue, 16 Dec 2025 21:34:08 +0100
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus: Enable known blocks and
 add placeholders
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251216-placeholders-v1-1-d7d544200e7c@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAD/CQWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQyNj3YKcxOTUjPyclNSiYl3zFDPTVCNLMxOLRBMloJaCotS0zAqwcdG
 xtbUAMTGuOl4AAAA=
X-Change-ID: 20251123-placeholders-7d65e29648a4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1668; i=david@ixit.cz;
 h=from:subject:message-id; bh=+JZK2ZbxfA/IlfNdhYsiDNwaA0HXucqfuw6KNa0TyXk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQcJEA5Crw2AD4nFHdNFPek/RbVbA9LTtw78Hh
 4W6BMB9wcyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUHCRAAKCRBgAj/E00kg
 coQ4D/wIOrl3U2EPI6EA35fBqsUoauCdeaHMeDEaVT/zFWMxpY4NvPo7wQPEKxGptTrhvi0DS10
 yCn/4/HjDwEb9vmbsnj6dJ7UDoqbW6+PzRYphlSoND/IoHRT0Bh373xKXOmuWAWJtEhA6Cmb7A0
 9tpUKrJ1jhmNo1iGhUZkqUnigNWKXjAUioHYtXmqoycC/fkuWdS6spHKlciENo0ehlPp0+0q/72
 m1nfuBi+auZdkt7yqiliJ3efTApM4s0kodS0PQZe1PD/oq4CPn52esVEAJFBjO0GCu1EJN3es/x
 rL575oZ/+LuNzQSb0UJcN+PyZo8AN2CAFynPOs/QWA9ielUgjpgJtBM8+MiozHLzWEDvGwhZiyV
 i/pkCbUOfDZubU1DWGg/swawcp529r5fnZcK0uCgZfa+fPVir40FrPDhp8lRRHiUi0KbeJ+nFki
 KeC3+VXUktrf4BrRsAn2wmGxpjYrMBAZTM9Tc0aiEmOnyMPK+OB6Vvy1zpMp/nU7aN5HaItZPVb
 oN5wBPoKfBwmoors9qnzIKdbKGaoarYUt5nRtdOTy/jY9IU6kPyspRou7uCOd5fycjJTzvFm0Ka
 NuY3uesS0hK5H6cz8O44mN2S3vYGvHHBw6Swaw1DqWjBnvdh/6KvD6qI1CCTt1JNK3Ae5OwuwnU
 UGyUMm1NE8YVc7g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know these devices are present; most of them are supported by
downstream and are close to the mainline kernels.

This adds placeholders for:
 - front camera (imx371)
 - rear cameras (imx519, imx376k)
 - actuators
 - NFC node on i2c3

This is very handy when rebasing the integration tree with
support for multiple different blocks at the same time.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 28 ++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..3e60565d54c08 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -352,6 +352,26 @@ vreg_s3c_0p6: smps3 {
 	};
 };
 
+&cci {
+	status = "okay";
+};
+
+&cci_i2c0 {
+	/* front sony,imx371 @10 */
+
+	/* rear sony,imx519 @1a */
+
+	/* rear onnn,lc898217xc @72 */
+};
+
+&cci_i2c1 {
+	/* sa,sa3103 @0d */
+
+	/* rear sony,imx376k @10 */
+
+	/* onnn,lc898217xc @74 */
+};
+
 &cdsp_pas {
 	status = "okay";
 	firmware-name = "qcom/sdm845/oneplus6/cdsp.mbn";
@@ -373,6 +393,14 @@ &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/oneplus6/a630_zap.mbn";
 };
 
+&i2c3 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	/* nxp,nxp-nci-i2c @28 */
+};
+
 &i2c10 {
 	status = "okay";
 	clock-frequency = <100000>;

---
base-commit: 563c8dd425b59e44470e28519107b1efc99f4c7b
change-id: 20251123-placeholders-7d65e29648a4

Best regards,
-- 
David Heidelberg <david@ixit.cz>

