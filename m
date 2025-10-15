From: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
Date: Wed, 15 Oct 2025 13:27:19 +0530
Subject: [PATCH v3 5/5] ASoC: dt-bindings: qcom: Add Kaanapali LPASS macro
 codecs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251015-knp-audio-v2-v3-5-e0e3e4167d87@oss.qualcomm.com>
References: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
In-Reply-To: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rao Mandadapu <quic_srivasam@quicinc.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Jingyi Wang <jingyi.wang@oss.qualcomm.com>, 
 Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760515036; l=3129;
 i=prasad.kumpatla@oss.qualcomm.com; s=20251014; h=from:subject:message-id;
 bh=NAMMaMbrKD0m9ZcUOqBECjhw9Ighe71ZgaLRDNCqEFs=;
 b=fL9FjAw64xysetYiN3fhk/9X8BjtUpj2wlyOmTJGZBjDjyma/NdUZupY5DEdVGl2RwNASVTsa
 y9s/1NFk6sTD3br6JHebz8/n7x73kt9PdT9dz83Op0oTR93HcPO3W7B
X-Developer-Key: i=prasad.kumpatla@oss.qualcomm.com; a=ed25519;
 pk=I3mn8JNlYnnm7frqMGXms1Rm2H+0gpAfknMlnBYqCzw=
X-Endpoint-Received: by B4 Relay for prasad.kumpatla@oss.qualcomm.com/20251014 with auth_id=541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for Qualcomm Kaanapali (LPASS) RX, TX, VA and WSA
macro codecs, which is likely compatible with earlier SM8550.

Signed-off-by: Jingyi Wang <jingyi.wang@oss.qualcomm.com>
Signed-off-by: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/sound/qcom,lpass-rx-macro.yaml  | 1 +
 Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml  | 1 +
 Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml  | 1 +
 Documentation/devicetree/bindings/sound/qcom,lpass-wsa-macro.yaml | 1 +
 4 files changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-rx-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-rx-macro.yaml
index 92f95eb74b19..b869469a5848 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-rx-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-rx-macro.yaml
@@ -20,6 +20,7 @@ properties:
           - qcom,sc8280xp-lpass-rx-macro
       - items:
           - enum:
+              - qcom,kaanapali-lpass-rx-macro
               - qcom,sm8650-lpass-rx-macro
               - qcom,sm8750-lpass-rx-macro
               - qcom,x1e80100-lpass-rx-macro
diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
index 914798a89878..e5e65e226a02 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
@@ -21,6 +21,7 @@ properties:
           - qcom,sc8280xp-lpass-tx-macro
       - items:
           - enum:
+              - qcom,kaanapali-lpass-tx-macro
               - qcom,sm8650-lpass-tx-macro
               - qcom,sm8750-lpass-tx-macro
               - qcom,x1e80100-lpass-tx-macro
diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
index 1c0d78af3c05..5b450f227b70 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
@@ -21,6 +21,7 @@ properties:
       - items:
           - enum:
               - qcom,glymur-lpass-va-macro
+              - qcom,kaanapali-lpass-va-macro
               - qcom,sm8650-lpass-va-macro
               - qcom,sm8750-lpass-va-macro
               - qcom,x1e80100-lpass-va-macro
diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-wsa-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-wsa-macro.yaml
index b6f5ba5d1320..d5f22b5cf021 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-wsa-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-wsa-macro.yaml
@@ -21,6 +21,7 @@ properties:
       - items:
           - enum:
               - qcom,glymur-lpass-wsa-macro
+              - qcom,kaanapali-lpass-wsa-macro
               - qcom,sm8650-lpass-wsa-macro
               - qcom,sm8750-lpass-wsa-macro
               - qcom,x1e80100-lpass-wsa-macro

-- 
2.34.1

