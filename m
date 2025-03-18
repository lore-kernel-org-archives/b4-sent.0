From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Mar 2025 20:56:48 +0100
Subject: [PATCH v3 5/5] dt-bindings: wireless: qcom,wcnss: Use
 wireless-controller.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-dt-bindings-network-class-v3-5-4d8d04ddfb61@ixit.cz>
References: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
In-Reply-To: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mailing List <devicetree-spec-u79uwXL29TY76Z2rM5mHXA@public.gmane.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, van Spriel <arend@broadcom.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_Pouiller?= <jerome.pouiller@silabs.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1072; i=david@ixit.cz;
 h=from:subject:message-id; bh=gmn5ThPDUPmISVwNn4Be9D1nVjSGuTMMZ+wDLTHXKfs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2c/+fSLSvOOP/1NrHIs5zBZKCZkCM9H07z63p
 +w64xSd1mSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9nP/gAKCRBgAj/E00kg
 crnBD/wKnlKViZa7j9xXS4zIroJ+mYGOGFXAK8GCBybRxkEyKbEGnWWJaeZ4bxNl+bTIr1dKClS
 G2FRnubcXBSk/w0JWDQOSw4SKJk4vvWgroqj5Nv5oaCQOxbxORBuUoOzRZMgkxxcA9w1v/g9Di7
 EQmvmzRuRxbTSfVCCHTSl4fl7zsiimAUsAzgry6WO3teaoRTlwM803VC6rNg8bnvPXtThU4w4xg
 UZ+GbUFC+FJShhA6XEWuT243WnOrlnz/9Po+usChnz+tbDy/fd3F+FyuHPOh6kwCDtZFNZSRRp5
 J36Xe2Q6Q1mzXZvJpnrI1gHsPRhWpVSV/vRyOdpcytb4XIV+L4vVIuE3cYjmI1xptluh1F9cfI9
 lg/YlbxrhwydDGSlP7PmUhk0l9fCr1/4/iEkrkVRZpLbdIAD9gbCIYza3uFBGhhCK3wPjNp2/G/
 oRDz6sTt084KYiPopdK6AMaIOXftTbnv8vvJAt/puaLkfFnTP1kf6ahdP2DUz5S4rrLXmuI+d+T
 oyDrfMmoH9Pb9MuyWcotYHxqZGToxIO+1V7WWyAHkeEhERajbFsRTTOCQALg27tCA1lYl//p9zC
 AgiOOblZW6Z17xyVVHfrhDxXs13zIz2vtAR897ISRaQhgMEZQLh09eg46bmLM9Pwlb3bqmXGHbV
 bbrM2205srJAXsw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reference wireless-controller.yaml schema, so we can use properties
as local-mac-address or mac-address.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/soc/qcom/qcom,wcnss.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,wcnss.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,wcnss.yaml
index fd6db0ca98eb7e56d7399f55c408844d5e782805..4fcae6bedfffa845ad61c776ee0b70768e9a38a5 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,wcnss.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,wcnss.yaml
@@ -54,7 +54,7 @@ properties:
       - compatible
 
   wifi:
-    additionalProperties: false
+    unevaluatedProperties: false
     type: object
     properties:
       compatible:
@@ -88,6 +88,9 @@ properties:
       - qcom,smem-states
       - qcom,smem-state-names
 
+    allOf:
+      - $ref: /schemas/net/wireless/wireless-controller.yaml#
+
 required:
   - compatible
   - qcom,mmio

-- 
2.49.0

