From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v2 0/2] power: supply: gpio-charger: add support for
 default charge current limit
Date: Fri, 13 Dec 2024 20:32:32 +0100
Message-Id: <20241213-default-charge-current-limit-v2-0-45886fce905c@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANCLXGcC/32Nyw6CMBBFf8XM2jGdBsG68j8MiwKDTMLDTAvRE
 P7dSly7PPck564QWIUDXA8rKC8SZBoT2OMB6s6PD0ZpEoM1NiNrHDbc+rmPmKwmW8+qPEbsZZC
 IufNcuOxscvKQEk/lVl57/l4m7iTESd/720Lf9Rcm+h9eCA0WF3KVNzmz9bdeuOpY9VRPA5Tbt
 n0AJHglm8sAAAA=
X-Change-ID: 20241209-default-charge-current-limit-69ae7945061a
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734118360; l=1474;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Ud2wCa8TSYVfpnac2gkRPt80w1+N1OzZr1JJXuVpSps=;
 b=zf9bjiGiLdqbtu5VANIqnr1BgtHuGTzqBJeXJABZGOjH1vn14TO6pLAItRzl13cm+iFqeMyXN
 pARni1WA2NiB/AmeCBXVFbGouit8cuSLzBriVeHs7EiBsgiuvyzmPeT
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

