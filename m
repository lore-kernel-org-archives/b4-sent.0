From: Rudraksha Gupta <guptarud@gmail.com>
Date: Thu, 14 May 2026 00:04:00 -0700
Subject: [PATCH 1/3] dt-bindings: soc: qcom: saw2: Rename MSM8960 SAW2
 compatible to v1.1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-expressatt_cpufreq-v1-1-487fd2d78859@gmail.com>
References: <20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com>
In-Reply-To: <20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778742241; l=1155;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=kNjii0mqGqmFn4GGiHWFBoaRtbaipmmzXSF2oiS82cc=;
 b=oHPl67Wu2/1eEYL7Ap56R6la/LoJQOJlgUWbNVXT9BpjaTveGN63qmGT5W00v6e06kE2IVR5Q
 JB0al5j5FOODpa+vw1qPw7WDP2OEMQ/CeLcSbil6uAoeK3731gsNqkO
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rename qcom,msm8960-saw2-cpu to qcom,msm8960-saw2-v1.1-cpu to follow
the naming convention used by other SAW2 compatibles that include the
hardware version (e.g. qcom,apq8064-saw2-v1.1-cpu).

The MSM8960 uses SAW2 v1.1, the same hardware version as the APQ8064.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 Documentation/devicetree/bindings/soc/qcom/qcom,saw2.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,saw2.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,saw2.yaml
index c2f1f5946cfa..ff0e2697a7c6 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,saw2.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,saw2.yaml
@@ -37,7 +37,7 @@ properties:
           - qcom,msm8939-saw2-v3.0-cpu
           - qcom,msm8226-saw2-v2.1-cpu
           - qcom,msm8226-saw2-v2.1-l2
-          - qcom,msm8960-saw2-cpu
+          - qcom,msm8960-saw2-v1.1-cpu
           - qcom,msm8974-saw2-v2.1-cpu
           - qcom,msm8974-saw2-v2.1-l2
           - qcom,msm8976-gold-saw2-v2.3-l2

-- 
2.54.0

