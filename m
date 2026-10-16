From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 16 Oct 2026 06:13:51 +0000
Subject: [PATCH 1/2] dt-bindings: interconnect: qcom,msm8998-bwmon: Add
 SM8350 CPU and LLCC BWMON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-sm8350-bwmon-v1-1-562fe403bf6b@fromdisposition.org>
References: <20261016-sm8350-bwmon-v1-0-562fe403bf6b@fromdisposition.org>
In-Reply-To: <20261016-sm8350-bwmon-v1-0-562fe403bf6b@fromdisposition.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792131248; l=1323;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=2V9EmHIfTwVMPMJXFXv6gNZE4v3VuLK8DjgkO4BKOLI=;
 b=y5pCykklfm0EnCq78CpVFzzoDYExiFxx49wopRYhtgNnoIRsTygTc0FlWYHV5GNPxaPA8exiY
 C+gsLVMGlDsBY9Twsx5Tj68GXlnGl4o96BGcYdH8oF2Gmuilb964UAl
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the SM8350 CPU BWMON, compatible with the SDM845 one (v4),
and the LLCC BWMON, compatible with the SC7280 one (v5).

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/interconnect/qcom,msm8998-bwmon.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/interconnect/qcom,msm8998-bwmon.yaml b/Documentation/devicetree/bindings/interconnect/qcom,msm8998-bwmon.yaml
index f6969910bded..af4a81ca080c 100644
--- a/Documentation/devicetree/bindings/interconnect/qcom,msm8998-bwmon.yaml
+++ b/Documentation/devicetree/bindings/interconnect/qcom,msm8998-bwmon.yaml
@@ -41,6 +41,7 @@ properties:
               - qcom,sm6115-cpu-bwmon
               - qcom,sm6350-llcc-bwmon
               - qcom,sm8250-cpu-bwmon
+              - qcom,sm8350-cpu-bwmon
               - qcom,sm8550-cpu-bwmon
               - qcom,sm8650-cpu-bwmon
               - qcom,sm8750-cpu-bwmon
@@ -59,6 +60,7 @@ properties:
               - qcom,shikra-cpu-bwmon
               - qcom,sm6350-cpu-bwmon
               - qcom,sm8250-llcc-bwmon
+              - qcom,sm8350-llcc-bwmon
               - qcom,sm8550-llcc-bwmon
               - qcom,sm8650-llcc-bwmon
               - qcom,x1e80100-llcc-bwmon

-- 
2.53.0

