From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/5] dt-bindings: net: Add network-class.yaml schema
Date: Tue, 18 Mar 2025 20:56:43 +0100
Message-Id: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPvP2WcC/42OzQrCMBCEX6Xk7Mp2Y/88+R7iIU2WNiopJLEip
 e/u1pu3noaBmW9mUYmj56TOxaIizz75KYjRh0LZ0YSBwTvxipA0EmpwGXofnA9DgsD5PcUH2Kd
 JCVpdN+xc3XSOlPR7kxj6aIIdNwIigpMFyzkyQ27LkoS2JUef8hQ/vxNzKXLdszeXgHCqiFE3F
 SG6y92EYF5HiambYGfajaIN1XV1K+8rbPQfal3XL+TR8NAoAQAA
X-Change-ID: 20230203-dt-bindings-network-class-8367edd679d2
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2490; i=david@ixit.cz;
 h=from:subject:message-id; bh=7W8QpbQv5teMaSOlvTSkrQIpc6ejHxAGQeFyZZG7vrs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2c/+j6DMvXwXlPePgX3PHddA4M1piRIGjZllm
 N+DF+5cZ62JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9nP/gAKCRBgAj/E00kg
 chroD/9vAs2g7yo2x2daiSwFvP2LReGaABPJ+K/Kmjr5AS+X+QJkFZXeJr3xzmKxGjzv4HRisY1
 0CFZPU+EiE4tulRle9WoXr7ayonKJtFnuzmd0nLMYQtJpqfabPolWqAIXSmUqPtjgaUwUPvoVll
 S1SKbU5tPNORhH6lwFbqdjb9Wqg9OkN/3bELAVEhXgXCoXFJ17fA46N+vkPWXRdsem0gijUAOUF
 0UWJNNEMrC3T6BB7gLOxjAp0L+k093wSflp+3FPH2QHR+07SMFKTnr/qHcHEfvWPjpwQuB78uOh
 V5DSLc4zt9dokk9ZP7lmYi3x1HuGDt9/yjrH3ymPgXuU39+sSP79iwzojlf56igEry4RkKVVF47
 a00kqS1PDZx4UZRsbIEoio7fKlnXNEBZf7pilWxqlE5OdzaDvwLLh9wAV8UgHLjyfgcZWuxDEgw
 ix5RM75HA/ZpzORoDGCGydOavRc/eXRGS4ZYIzDABpgPvmmlsTHiPMP6owT0lU8uG4/qhOO1ki9
 MBi4+L1v3NoyEh/pe1zYh8zYy5nZ6yHYxlRIpfSqTSH1OVQ+AdEa01n+dUafH7mDFPPj/CLeDwe
 SZPCS73I+WI72g/GsJsBVuUzOR5Dt6snywG0Tt2ClvDhP5JT2+8MR9WTUQMvHt+O+k0ym+7f7E+
 frkEV2LqN7wTNTA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Devicetree Specification, Release v0.3 specifies in section 4.3.1
a "Network Class Binding". This covers MAC address and maximal frame
size properties. "local-mac-address" and "mac-address" with a fixed
"address-size" of 48 bits are already in the ethernet-controller.yaml
schema so move those over.

Keep "address-size" fixed to 48 bits as it's unclear if network protocols
using 64-bit mac addresses like ZigBee, 6LoWPAN and others are relevant for
this binding. This allows mac address array size validation for ethernet
and wireless lan devices.

"max-frame-size" in the Devicetree Specification is written to cover the
whole layer 2 ethernet frame but actual use for this property is the
payload size. Keep the description from ethernet-controller.yaml which
specifies the property as MTU.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Incorporated wireless-controller.yaml suggestion (Andrew)
- Link to v2: https://lore.kernel.org/r/20230203-dt-bindings-network-class-v2-0-499686795073@jannau.net

Changes in v2:
- Added "max-frame-size" with the description from ethernet-controller.yaml
- Restrict "address-size" to 48-bits
- Fix the mac-address array size to 6 bytes
- Drop duplicate default value from "max-frame-size" description
- Link to v1: https://lore.kernel.org/r/20230203-dt-bindings-network-class-v1-0-452e0375200d@jannau.net

---
David Heidelberg (2):
      dt-bindings: net: Add generic wireless controller
      dt-bindings: wireless: qcom,wcnss: Use wireless-controller.yaml

Janne Grunau (3):
      dt-bindings: net: Add network-class schema for mac-address properties
      dt-bindings: wireless: bcm4329-fmac: Use wireless-controller.yaml schema
      dt-bindings: wireless: silabs,wfx: Use wireless-controller.yaml

 .../bindings/net/ethernet-controller.yaml          | 25 +-----------
 .../devicetree/bindings/net/network-class.yaml     | 44 ++++++++++++++++++++++
 .../bindings/net/wireless/brcm,bcm4329-fmac.yaml   |  2 +-
 .../bindings/net/wireless/silabs,wfx.yaml          |  5 +--
 .../bindings/net/wireless/wireless-controller.yaml | 23 +++++++++++
 .../devicetree/bindings/soc/qcom/qcom,wcnss.yaml   |  5 ++-
 6 files changed, 74 insertions(+), 30 deletions(-)
---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20230203-dt-bindings-network-class-8367edd679d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

