From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v3 0/2] power: supply: gpio-charger: add support for
 fast-charge timer
Date: Mon, 23 Mar 2026 17:04:05 +0100
Message-Id: <20260323-gpio-charger-timer-v3-0-885796d681a5@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHVkwWkC/33NzwqDMAwG8FeRnteRVKtzp73H2ME/UQNzlVTKh
 vjuq8IuY+wS+PKRXxblSZi8OieLEgrs2T1iSA+Jaobq0ZPmNmZlwFgEY3Q/sdOxkp5EzzzG2bR
 tRZhjWWCm4uEk1PFzR6+3mAf2s5PX/iPgtv3LBdSga2uLDMoMoDOXO1M9kMixcaPaxGA+Sg4I5
 U/FRCVPuxbrqrCnFL6UdV3fb9fHQ/0AAAA=
X-Change-ID: 20251022-gpio-charger-timer-cddae1619714
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774281855; l=1525;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Y1S4gRWDT82nQeaTX8Gz/Jb68lDNGp+fLZnAgEz73ac=;
 b=maxne++y9cRaEJbfP+x+FLR324e8XhkSRWugooGHK7LUoiQIrNU15zct1vh/m8rVIZoVzFAI1
 R64jm/kq/8RDR6A2J0OUuEymRjoF7XOv81IrYxKRkRGcU4KfyaiQQWR
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
Changes in v3:
- Add documentation for fast_charge_timer
- Add a compatible for the BQ24081 (using gpio-charger as fallback) and
  then only allow 'fast-charge-timer-gpios' for the BQ24081.
- Add sample in device-tree bindings
- Removed acked-by from Connor because device-tree bindings changed
- Link to v2: https://lore.kernel.org/r/20260109-gpio-charger-timer-v2-0-63fd1ba75830@liebherr.com

Changes in v2:
- Added Acked-by tag
- Link to v1: https://lore.kernel.org/r/20251022-gpio-charger-timer-v1-0-b557409400f2@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: power: supply: gpio-charger: add support for fast-charge timer
      power: supply: gpio-charger: add support for fast-charge timer

 .../ABI/testing/sysfs-class-power-gpio-charger     | 14 ++++++
 .../bindings/power/supply/gpio-charger.yaml        | 22 ++++++++-
 drivers/power/supply/gpio-charger.c                | 56 +++++++++++++++++++++-
 3 files changed, 90 insertions(+), 2 deletions(-)
---
base-commit: aa2132799817fb052d95a87f0c23cc6af38541c0
change-id: 20251022-gpio-charger-timer-cddae1619714

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

