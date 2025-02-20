From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/3] net: Convert Gianfar (Triple Speed Ethernet
 Controller) bindings to YAML
Date: Thu, 20 Feb 2025 18:29:20 +0100
Message-Id: <20250220-gianfar-yaml-v1-0-0ba97fd1ef92@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHBmt2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIwNL3fTMxLy0xCLdysTcHN1EM1MTIzPjJHNTYxMloJaCotS0zAqwcdG
 xtbUAxNiZJl4AAAA=
X-Change-ID: 20250209-gianfar-yaml-a654263b7534
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Claudiu Manoil <claudiu.manoil@nxp.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740072564; l=1474;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=sOsK+4XV+btUJLsdx7CeyNqNlxi14iZGQDMYRhXYexo=;
 b=Lr6gbM7OQjCNKXzFicdyKKCHoUMa+JItK8YHuHAKUwAYcg8ebgyT+I7l15eNKiuwGDztq/RQm
 ObsbmXf51vwCxnj/C/HLivLaAD7358ip46IoaKOqScMUbFVgjSPIUMq
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The aim of this series is to modernize the device tree bindings for the
Freescale "Gianfar" ethernet controller (a.k.a. TSEC, Triple Speed
Ethernet Controller) by converting them to YAML.

Known issues that require a solution:
- fsl,gianfar-mdio.yaml (MDIO bus) and fsl,gianfar.yaml (Ethernet
  controller) both specify "gianfar" as a possible compatible string. If
  compatible = "gianfar" is used, the device_type property determines
  whether the node is an MDIO controller or an Ethernet controller.
  This confuses the DT schema validation tools:

  Warning: Duplicate compatible "gianfar" found in schemas matching "$id":
           http://devicetree.org/schemas/net/fsl,gianfar-mdio.yaml#
           http://devicetree.org/schemas/net/fsl,gianfar.yaml#

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (3):
      dt-bindings: net: Convert fsl,gianfar-{mdio,tbi} to YAML
      dt-bindings: net: fsl,gianfar-mdio: Update information about TBI
      dt-bindings: net: Convert fsl,gianfar to YAML

 .../devicetree/bindings/net/fsl,gianfar-mdio.yaml  |  93 ++++++++
 .../devicetree/bindings/net/fsl,gianfar.yaml       | 242 +++++++++++++++++++++
 .../devicetree/bindings/net/fsl-tsec-phy.txt       |  80 +------
 3 files changed, 338 insertions(+), 77 deletions(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250209-gianfar-yaml-a654263b7534

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

