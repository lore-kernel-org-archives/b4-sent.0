From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v2 0/2] Add Apple Silicon SMC power driver
Date: Fri, 09 Jan 2026 00:18:47 +1100
Message-Id: <20260109-b4-macsmc-power-v2-0-93818f1e7d62@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALeuX2kC/3WNQQ7CIBBFr9LM2jGA0EZX3sN0gVPaTiKlAYOah
 ruL3bt8L/nvb5BcZJfg0mwQXebEYamgDg3QbJfJIQ+VQQnVCikM3jV6S8kTruHlIg5CdkTdaE6
 WoK7W6EZ+78VbX3nm9Azxsx9k+bP/W1miwFadjSatrDHmOnnLjyMFD30p5QtP5UOgrgAAAA==
X-Change-ID: 20260105-b4-macsmc-power-d017cc7f53ac
To: Sebastian Reichel <sre@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767878329; l=1754;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=ULItbI1yU0oVHXTe0/S32I9HO15qLNcu+lgP97nBouQ=;
 b=nPEwliGopv3tiHSTW55ltR9k7IAzFxUGeMQtuM3HZAEmI8bCau/pgyINeKM2ZSPnUnxCl0ajA
 Y5M3G9B279gDQJ1ndb8X8qMopbNEJrDuivf9tPlqQ3VcpAtCYAC0Jvd
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a power supply driver for the Apple SMC found on
Apple Silicon devices. This allows the kernel to report AC status,
battery charging status, and power metrics, and modify the charging
behaviour.

The first patch adds the driver itself, and the second patch wires it
up to the MFD core.

The driver is based on an original out-of-tree implementation by
Hector Martin. It has been refactored for upstream inclusion, 
including support for newer SMC firmwares, devices without batteries,
dynamic property detection and improved state management.

Tested on: Apple M3 (MacBook Air, J613)

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Changes in v2:
- Added Reviewed-by: Neal Gompa <neal@gompa.dev> to all patches.
- Fixed Makefile alignment by using tabs for the macsmc-power entry.
- Upgraded physical battery exhaustion log level to EMERG.
- Downgraded software-triggered orderly poweroff log level to CRIT.
- Added check for CHIS key to skip AC registration on desktop models.
- Link to v1: https://lore.kernel.org/r/20260105-b4-macsmc-power-v1-0-62954c42a555@gmail.com

---
Michael Reeves (2):
      power: supply: Add macsmc-power driver for Apple Silicon
      mfd: macsmc: Wire up Apple SMC power driver

 MAINTAINERS                         |   1 +
 drivers/mfd/macsmc.c                |   1 +
 drivers/power/supply/Kconfig        |  11 +
 drivers/power/supply/Makefile       |   1 +
 drivers/power/supply/macsmc-power.c | 883 ++++++++++++++++++++++++++++++++++++
 5 files changed, 897 insertions(+)
---
base-commit: cc3aa43b44bdb43dfbac0fcb51c56594a11338a8
change-id: 20260105-b4-macsmc-power-d017cc7f53ac

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

