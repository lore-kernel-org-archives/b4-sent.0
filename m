From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v5 0/5] dt-bindings: net: Add network-class.yaml schema
Date: Mon, 24 Mar 2025 18:41:37 +0100
Message-Id: <20250324-dt-bindings-network-class-v5-0-f5c3fe00e8f0@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFKZ4WcC/43O20oEMQwG4FdZem2WNJlDx6t9D/GiM4m7VelAW
 8fDMu9uRxEFYdmrEPjz/TmbrCloNre7s0m6hBzmWJf2Zmemk49HhSB1N4TESMggBcYQJcRjhqj
 ldU5PMD37nMFx16tI1w9Cpt6PPiuMycfptAmICFIbJi1JFYqzlqq2JU8hlzm9fz2x2DrurulbL
 CA0LSly3xKiHB59jP5lX2PmvrILXU3RRg1D5+r3Lfb8j+IfqkW27hLFGyVOsBF5GDt7CG+h7Ke
 Pb6f56wyXnKY6xDQwdw5pbH6ddV0/AcDuXAC4AQAA
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
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>, 
 Mailing List <devicetree-spec@vger.kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2987; i=david@ixit.cz;
 h=from:subject:message-id; bh=sdcuRNAQFYtob6yEPETsohJyFlIPNbv+Zn2NcH7jrWI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn4ZlTrhhrbvdN7q/q0xl8VBJwCdheUpabZJum5
 tkfNRJDy32JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+GZUwAKCRBgAj/E00kg
 cjJoD/445obenDkJ2ww6j/V4OnGgHkP5M0egpahzT0SriANaT7QkIObfDbx9udE25Un6znndbgt
 8vUbYA91FAokbS4DkynY4cXKxi46j7HOYnAicew45FZGRZaLajzGiIXVwvuQXn/F7hJtLDmUBUK
 XrOlCDQrtMRKfH06dxoZITN9SWhp3aBm6Huq+9nBnw+xIkQUblfcWFdnRWkcyn/6tuuYZMvBnwJ
 K66LZW3tL8nHZiEzrIMX3CD63GUo2kGfzqK3cmB7j9Dp3WGC0jh8iCgjUY2bsZije1q8K1m40OQ
 LSmgTZJctX903izdObj6fvhuOl0nqvVBv+X9IZbL7EA9ykSdACJE4S4NoLnt6knBmcDJOCYwO/o
 JaHIQh7VP9OuBX2raJcNMy3XcM3N+EdP6wH7omOzTeFMPiR299/EFLUnSl49NTdho+792cDHc9f
 46IwQ0P3TDkfxNAtFAR2rXkzwwdWNASfz5JuvrpnUvY1NI5PpUwjQ30sG088EOPKdBUMlrOEIKL
 ee20LJGG2aOL0vD+dJnzrqXQv2uCr7P3Edm/ea+ZPXOJ89mOF0gGw5cuGXH3AYAUIFTpLd1rXQW
 0D4esR1/YpfKoxq/0S2FUFdpqCk+MhTF/FQy+rcfD7PtVhecHx9VZZBqZKP+KYAJCfbXCS4AVwp
 haOaR4i1hClUEsA==
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
Changes in v5:
- Incorrect DCO chain, missing SoB. (Krzysztof)
- Improved address-bits description. (Krzysztof)
- Link to v4: https://lore.kernel.org/r/20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz

Changes in v4:
- Changed the mailing list address (Rob)
- Copyied the whole description for the max-frame-size, including the
  MTU x max-frame-size contradiction. (Rob)
- Link to v3: https://lore.kernel.org/r/20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz

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
 .../devicetree/bindings/net/network-class.yaml     | 46 ++++++++++++++++++++++
 .../bindings/net/wireless/brcm,bcm4329-fmac.yaml   |  2 +-
 .../bindings/net/wireless/silabs,wfx.yaml          |  5 +--
 .../bindings/net/wireless/wireless-controller.yaml | 23 +++++++++++
 .../devicetree/bindings/soc/qcom/qcom,wcnss.yaml   |  5 ++-
 6 files changed, 76 insertions(+), 30 deletions(-)
---
base-commit: 882a18c2c14fc79adb30fe57a9758283aa20efaa
change-id: 20230203-dt-bindings-network-class-8367edd679d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

