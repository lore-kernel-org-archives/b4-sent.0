From: Joe Sandom <jsandom@axon.com>
Date: Thu, 09 Apr 2026 16:26:56 +0100
Subject: [PATCH v3 4/5] dt-bindings: arm: qcom: document QCS8550 RB5Gen2
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-rb5gen2-dts-v3-4-be736355d4b4@axon.com>
References: <20260409-rb5gen2-dts-v3-0-be736355d4b4@axon.com>
In-Reply-To: <20260409-rb5gen2-dts-v3-0-be736355d4b4@axon.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775748414; l=1053;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=X7bqqJqdT0hN1KiBNbd6ABCxR6gi8MIYVUn555bOoDI=;
 b=iCstqQHcRq9KriSiEm3ZYhT0i+DUXIrxGMo6841o/3nBuPW3U8+2MuNLl+Enh2H11bUqPBM/X
 Oq9oFCUXAsCCBvixFCixf61zzTk8+DrjWmDyuqTFC+/Q0Mzibj7K7Tk
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm RB5gen2 from Thundercomm based on the
QCS8550 chipset from Qualcomm.

[1] https://www.thundercomm.com/product/qualcomm-rb5-gen-2-development-kit/

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Joe Sandom <jsandom@axon.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 1335a7bee397c46e8dc62806091531e32b7327d4..f9f8001e3e6b66e3a926255bdb15363f4c7c2b66 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1093,6 +1093,12 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - qcom,qcs8550-rb5gen2
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - ayaneo,pocket-s2

-- 
2.34.1

