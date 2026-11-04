From: Demeter Barna <me@fromdisposition.org>
Date: Wed, 04 Nov 2026 18:07:15 +0000
Subject: [PATCH 7/7] ASoC: dt-bindings: qcom,sm8250: Add SM8350 sound card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-sm8350-sound-v1-7-4c872df294fa@fromdisposition.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=1024;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=WzyI+H2dXucyfn4YdVhqjW+4BoqlMGa4ke+mqK0BZpo=;
 b=l+qClH2K37db/cfg3zbyViozWf1icXt282DudloAbK5a2uT0ksNh3SyJlT/Ic52OOD+3Q2QTA
 mc5yew/xCaSDfeJX1aRnjXLZohunlLWG450HyEh1WhNGqY89v39ZcRK
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8350 sound card is the SM8250 one: the same DSP services (APR with
q6afe, q6asm, q6adm), LPASS codec macros and back ends, handled by the
sm8250 machine driver. Add its compatible with the SM8250 one as a
fallback.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/sound/qcom,sm8250.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
index e2e3fc99e..ccf553f38 100644
--- a/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml
@@ -21,6 +21,9 @@ properties:
               - lenovo,yoga-c630-sndcard
               - qcom,db845c-sndcard
           - const: qcom,sdm845-sndcard
+      - items:
+          - const: qcom,sm8350-sndcard
+          - const: qcom,sm8250-sndcard
       - items:
           - enum:
               - qcom,eliza-sndcard

-- 
2.53.0

