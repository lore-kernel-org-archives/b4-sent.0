From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] power: supply: gpio-charger: add support for
 fast-charge timer
Date: Wed, 22 Oct 2025 21:47:46 +0200
Message-Id: <20251022-gpio-charger-timer-v1-0-b557409400f2@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOI0+WgC/x2MSwqAMAwFryJZW2iKH/Qq4qLYWLOwSioiFO9uc
 DMwDO8VyCRMGcaqgNDNmY+kgnUFy+ZTJMNBHZx1LVrnTDz5MJokkpiLd+USgifscOixAR2eQis
 //+k0v+8HfnBUnWQAAAA=
X-Change-ID: 20251022-gpio-charger-timer-cddae1619714
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761162472; l=955;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=OOWdg8OLvSFMbIcc+BI5b8nhes+ym73swFUSBnZalNE=;
 b=PpF7pZWzkkC9XfQLaGcpxqv3v7GM9YR01a9GQv+9HJL/ePXifr+Ey3xAY4D63kEjuBRAihdxS
 vMZkvV1K0xgBDQjEVhfeUSBLDzkmzEDf1AeUtx1xQea+cVr6Gf0WWTw
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some devices like TIs BQ24081 battery charger it is possible to activate
or deactivate a fast-charge timer that provides a backup safety for charge
termination. In case of the BQ24081 it is a fixed 7-hour timer. Add support
for enabling/disabling the fast-charge timer via GPIO.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      dt-bindings: power: supply: gpio-charger: add support for fast-charge timer
      power: supply: gpio-charger: add support for fast-charge timer

 .../ABI/testing/sysfs-class-power-gpio-charger     | 10 ++++++
 .../bindings/power/supply/gpio-charger.yaml        |  5 +++
 drivers/power/supply/gpio-charger.c                | 39 ++++++++++++++++++++++
 3 files changed, 54 insertions(+)
---
base-commit: 3a8660878839faadb4f1a6dd72c3179c1df56787
change-id: 20251022-gpio-charger-timer-cddae1619714

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

