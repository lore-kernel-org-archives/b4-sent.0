From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Mar 2025 18:41:40 +0100
Subject: [PATCH v5 3/5] dt-bindings: wireless: bcm4329-fmac: Use
 wireless-controller.yaml schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250324-dt-bindings-network-class-v5-3-f5c3fe00e8f0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1082; i=david@ixit.cz;
 h=from:subject:message-id; bh=/39eFZ6ducpCjGUyDE9DMGHcDra7AKtjh9uaQngpN54=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn4ZlUt699Tlcv8r6WJO24J/HN3KZtO6w86vhOh
 rcHlVCjHG+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+GZVAAKCRBgAj/E00kg
 cmG9D/oCykoLT9XrEn6xb1Q47UpvM0WJw8+ER5SJHyw1AQ3bzSnBRHBhPZ8VDJ3TlyhVGbkWQx9
 noV3zps0Zfjl+n0BqTH3IPBPsVmXi+woMrih0R0wPjNc39dV0WlBq64G6dXCrc5SVWBB649glBu
 gx8rYGmdyDVEmBNZv4XUyez4iiL4cmGkNwRf/atqNbmzROapeQDuGRYabDPQA6q8sNf/8hk39S7
 tdZ6HYA3Xa4z+xc2DADeuoesKl7tfgtQNjxETQpOwPmYTHPhVlDTklYylklSF59YhDRSBq9KWfD
 eppNfUdMcSa6VdBSctjJkAaKqnJOpOc7wYEOO0XEWN4iQI2Ab8l0T/r0TkV1IAncai3cmPEjqdv
 ayQ45Pc2f0r/gTtGnlvWxsC7vxKcPx3qrt0iof5nuiDwYdj9XM759iCKMzXIFX9HrACDuauPZSD
 4neH2iIg3QsED31jB6f+3cx5KhMB5Z6CH6d7OSUJ9E8RPMMsNslwEcAEY8irjtblxG4zxx2PeTu
 mPL7w5j7JeXOcQ4bEbusJuAtyoSmo5Wr9yTm2PHYUlpo+pTwbIxI2lGac+zL4bGqCmR+TiFNpyn
 Tz4Av7pbr8u87LDnP5jsNZDsMCxKupIAa51N2CyEhK9nych/nWQFMuX86GbuoNma1pQXurxD93z
 eGVScAgNGtNlrBQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

The wireless-controller schema specifies local-mac-address as
used in the bcm4329-fmac device nodes of Apple silicon devices
(arch/arm64/boot/dts/apple).

Fixes `make dtbs_check` for those devices.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Janne Grunau <j@jannau.net>
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

