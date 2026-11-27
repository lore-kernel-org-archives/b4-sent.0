From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 27 Nov 2026 15:24:25 +0000
Subject: [PATCH v3 1/2] dt-bindings: crypto: qcom,inline-crypto-engine: Add
 SM8350
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-sm8350-ice-v3-1-39c5b4f562cd@fromdisposition.org>
References: <20261127-b4-sm8350-ice-v3-0-39c5b4f562cd@fromdisposition.org>
In-Reply-To: <20261127-b4-sm8350-ice-v3-0-39c5b4f562cd@fromdisposition.org>
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, Demeter Barna <me@fromdisposition.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795793066; l=1295;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=jT68xkxxz5/EVqIPjmJKY8VY49FYVLS9vEllgykpp6Y=;
 b=oVptq1TzpVLZzr5nYHObZUa4FX2l/0VGIPaxRY2sW8pLRH7oKRQQ7VoG91ioQ0dQnMGmWtof1
 R8Lz58ciB6KDjtq6vxUhK0Iqslap6MJkw4FOSkQjaL8DtTPwdQYF2Qh
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350's UFS host has an inline crypto engine, version 3.2.0, with a
hardware key manager behind it, clocked by the UFS ICE core and AHB
clocks and powered by the UFS PHY GDSC. Document the compatible. Being a
new SoC, it stays off the legacy single-clock list, so both clocks and
the power domain are required.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
index a45a4ac5d..e808af8dd 100644
--- a/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
+++ b/Documentation/devicetree/bindings/crypto/qcom,inline-crypto-engine.yaml
@@ -28,6 +28,7 @@ properties:
           - qcom,sc7280-inline-crypto-engine
           - qcom,shikra-inline-crypto-engine
           - qcom,sm8150-inline-crypto-engine
+          - qcom,sm8350-inline-crypto-engine
           - qcom,sm8450-inline-crypto-engine
           - qcom,sm8550-inline-crypto-engine
           - qcom,sm8650-inline-crypto-engine

-- 
2.53.0

