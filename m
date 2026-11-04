From: Demeter Barna <me@fromdisposition.org>
Date: Wed, 04 Nov 2026 18:07:13 +0000
Subject: [PATCH 5/7] ASoC: dt-bindings: qcom,lpass-va-macro: Add SM8350
 LPASS VA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-sm8350-sound-v1-5-4c872df294fa@fromdisposition.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=1144;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=sZTRXDQ8sQKItE93dYdxZrl3e5Pj6ECZjzyBHzSkKxM=;
 b=tKRneY64+EQq831yUTvu4aW3mZCN7HO2QtZ1ALYjo107uoO+zwz8U9nO2eYfaDSWE6Kn8k7Qc
 WoHmlLJWeq7A8uaUuCqHbilIQYgrxzgNpIYMdORDfrAzHuFOqKAHB7C
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8350 VA macro takes the mclk, macro and dcodec clocks, as SC7280
does without power-domains, and reports LPASS codec version 2.0 in its
core ID registers. The SC7280 driver data reads the version from there,
while the SM8250 data sets 1.0, so use SC7280 as the fallback.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
index aea31fbda..a5466e61b 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
@@ -19,6 +19,9 @@ properties:
           - qcom,sm8450-lpass-va-macro
           - qcom,sm8550-lpass-va-macro
           - qcom,sc8280xp-lpass-va-macro
+      - items:
+          - const: qcom,sm8350-lpass-va-macro
+          - const: qcom,sc7280-lpass-va-macro
       - items:
           - enum:
               - qcom,eliza-lpass-va-macro

-- 
2.53.0

