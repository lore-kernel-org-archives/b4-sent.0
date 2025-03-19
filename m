From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 08:42:50 +0100
Subject: [PATCH v4 5/5] dt-bindings: wireless: qcom,wcnss: Use
 wireless-controller.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-dt-bindings-network-class-v4-5-2329336802b4@ixit.cz>
References: <20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz>
In-Reply-To: <20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz>
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
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>, 
 Mailing List <devicetree-spec@vger.kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1122; i=david@ixit.cz;
 h=from:subject:message-id; bh=8m+TP7dhDaz8he9N9bMiZ3ZhzlbMMMqDKwJGp281Vxg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2nV/BlN6S2VBiO/H/JLDX9kUOJ7EEhXpItnbg
 zzJrbNHsx+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9p1fwAKCRBgAj/E00kg
 cgLDD/9LvfI9zTcWOn4Qin6qT0LBWSbGHrBABqoX5Cr7vQ9qld/bLsXSBsehlJik+HdtJD2KiJY
 SfTNFtoPYKiY1LQ2ozg9aoHo6Mn52fvz26J54KQwSILEoONum+Jnoq1SHiD+jNaHbkSBOx/P05P
 rebiMzprJ9tHL6us7qW3pQo4Znx75ZiBmesBz7wlHhVk1e0GbzSHuN3nJsXrTWaAMUS+jjwZUZB
 nwcEINBaPSE3ufSjuRBbQWXrGYBG08HYHp25Y2Q05cmfpqAvhXc+sIFtgD/etQTgtI9Bh9ZjHJN
 5OSeQCoZ+2j4WEovbTfGBbJfdfP/eWXbD4GShnKVCGZYZGlT0khJXgyFLTJtCZifTMNiCWmrsdE
 nU0xWUf9Nu4lkO3sJXvhVvIYy+hlJiGyxlJp4ug/yZ2yWN7Q07nwjJYw65+vMZPs+j/h9dpV7EC
 oZhhexHCOk8RYnfdY6kZJk3sI+rhMj6lSH4sodiZQS+fpbO0uoNka+4BHL+Q+BJxXjdgrglPRIw
 OAVeaKoj1kz5FBmtAbRWOXQggoXCNSmX6ofWT0wQ6eC6jtZdSJdcFyIcrjijnwpG8qkylrbIFQJ
 qJ6aLHmu0rMbTKEM0Brx8ob17dZEToD3GrPIahWf9O/sBkfmgfi8yMERRIqOPEUrh87B0uLKduE
 qp84mMbuGPTrcjw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reference wireless-controller.yaml schema, so we can use properties
as local-mac-address or mac-address.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
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

