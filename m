From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v3 0/2] power: supply: gpio-charger: add support for
 default charge current limit
Date: Wed, 18 Dec 2024 09:34:59 +0100
Message-Id: <20241218-default-charge-current-limit-v3-0-b26118cf06b5@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADOJYmcC/4XNywrCMBCF4VcpWRtJ0mtc+R7iIk2ndqAXmaRBK
 X130+JCXOjynwPfLMwBITh2ShZGENDhNMZIDwmznRlvwLGJzZRQmVRC8wZaM/eex5XiamciGD3
 vcUDPC22g1FkuCmlYJO4ELT52/nKN3aHzEz33b0Fu1zcs5W84SC54WUldG1EAKHPuEeoOiI52G
 thmB/XppX88Fb0sr6qitaBFbr+8dV1fjFA2LBsBAAA=
X-Change-ID: 20241209-default-charge-current-limit-69ae7945061a
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734510905; l=1729;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=+QDle9JEkjDQ/QxtUf4707ZXIzare578DXwCr4H8Ixw=;
 b=AA7hl+bQkoeVXU0gCuOpYd+ewT4c9d+ccmAsRG23kspyCjmivC0iGHf0yAPSXO4a+n8dNivw5
 WI6XFA2jAHzDHJDSoCaAE5ULGGFE2zlujAAHNBdLZrPL1ovJW6bcqsG
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With DT properties charge-current-limit-gpios and
charge-current-limit-mapping one can define charge current limits in uA
using up to 32 GPIOs. At the moment the driver defaults to smallest charge
current limitation for safety reasons. When disabling charging is
supported, which should be common, the driver defaults to non charging on
probe. By having a default, charging can be enabled on probe for such
devices.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- Fix commit msg for "dt-bindings: power: supply: gpio-charger: add support for default charge current limit"
  Add use case
- Link to v2: https://lore.kernel.org/r/20241213-default-charge-current-limit-v2-0-45886fce905c@liebherr.com

Changes in v2:
- renamed DT property charge-current-limit-default to
  charge-current-limit-default-microamp
- Added dependency on charge-current-limit-mapping
- Added intention and use case to commit descriptions
- Added charge-current-limit-default-microamp in bindings example
- Link to v1: https://lore.kernel.org/r/20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: power: supply: gpio-charger: add support for default charge current limit
      power: supply: gpio-charger: add support for default charge current limit

 .../devicetree/bindings/power/supply/gpio-charger.yaml      |  6 ++++++
 drivers/power/supply/gpio-charger.c                         | 13 +++++++++++++
 2 files changed, 19 insertions(+)
---
base-commit: 57cb041f61d4abcf8dfa41259df27d081ab4cb6a
change-id: 20241209-default-charge-current-limit-69ae7945061a

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

