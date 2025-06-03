From: Shmuel Leib Melamud <smelamud@redhat.com>
Subject: [PATCH v3 0/2] renesas: Renesas R-Car Gen4 watchdog driver
Date: Tue, 03 Jun 2025 06:06:03 +0300
Message-Id: <20250603-us-renesas-watchdog-v3-0-af3a65afd03e@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJtmPmgC/32NQQ6CMBBFr0Jm7ZhaBMWV9zAsysxAu5CaDqKGc
 HcrB3D5XvLfX0AlBVG4FAskmYOGOGYodwWQd+MgGDgzWGMrU5UGn4pJRlGn+HITeY4DWjo13HV
 cEVvIy0eSPry36q3N7INOMX22k9n+7P/ebPGAneFz39RUH5muSdi7aU/xDu26rl9bqop8twAAA
 A==
X-Change-ID: 20250530-us-renesas-watchdog-2c79dbbd5cd2
To: Nobuhiro Iwamatsu <iwamatsu@nigauri.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Tom Rini <trini@konsulko.com>, Stefan Roese <sr@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>
Cc: u-boot@lists.denx.de, Shmuel Leib Melamud <smelamud@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748919978; l=1660;
 i=smelamud@redhat.com; s=20250530; h=from:subject:message-id;
 bh=1jLyNp9OLZlEl3G2bx9eOEVl4koCn3TPWeSL6l4fnbQ=;
 b=JWLFX1cWBEAfQb+hiMKFVfIicYofSQHtIkxZz2ZYBzpa2jVakZ0KA1sY0OKwFNSlcokBdY43o
 8UzEeCQ0YL0C4NX+Ob7zTw5IowNekl6wTVjyh1ubuLUtS/vK43/ExWJ
X-Developer-Key: i=smelamud@redhat.com; a=ed25519;
 pk=B1DFtpdxDPQudtnqMHSFRRSJziu3zB49J6oZUBo0qI8=
X-Endpoint-Received: by B4 Relay for smelamud@redhat.com/20250530 with auth_id=418
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These series add support of Renesas R-Car Gen4 watchdog timer.
Timeouts up to 8184.0s are supported (CKS1 register is not involved).
The watchdog uses the clock type CLK_TYPE_GEN4_MDSEL, so a separate
patch adds handling of this constant to gen3_clk_get_rate64() function.

The series were tested on real Renesas R8A779F0 hardware. If the
watchdog driver is enabled at the build time, the watchdog timer is
initialized when U-Boot starts. Under normal circumstances, U-Boot loads
the kernel, it starts systemd and systemd continues to pet the watchdog.
If systemd is not started before the timeout expires, the watchdog
resets the board.

Signed-off-by: Shmuel Leib Melamud <smelamud@redhat.com>

---
Changes in v3:
- Reference to the Linux driver added.
- Clock driver change moved to a separate patch.
- rwdt_ prefix used everywhere instead of renesas_wdt_.
- Disable the clock if rwdt_probe() fails.
- List of compatibles updated.
- Link to v2: https://lore.kernel.org/r/20250530-us-renesas-watchdog-v2-1-b0d8f96c64dc@redhat.com

---
Shmuel Leib Melamud (2):
      renesas: Handle CLK_TYPE_GEN4_MDSEL in gen3_clk_get_rate64()
      renesas: Renesas R-Car Gen4 watchdog driver

 drivers/clk/renesas/clk-rcar-gen3.c |   4 +-
 drivers/watchdog/Kconfig            |   8 ++
 drivers/watchdog/Makefile           |   1 +
 drivers/watchdog/renesas_wdt.c      | 182 ++++++++++++++++++++++++++++++++++++
 4 files changed, 194 insertions(+), 1 deletion(-)
---
base-commit: 3b6760ddeb4ef940226921017cd9088c89784b01
change-id: 20250530-us-renesas-watchdog-2c79dbbd5cd2

Best regards,
-- 
Shmuel Leib Melamud <smelamud@redhat.com>

