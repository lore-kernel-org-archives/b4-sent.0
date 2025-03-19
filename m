From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 08:42:48 +0100
Subject: [PATCH v4 3/5] dt-bindings: wireless: bcm4329-fmac: Use
 wireless-controller.yaml schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-dt-bindings-network-class-v4-3-2329336802b4@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1082; i=david@ixit.cz;
 h=from:subject:message-id; bh=Ykanx8wzDbyUa/ls65ZFTHRGPUtwaqJKAXv1MSG0rDU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2nV/qIBBtD+92YGrTaZ6GD9reQMC2Inj3zs73
 N+8JLdqnNCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9p1fwAKCRBgAj/E00kg
 ct3SD/4jAIh8CmZO81HMcbQ37zZZgxfpTo6ov/fnVOOHd8MeKz5r5T8PvXv/fu60t0ou3WTXroy
 lt2hSsnu13cX0uvqfKCaTffSJUGlE5kog1XKkcePDd9bdse3Eh07yNdaVAQSK9McZuvWi8Cw/gW
 7RM5rccSuFGlCwxZrNj26vAKtfDRjMjMrSOqoiibo2wuFJyu8gtzLm4f1H969QIFnR43TTsKRzo
 wkops2UoeJR+DPBK+4fT5lwxRLtTVtLS1p8nTLFyN0gHdhNcKtZjPoX/tKiG+hD7dl8ErnxvyaI
 l7uoKnO9Sqe6wDGAd6wTk3xMSMbl97JvPhx2a0Ox89vjDWvOCnwCZv4QEkyDCPueBd8oXt7mEtE
 Lq6P7om+cW++205M2Oij7pwsPTWoUJLQuikRBoR4tlaN3WgV/s236zfu2BS0FS3I3ps2UDRjGSg
 4b6ItRoim5Kaln5vH1V2aFB7QNx9lSD9f25oFdudmktgcnaRmtw6GArJXiMEWAsCspNyIjJRix0
 s3oGIiA+sKJ3+7UbvYgGCxk7re0aIavOrDBsZeY90mCrBAi8Zy2rgXnisMYPLMQ86OhLms1G7TE
 5wmTvgiNnKruWcP7MkCZFzc97zoMVq/Xf6g1Hx/UibkIQUkDmrd/twYyA0BsrfSDmjaAp1HhWhE
 k96mQxvVC9Q+neA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

The wireless-controller schema specifies local-mac-address as
used in the bcm4329-fmac device nodes of Apple silicon devices
(arch/arm64/boot/dts/apple).

Fixes `make dtbs_check` for those devices.

Signed-off-by: Janne Grunau <j@jannau.net>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml b/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
index a3607d55ef3671514cdf2c884cf5bd0ccaadb162..7c8100e59a6cd045837a2f602e367f3f79ced5ba 100644
--- a/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
@@ -16,7 +16,7 @@ description:
   binding.
 
 allOf:
-  - $ref: ieee80211.yaml#
+  - $ref: /schemas/net/wireless/wireless-controller.yaml#
 
 properties:
   compatible:

-- 
2.49.0

