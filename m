From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Apr 2026 12:54:56 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Append
 compatible strings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260405-beryllium-compat-string-v2-2-91149be07835@ixit.cz>
References: <20260405-beryllium-compat-string-v2-0-91149be07835@ixit.cz>
In-Reply-To: <20260405-beryllium-compat-string-v2-0-91149be07835@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>, Arnaud Ferraris <aferraris@debian.org>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Petr Hodina <petr.hodina@protonmail.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2487; i=david@ixit.cz;
 h=from:subject:message-id; bh=cv7cDYuMTi6gyf2Pp9mcIzjD0CpCT5mLI+pIjAH3UTA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp0j9/da2r9Zvp3XxR8GRM9SV8Jl0kFoIA4qD9/
 mWIBbIToWSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadI/fwAKCRBgAj/E00kg
 csVCD/9SY21ucBUIdch1nEgdipJ3CRwzcK1fErN4W2EXhhzDyamREDIgxzpK8jCK3SOjocmzSpF
 FA5BygMPXxW7xz8+mWbi5QJtRiiTKVIbqPC4V6MedTeWKAFG39mhsgXLE94VlHxsRx3/PQYJEgq
 M5rnDwVbrhnzHqispVETKPaTAs+EbUSecsRKCBPNSqrMT6SNSZoyCBJyyTxa0yw7ATJtTZ3BlDP
 4n3zcMmHsQZCIhweT+aX50sO8V+tq0AH0fIl1eRJB0Szo6K6ZF0FI8gOvUYzQlVJ6AjeVFJP5O0
 jSQef9LQqggmZBfog6ParwaFSbJi8ecV5JB4arzmT7jIp77JEzUO2BcdWxNlM4IArEHFo8PEm4B
 C8oID31Xk3v/kmv/G1cCDNaiJcNC4XlMXTbhXT9YJJa0tw0t+GzIZXoKh4Wasnwp81GWrnGHYzP
 7sC2AW6UbVPOtkz9qR7ZdeoQX1y3xixFW8NTCMkZ19LyoDB13gDkpuFeCf9fT6PgzdmzeDzV+++
 fCUh4z4mqqHe3cPTXuNm9ASXjFm3RH8SP0jBLrIpzH26KafXMLaAxxGXorhuUOpcZpRiTFXiHmc
 JhP6VJApmL7UiaFBGiB3J2seBEngmUAd3ztD1t1Q0QA46xDDDD+JTixaQood0X8rzqRqR40gK43
 wkmlxX+e5xSVv6Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jens Reidel <adrian@travitia.xyz>

Add the generic "xiaomi,beryllium" compatible string after the
panel-specific one, so the compatible list follows the required
ordering from most specific to most generic.

This allows userspace to fall back to the generic Poco F1 compatible
when no panel-specific match is present. In particular, hexagonrpcd
relies on trying all compatible entries to derive the HexagonFS path,
and currently fails when the generic device string is missing.

This change modifies the DT ABI: systems describing the EBBG variant
will now also match on "xiaomi,beryllium", whereas previously only
the panel-specific compatible was exposed.

In practice, no upstream userspace distinguishes between Tianma and
EBBG panel variants. All known consumers rely only on the generic
device identification, and no panel-specific handling exists.
Therefore, enabling the generic fallback does not change effective
runtime behavior, but fixes userspace that depends on generic matching.

The previous state was incomplete, as it omitted the generic
device-compatible string required for proper fallback matching.

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

