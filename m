From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 09:14:05 +0100
Subject: [PATCH net-next v2 1/3] dt-bindings: net: qcom,ipa: add
 qcom,sc8180x-ipa compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-qcom-ipa-sc8180x-v2-1-89eba621da95@gmail.com>
References: <20261126-qcom-ipa-sc8180x-v2-0-89eba621da95@gmail.com>
In-Reply-To: <20261126-qcom-ipa-sc8180x-v2-0-89eba621da95@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680844; l=911;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=Zda+9Ammsc4s6lMXOWoTtjkZ/oA5KShVVsCnmBZdGAo=;
 b=I40e9SfuC+UdZBZLKwNCpF9MbOPhueCs93NphBRuYb6USVNiQaO/L3nOJhJ4Sj/u4o873DA3L
 BZHwwh72z74CLVsV7IH/QcJk/F3TwPAYyHqnSAhiKUZ34CUtCP3g1GG
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm SC8180X (IPA v4.1) compatible string in the
Qualcomm IPA binding.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 Documentation/devicetree/bindings/net/qcom,ipa.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/qcom,ipa.yaml b/Documentation/devicetree/bindings/net/qcom,ipa.yaml
index 38e3830512feb375572c8801e06fbb97c33d9d89..99e5464dc47e53514dc8012ecd06654789ef6019 100644
--- a/Documentation/devicetree/bindings/net/qcom,ipa.yaml
+++ b/Documentation/devicetree/bindings/net/qcom,ipa.yaml
@@ -48,6 +48,7 @@ properties:
           - qcom,msm8998-ipa
           - qcom,sc7180-ipa
           - qcom,sc7280-ipa
+          - qcom,sc8180x-ipa
           - qcom,sdm845-ipa
           - qcom,sdx55-ipa
           - qcom,sdx65-ipa

-- 
2.47.3

