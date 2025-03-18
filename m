From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Mar 2025 20:56:47 +0100
Subject: [PATCH v3 4/5] dt-bindings: wireless: silabs,wfx: Use
 wireless-controller.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-dt-bindings-network-class-v3-4-4d8d04ddfb61@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1244; i=david@ixit.cz;
 h=from:subject:message-id; bh=HBoY5S1k0e2zUg4tv3n60rntaTQrtnXEYSlk57YEgBo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2c/+rXtH32FEFx87hHOghZXRVsarHOwhHZ93V
 X6wuntamLSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9nP/gAKCRBgAj/E00kg
 cqjXD/0YxeBL0pOWKsiQgODzLmJj+LanjSBr4ifes0h6NEu2JaO5oIVRs23VCKcl15XHUsKzmBC
 Vk3wkMYWzA7zy3l/dQI5nffjhlcz3Nnkp8zllSYqph3R/xGq1KJwxJOmLove5mSCTRrEy+INte/
 z1vY/6+9I1DoEY3Cf2wXITLUPepUiU4sHCebIcwMhVVhnarQjDKkthed8SjG02eHZjjDjksZWil
 +lUNoYU1FGo2qOT8ea1xSKmTmRrEsktp7gVfBeSqcLQIa61p+qgBzFIzcRyRV9eBfn3s7uyKQyX
 nr9bwzBkBpVgK0gZmDua5sxmHAwmbxFIerCyvkCExkSLlUAjMPWO+a2EXy4dkFj+f5R0A6HU2Dl
 TO7qCPASb4wIiS90Hbz56SGLwLrIIufRRV/QOGBxmOYjxkaF6lcsWAxmfgQCj6FmQIxqPNV2a1e
 cplZdiHmWVVKU/JEKOhtnyaRjSJKYn0b6Hae78/60dTPNqF+HGVjzYgtNv+5PsR3Uqvf1lSxF4u
 5n5XTEWOnCoz8UBWpx3iOtzG3TdWJH/J0BWZyn6z6cSpuEuWmXyFzVuIVXeLI7QVm3Bz0e/jyjN
 FNPv1Odopp6ol8tPcbxJPDvQ2Wvapit8RuDny1ffYUxqYUFC78SBjlXmHvwl5R7OTi5dELLRsDL
 nItlsfj1qR7bRjw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Instead listing local-mac-address and mac-address properties, reference
wireless-controller.yaml schema. The schema brings in constraints for the
property checked during `make dtbs_check`.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml b/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
index 84e5659e50ef3125b5063fbebcaf1d2b2bdb7398..6c0888ae4c4e172edf2a5f6249cb8aed5ed11681 100644
--- a/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
@@ -71,15 +71,12 @@ properties:
       "Platform Data Set" in Silabs jargon). Default depends of "compatible"
       string. For "silabs,wf200", the default is 'wf200.pds'.
 
-  local-mac-address: true
-
-  mac-address: true
-
 required:
   - compatible
   - reg
 
 allOf:
+  - $ref: /schemas/net/wireless/wireless-controller.yaml#
   - $ref: /schemas/spi/spi-peripheral-props.yaml#
 
 unevaluatedProperties: false

-- 
2.49.0

