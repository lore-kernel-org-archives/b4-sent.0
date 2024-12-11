From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] power: supply: gpio-charger: add support for default
 charge current limit
Date: Wed, 11 Dec 2024 08:29:08 +0100
Message-Id: <20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEQ/WWcC/x3MSwqFMAxA0a1Ixgba4oe+rYiDolED2idpFUHcu
 8Hh5cC9IZEwJfgVNwidnPgfNWxZwLCEOBPyqA3OuMo643GkKRxrRlVRHQ4RihlX3jhj4wO1vqp
 NYwPoYhea+Pr2Xf88L+ON9wBuAAAA
X-Change-ID: 20241209-default-charge-current-limit-69ae7945061a
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733902172; l=780;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=z7Dc5FJTPUHHlOFfQcHtMzEV5zoZUD9OFcQgozB76GM=;
 b=QN+vCWDtq5aI6nCehjbU2+5I8rT3UTY0ytF/rlzS2w5tLUv2ivyxP4cP4PAz5Vj2PmXyH5Cef
 1A1I1Q2ehIlBvjV4jcrNPfjkFwYeQYJwheKvL3xQK4rOC8GXJXDHt7Y
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver defaults to smallest current limitation for safety reasons. Add
support for setting default current limitation via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      dt-bindings: power: supply: gpio-charger: add support for  default charge current limit
      power: supply: gpio-charger: add support for  default charge current limit

 .../devicetree/bindings/power/supply/gpio-charger.yaml      |  4 ++++
 drivers/power/supply/gpio-charger.c                         | 13 +++++++++++++
 2 files changed, 17 insertions(+)
---
base-commit: 88e4a7dc04b7828315292eb3acaa466c9c123d8b
change-id: 20241209-default-charge-current-limit-69ae7945061a

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

