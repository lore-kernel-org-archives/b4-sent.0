From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v3 0/2] Add Apple Silicon SMC power driver
Date: Thu, 15 Jan 2026 18:08:14 +1100
Message-Id: <20260115-b4-macsmc-power-v3-0-c236e09874be@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF+SaGkC/3WNyw6CMBBFf4V0bU07UF4r/8O4qMMATSwlrakaw
 r9bWJEYl+cm59yFBfKGAmuzhXmKJhg3JchPGcNRTwNx0yVmIKAUUih+L7jVGCzy2b3I807ICrH
 qVa6RJWv21Jv3XrzeEo8mPJ3/7AdRbuv/VpRc8BIaVWABWil1Gaw2jzM6y7ZWhKPf/PqQ/CavZ
 d1LqroSjv66rl8n4xcR7gAAAA==
X-Change-ID: 20260105-b4-macsmc-power-d017cc7f53ac
To: Sebastian Reichel <sre@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768460903; l=2212;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=7ZuDFsWT2gxxq3ujMvtSzPih5aeosnU4qUGhtGU18+o=;
 b=ZqocKdTEOkpTOndAfW3elALKsRlonSok214dv4pvVbnLBEpl//qZUsBW7DJ3g8mvf1YbcDtEF
 6pBqk5v+n0sAmAuvweaEXSglpBwNgYtXbypJpVc8UzHA7hiE0FzDIOr
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
Changes in v3:
- Rebase on top of latest linux-next
- Drop charge control threshold properties.
- Switch to devm_work_autocancel() for critical work.
- Add platform ID table and remove MODULE_ALIAS.
- Simplify property array management in struct macsmc_power.
- Improve probe error handling and device pointer usage.
- Minor style and indentation fixes.
- Link to v2: https://lore.kernel.org/r/20260109-b4-macsmc-power-v2-0-93818f1e7d62@gmail.com

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
 drivers/power/supply/macsmc-power.c | 834 ++++++++++++++++++++++++++++++++++++
 5 files changed, 848 insertions(+)
---
base-commit: b775e489bec70895b7ef6b66927886bbac79598f
change-id: 20260105-b4-macsmc-power-d017cc7f53ac

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

