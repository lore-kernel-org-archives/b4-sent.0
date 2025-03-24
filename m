From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Mar 2025 18:41:41 +0100
Subject: [PATCH v5 4/5] dt-bindings: wireless: silabs,wfx: Use
 wireless-controller.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250324-dt-bindings-network-class-v5-4-f5c3fe00e8f0@ixit.cz>
References: <20250324-dt-bindings-network-class-v5-0-f5c3fe00e8f0@ixit.cz>
In-Reply-To: <20250324-dt-bindings-network-class-v5-0-f5c3fe00e8f0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1355; i=david@ixit.cz;
 h=from:subject:message-id; bh=1+Q97VlsmTPyLRAWooczMv5yLKsXFA3Pd6AXggMFbak=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn4ZlUF/zgQhHhLaKXCphlup97trhKf8Or6du6C
 ZNMKVUlw6WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+GZVAAKCRBgAj/E00kg
 cmJgD/9j/3y+cVi7+Qtvbk//nZ7RVgZDDN0GAGbjJrZ+UEjhd/6vdeBvEr3JWAyGNuhtvLMxTbr
 GUoqEG2rpmlf7KgZTmFa+v3Eon8FcTNrQLP1IqMRG49r/zx2L9tmh0VF6iNa2FjjXCGdwzJjXb3
 72ngNCiIkcBrJ4AI6IoY2f7BZ4fD2ou2E8Lv5JXo0p80OJTff5XkSrGhFDZiqMck2Ip2GHVVepZ
 l25HdjQoeqciRJF2FtmEnrtwIQotAUaSJre6AEM8gUXJz5ehWZBwpKQaBDKl5dzzZUbbNecPLRJ
 MDuljAtFfSLzdgzdTzFhrIu2z3onhjnULad06GyRCTn5JPxJrtgki7MixamRWtoteMILrSpH31T
 Xpnfijb1cyMQNhhpKliDnckjHJ18oagCOqHv4wpb9zzm5aB6VxmZ9gFwFinxecQ4uXZXE64iY7H
 RR2vxZNg+AdyI4hp3B1xOupk+75jyqSpEGbNwwOis0VhefAuAlkRh82pBEuGdayW8jO8gRKlYxq
 0HDe0Dqz6ak/TRJaFIywDIBGDw8Lro5/DOQ+g5dkGAJB1ak6UK4qO4SFEcYPgYUA4s11C8DQ1z2
 Xi91+LtieCa+/pWl/sSSC43yaHahkgcLOEb8lb3qtID1bM5/eObrx0hqj90mglvU1k6qzceNH52
 syrqHitgj1VP83g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Instead listing local-mac-address and mac-address properties, reference
wireless-controller.yaml schema. The schema brings in constraints for the
property checked during `make dtbs_check`.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Jérôme Pouiller <jerome.pouiller@silabs.com>
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

