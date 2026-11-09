From: Demeter Barna <me@fromdisposition.org>
Date: Mon, 09 Nov 2026 13:55:29 +0000
Subject: [PATCH v2 1/2] dt-bindings: crypto: qcom,inline-crypto-engine: Add
 SM8350
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-sm8350-ice-v2-1-fd5e84985e90@fromdisposition.org>
References: <20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org>
In-Reply-To: <20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794232535; l=1222;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=O8H9CShAkj9Ovw7qSKhxVxcXLgvKHLomuYV1vK0dxiU=;
 b=XV+ZqkfTPsOnsrBbgAxWb88AQs2Y8b6HpCata6VLx6NmLxeWanvpCdCQLW5hpbxbYDLiiFm4Q
 FsaaT4Em3M8Awf0aoi/gPY6gpCjMrpyvclMtURYmlt02wAi2vdnUOLV
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350's UFS host has an inline crypto engine, version 3.2.0, with a
hardware key manager behind it, clocked by the UFS ICE core and AHB
clocks and powered by the UFS PHY GDSC. Document the compatible. Being a
new SoC, it stays off the legacy single-clock list, so both clocks and
the power domain are required.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
index 23bf98c2b..2423fd846 100644
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

-- 
2.53.0

