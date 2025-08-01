From: David Heidelberg <david@ixit.cz>
Date: Fri, 01 Aug 2025 10:21:40 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-oneplus: Deduplicate
 shared entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250801-sdm845-msmid-v2-2-9f44d125ee44@ixit.cz>
References: <20250801-sdm845-msmid-v2-0-9f44d125ee44@ixit.cz>
In-Reply-To: <20250801-sdm845-msmid-v2-0-9f44d125ee44@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2251; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZJywnoUp3uvB3aKb5+Bvj63no54fBuuORi0qPRukfHI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBojHkS0aszmT0r1lv705M3GHf3q3UeTInv1J0Hj
 7xFX7oWI7SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIx5EgAKCRBgAj/E00kg
 cv2rD/9CHE4cDtJn3+z/h05RzJ1b8vmIHMrSj5jE1WuEDCeSh5Vq98jfSd7vzj8dqKP3H9+XFOH
 7L0AULrDXhsb9L9GyKl0ATpPeJs7O0eD4v0eV30eQFtSngbVq9XhPNpWSn2jbhUq30cx7M0v2bw
 zQ4IEL0U8pUFEiL+S29kXgaSquxtxuwSyrA17dDc+O+ve468nbAC3Fd7YAZOH9rdy5elbVN8imh
 6cWshAvCBLxyY7Rr2SbCN+342Z+JSarsJtsJC5uFEZOA/EmwlPA9nwcVSvG0nqAIGkzdGqBxyCE
 /C3r+VuR4112+IoK6gGibeznr6g1EGwDNkYLH+wSduWdshoh+THNyeaGYHEoVgV8bslRu1Sy6KN
 E+GDquRVpjUNhpN9kLmaiDJGjqdyrajSY9WReWgnUQPY7lsoDWd3HhL25GZd2fXO0UbgqvYyjFR
 qxzDffeRwWPfFYiDD3rky1lyJbPNHtap26RCDBK+75Y1mMeRQUpcGdzsAUY0nKflcqdNGAgC7JK
 qtPcRlmgsovbwaGNRzxv7hrYy212SqS4GeIhbcHCS3seugDe7//eWhKFS4g2HGMySBpld3i/vpS
 5vLbUQdbbri1gSKKygCGqS9PS5Uh4tntFWGpEHklLcoO+j9hE70mL8CS+4YkKe7YrlHNWyc3CRM
 M9S3c+II2GLSliQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the definition for qcom,msm-id and put them into the common dtsi.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 4 ++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 2 --
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    | 2 --
 3 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index b118d666e535a433f44b66c71b36e55df2ce5c80..dcfffb271fcf3146aeabda8fc19e61b456b76887 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -7,6 +7,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/leds/common.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
@@ -21,6 +22,9 @@
 /delete-node/ &rmtfs_mem;
 
 / {
+	chassis-type = "handset";
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
+
 	aliases {
 		serial0 = &uart9;
 		serial1 = &uart6;
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index 4005e04d998a40d25a64d652a526bf93efc20332..cd5546b69d13d8d7f29373aebab1cfda79666900 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -10,8 +10,6 @@
 / {
 	model = "OnePlus 6";
 	compatible = "oneplus,enchilada", "qcom,sdm845";
-	chassis-type = "handset";
-	qcom,msm-id = <0x141 0x20001>;
 	qcom,board-id = <8 0 17819 22>;
 
 	battery: battery {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 9471ada0d6ad8bd44cc58a6efa07f7eb27921af9..b4212626b42954e10974ec087db2b42b07979f72 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -10,8 +10,6 @@
 / {
 	model = "OnePlus 6T";
 	compatible = "oneplus,fajita", "qcom,sdm845";
-	chassis-type = "handset";
-	qcom,msm-id = <0x141 0x20001>;
 	qcom,board-id = <8 0 18801 41>;
 
 	battery: battery {

-- 
2.50.1

