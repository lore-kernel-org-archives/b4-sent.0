From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v2 0/2] power: supply: gpio-charger: add support for
 fast-charge timer
Date: Fri, 09 Jan 2026 19:41:18 +0100
Message-Id: <20260109-gpio-charger-timer-v2-0-63fd1ba75830@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM5LYWkC/32NQQqDMBREryJ/3ZQkmIpd9R7FhSbf5EM18iOhR
 XL3ph6gm4E3w8wckJAJE9ybAxgzJYprBX1pwIZx9SjIVQYttVFSa+E3iqJG7JHFTktV69yI6qb
 6TrVQixvjTO9z9DlUDpT2yJ/zI6uf+3cuKyHFZEzXyr6VctaPF+EUkPlq4wJDKeULhwyYYLcAA
 AA=
X-Change-ID: 20251022-gpio-charger-timer-cddae1619714
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767984085; l=1100;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=AkWfGMy7CoxX8lwk4ACgbZ8DU1m/o9H1ps5R6pef5iM=;
 b=0WZEp5rREGLi0PqgpPQAQIExjUN2H3LCmNO4sF++IuDli6gLvq2S5z2jpBBOWzPsjiaqJFJkU
 IYpeNHC/qWFAj1OBl8irj0LAwC6aSTmn09YQcHzJf5iy68IoZ7vL8LM
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
Changes in v2:
- Added Acked-by tag
- Link to v1: https://lore.kernel.org/r/20251022-gpio-charger-timer-v1-0-b557409400f2@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: power: supply: gpio-charger: add support for fast-charge timer
      power: supply: gpio-charger: add support for fast-charge timer

 .../ABI/testing/sysfs-class-power-gpio-charger     | 10 ++++++
 .../bindings/power/supply/gpio-charger.yaml        |  5 +++
 drivers/power/supply/gpio-charger.c                | 39 ++++++++++++++++++++++
 3 files changed, 54 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251022-gpio-charger-timer-cddae1619714

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

