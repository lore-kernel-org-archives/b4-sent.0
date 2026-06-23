From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 22 Jun 2026 21:44:18 -0400
Subject: [PATCH 2/3] dt-bindings: net: qcom,ipa: Add SM8450 compatible
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-sm8450-ipa-v1-2-532f0299f96e@proton.me>
References: <20260622-sm8450-ipa-v1-0-532f0299f96e@proton.me>
In-Reply-To: <20260622-sm8450-ipa-v1-0-532f0299f96e@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782179059; l=741;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=W4HaPPuqJKWe7vEYJVxbrdUViHRUB9llZBviI9Yuc4w=;
 b=2V5hi6hHuHqSLGzTbR1Ekc1t3eHAqRambzD/YV3uUWQQviFAkWUMRyt0gVpT2cU1WdSrQBb5h
 nvZGCc5qs15B0JtRCEDVerdRrK8+CODEoyXTZXfzYD4Q5iSV/RocnMi
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Declare compatible string in ipa binding for SM8450,
which uses IPA v5.1.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 Documentation/devicetree/bindings/net/qcom,ipa.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/qcom,ipa.yaml b/Documentation/devicetree/bindings/net/qcom,ipa.yaml
index 68ec76fe4473..db91bfaaf833 100644
--- a/Documentation/devicetree/bindings/net/qcom,ipa.yaml
+++ b/Documentation/devicetree/bindings/net/qcom,ipa.yaml
@@ -53,6 +53,7 @@ properties:
           - qcom,sdx65-ipa
           - qcom,sm6350-ipa
           - qcom,sm8350-ipa
+          - qcom,sm8450-ipa
           - qcom,sm8550-ipa
       - items:
           - enum:

-- 
2.54.0

