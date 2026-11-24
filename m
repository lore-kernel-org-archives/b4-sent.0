From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Wed, 25 Nov 2026 00:01:33 +0100
Subject: [PATCH net-next 1/3] dt-bindings: net: qcom,ipa: add
 qcom,sc8180x-ipa compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-qcom-ipa-sc8180x-v1-1-48a889acbe6b@gmail.com>
References: <20261125-qcom-ipa-sc8180x-v1-0-48a889acbe6b@gmail.com>
In-Reply-To: <20261125-qcom-ipa-sc8180x-v1-0-48a889acbe6b@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795561294; l=772;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=Ls4DQl8lIKzCyet1NYkIjpGTEw7VXHTl1yE+bWxb4f0=;
 b=KWHKvkZqphw1nMy/TICAin+TjraOOGX978YjvMJXAO0xffpHOBGGb29n1mRTCSQOoAHeBjNEQ
 wXvxEk3PXJoCdxQ/YD/9kwsKudTqoOP0WtBG7al8lTQetRMg/Qe3GS7
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm SC8180X (IPA v4.1) compatible string in the
Qualcomm IPA binding.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 Documentation/devicetree/bindings/net/qcom,ipa.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/qcom,ipa.yaml b/Documentation/devicetree/bindings/net/qcom,ipa.yaml
index 38e3830..99e5464 100644
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
2.56.0

