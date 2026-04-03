From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 18:55:34 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Fix
 compatible strings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-beryllium-compat-string-v1-2-0a6b9cb55a20@ixit.cz>
References: <20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz>
In-Reply-To: <20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1901; i=david@ixit.cz;
 h=from:subject:message-id; bh=MZ+eRzNq9NMrcA+OAcR5yU63SqPRgMpiRYCCd8HwqP8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/EFpP7IbtRoFPW4edA+U04N6Pc6pM0G+LVN7
 C3zBYwhtZiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/xBQAKCRBgAj/E00kg
 cibnD/90wPlkMiUxRKz4ioLPT7dxEjWGGLbcRHmehrjszOfYOWW+qBJer0xSYC3ZsCBjjU6SKM1
 rvZYC3o7ABd2McxVfIHRU3ie2+oHtftxK4vwhAsE6fwysdObacccajWqFgbsjMgarB+oqK1mdRi
 F7xwDJg52n84DzAA7qSvCWpHyK7jhq5YGH36e5Nqf8UFYZQ/RLDOCIfAsfxrL+KktCwvSU22IuV
 oUqpzWXJmMqH7X4/GdBUyUdXNcbkgQKwHLHN7P46/f6jZgslBbOSx94h0dyqStV/7GdxC4yWteU
 Lrw9ydsB5ZQUzpdVt/ciFWqFrlZrmpvgRs1dumBxSOeEPtaX6K39gsapqKCyHM8auhdfNPb/EOh
 Hsg+me4KMM0WpW2aEMnfzuKUC5ryJnESYqyZ1HAL0HeCyHUgslwYMekJNaF6nRMXyizP7p7oWlg
 HL4Awf0pKgRN7Ye2FqgSdTB91evclizQLvIc9MiFF9iWs1/Yf7M1qK2Bv0aFICj0a841RUBmosu
 YPGayHt1jJxTBpuoSLiFRHkmIqP6CH/1uk4gAVsbssAJAfSWQL3l/MV0ujbjj54yyohEcNSD61b
 5RQPgZWxCcpFozH22PrmjX5uksh2zfAqYRk6AUjOIiyxCHMI/SmXN737PyYGl6GMTiJM7KdcMch
 TTwWS/sdui65m7w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jens Reidel <adrian@travitia.xyz>

The most specific strings should come first (panel variant included),
then the more generic ones (device and SoC).

This is necessary for hexagonrpcd to guess the HexagonFS path for the
device. It tries all of the compatible entries, but if none for
xiaomi,beryllium existed it wouldn't be able to guess it.

Fixes: bcf429831ecb ("arm64: dts: qcom: sdm845-xiaomi-beryllium-ebbg: introduce Xiaomi Poco F1 EBBG variant")
Fixes: dd6459a0890a ("arm64: dts: qcom: split beryllium dts into common dtsi and tianma dts")
Signed-off-by: Jens Reidel <adrian@travitia.xyz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts   | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
index 2d6f0e382a6cb..d157622f84d13 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts
@@ -6,7 +6,7 @@
 
 / {
 	model = "Xiaomi Pocophone F1 (EBBG)";
-	compatible = "xiaomi,beryllium-ebbg", "qcom,sdm845";
+	compatible = "xiaomi,beryllium-ebbg", "xiaomi,beryllium", "qcom,sdm845";
 };
 
 &display_panel {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
index b58964cde8342..71816a9f33b48 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
@@ -6,7 +6,7 @@
 
 / {
 	model = "Xiaomi Pocophone F1 (Tianma)";
-	compatible = "xiaomi,beryllium", "qcom,sdm845";
+	compatible = "xiaomi,beryllium-tianma", "xiaomi,beryllium", "qcom,sdm845";
 };
 
 &display_panel {

-- 
2.53.0

