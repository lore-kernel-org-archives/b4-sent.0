From: Demeter Barna <me@fromdisposition.org>
Date: Wed, 04 Nov 2026 18:07:12 +0000
Subject: [PATCH 4/7] ASoC: dt-bindings: qcom,lpass-tx-macro: Add SM8350
 LPASS TX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-sm8350-sound-v1-4-4c872df294fa@fromdisposition.org>
References: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
In-Reply-To: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=1540;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=0hLjX+UuZseyb7/LGbuCXr+F7fsgUZAI6EHJS7cn3Zo=;
 b=eBdl5XseGfy6llngy+lt6PaHrN/tEzsTHy/Yb7Xf8zmg3pDjPiYQLqghZGGGLZQBHqF1cJokg
 umT2TkOJOo/DDWD+YEFNbHfi/7Q6VHQ+JvZ91AzwPUN5dvMJufO0hCZ
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8350 TX macro is LPASS v9.2 as on SM8450 and takes the same
clocks, so add it with SM8450 as the fallback. Use "contains" in the
clocks condition so that it also covers the fallback form.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 .../devicetree/bindings/sound/qcom,lpass-tx-macro.yaml       | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
index d8682ff2e..f9702a11e 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-tx-macro.yaml
@@ -19,6 +19,9 @@ properties:
           - qcom,sm8450-lpass-tx-macro
           - qcom,sm8550-lpass-tx-macro
           - qcom,sc8280xp-lpass-tx-macro
+      - items:
+          - const: qcom,sm8350-lpass-tx-macro
+          - const: qcom,sm8450-lpass-tx-macro
       - items:
           - enum:
               - qcom,eliza-lpass-tx-macro
@@ -90,10 +93,11 @@ allOf:
   - if:
       properties:
         compatible:
-          enum:
-            - qcom,sc8280xp-lpass-tx-macro
-            - qcom,sm8250-lpass-tx-macro
-            - qcom,sm8450-lpass-tx-macro
+          contains:
+            enum:
+              - qcom,sc8280xp-lpass-tx-macro
+              - qcom,sm8250-lpass-tx-macro
+              - qcom,sm8450-lpass-tx-macro
     then:
       properties:
         clocks:

-- 
2.53.0

