From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 15:29:30 +0000
Subject: [PATCH 1/2] dt-bindings: crypto: qcom,inline-crypto-engine: Add
 SM8350
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-ice-v1-1-f55e6ea8e1ca@fromdisposition.org>
References: <20261105-b4-sm8350-ice-v1-0-f55e6ea8e1ca@fromdisposition.org>
In-Reply-To: <20261105-b4-sm8350-ice-v1-0-f55e6ea8e1ca@fromdisposition.org>
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793892578; l=1578;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=u0v3UH3x9W1mbgQNCdGqZvEY20x04vN6GLy9V/2qshY=;
 b=dAdTT0nm4q2Cv6G9ukR940p10kW9bV2xHiVLHSIqZsUscmv2d9Ceo4rs/VMm/ky01MIJtNABd
 BG9sX1axPMKAHc/tc/dffEB7FL9mMpcLIoSVv29UauC40OaFBwRt8J6
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350's UFS host has an inline crypto engine, version 3.2.0, with a
hardware key manager behind it, clocked by the UFS ICE core and AHB
clocks and powered by the UFS PHY GDSC. Document the compatible and
require the power domain and clock names for it, as for SM8450.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
index 23bf98c2b..198002f58 100644
--- a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
+++ b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
@@ -24,6 +24,7 @@ properties:
           - qcom,sc7180-inline-crypto-engine
           - qcom,sc7280-inline-crypto-engine
           - qcom,shikra-inline-crypto-engine
+          - qcom,sm8350-inline-crypto-engine
           - qcom,sm8450-inline-crypto-engine
           - qcom,sm8550-inline-crypto-engine
           - qcom,sm8650-inline-crypto-engine
@@ -74,6 +75,7 @@ allOf:
                 - qcom,sa8775p-inline-crypto-engine
                 - qcom,sc7180-inline-crypto-engine
                 - qcom,sc7280-inline-crypto-engine
+                - qcom,sm8350-inline-crypto-engine
                 - qcom,sm8450-inline-crypto-engine
                 - qcom,sm8550-inline-crypto-engine
                 - qcom,sm8650-inline-crypto-engine

-- 
2.53.0

