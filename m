From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/5] dt-bindings: net: Add network-class.yaml schema
Date: Wed, 19 Mar 2025 08:42:45 +0100
Message-Id: <20250319-dt-bindings-network-class-v4-0-2329336802b4@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHV12mcC/43Oy2oDMQwF0F8JXldBlufhySr/EbLwWGrGbfGA7
 UwfYf49nkBXhZKVEFydq5vKkoJkddjdVJIl5DDHujQvO+UnFy8CgeuuCMkgoQEuMIbIIV4yRCm
 fc3oH/+FyBmu6Xpi7fmBS9X50WWBMLvppExARuDZ4KUkEitWaqrYlp5DLnL4fTyy6jtMzfYsGh
 KYlQdO3hMjHNxeju+5rTJ0ru9DTFG3UMHS2ft9ib/5Q5pdq0Wj7H2U2ii1jw/w6dvoYvkLZ+x9
 1Xtf1DnYU6OhwAQAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2768; i=david@ixit.cz;
 h=from:subject:message-id; bh=393IToClAzfR0O1K/XE7LWt3enDS7PjgPZXQuUlFetg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2nV+fAu9Z+30XzWw6iGU1UgKuJHCa9+LbOuWu
 pyl7M0EieSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9p1fgAKCRBgAj/E00kg
 ctv1D/97fXqZxd+QFVLBALI9KOioq7nsDQmfS0I+A7jc3/po3kvHlwnbRzaeQaBSrlEYJKY4lk/
 d8SBVNM6N7CkLjDqPlCmndKHJ7W/cziirlRNp7lCsxhCq2hWvhujW0VCyvBehi66Pg7c8cYZ4f8
 XHkrIHi8U8OacZX+BhyU/hSt5FFXqCNe6yEWmv7UCBBH/qMGJr2zYUMsKU4yhnCbWlzDkOtRDAo
 7Nj67MRvgbtcm+jbao8nYtG5Zo0w3AZ9q+dUEnOlAfEiKqWPEZu20ZCYjTciW107G/eqb8ilGiA
 LLjo2GPXHayUTce193wWJB1aDRwb8+kw2SY7xVn5QD2KkQbYTStNs6jmO6lEkteuVSmodUs8fnk
 IIMwg/ltpiOYKqKJJbEEieEyv989UX54+Z5rl4iS9A1ZKsB0db71sIn1z/eD0SmQwd6R4OyRFdf
 CnPqPJh0dVRRjqhP2seJEGdXYcvfpC2ypyjBPWkyJ+sVHAcfZU7AnSDjGCqwP0n9fIIzS7ad6Uo
 6hCeM2sbc88dV+OQKHfM5+Zp3WzdzH0QZKIZv7X6y6ehHYdOd04L4JxPM4WzABXLvcyqDZUkA4g
 4TMtg7TGTMpQt025eoK3Z51tPXZMm8aDW/r54LCjstqoEkY9Elj+IwSP37qJRMFHJOujDDIcclY
 L6EwX5wnB1fSHKA==
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
 .../devicetree/bindings/net/network-class.yaml     | 47 ++++++++++++++++++++++
 .../bindings/net/wireless/brcm,bcm4329-fmac.yaml   |  2 +-
 .../bindings/net/wireless/silabs,wfx.yaml          |  5 +--
 .../bindings/net/wireless/wireless-controller.yaml | 23 +++++++++++
 .../devicetree/bindings/soc/qcom/qcom,wcnss.yaml   |  5 ++-
 6 files changed, 77 insertions(+), 30 deletions(-)
---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20230203-dt-bindings-network-class-8367edd679d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

