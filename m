From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] mfd: syscon: Give each syscon its own lockdep class
Date: Sat, 28 Nov 2026 19:06:23 +0000
Message-Id: <20261128-syscon-lockdep-v3-0-2c786aa075bf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WOyw6CMBBFf8V0bU1bpFRX/odxUdoBqkCxBSIh/
 LsFSXwtz+See2dEHpwBj46bETnojTe2DhBtN0gVss4BGx0YMcI4pTTGfvDK1ri06qahwZpGUZb
 GQrEUUJAaB5l5LIXny4t9l15BtXPLmnBw78JS+44VxrfWDcsbPZ2v6yIjv4s9xRRL0ElykITsU
 3HKK2nKnbIVmqt69qmzP50FXXBBYi65FORLn6bpCaP+AtoSAQAA
X-Change-ID: 20261115-syscon-lockdep-d133fb58c2be
To: Mark Brown <broonie@kernel.org>, Lee Jones <lee@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, driver-core@lists.linux.dev, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Heiko Stuebner <heiko@sntech.de>, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892783; l=1735;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=cl55l6BlQAsqIoctvHm7U067i4K1Kn6CwQBaA/ujpbU=;
 b=YJAEuAskfeK/igBCqgZCgGezinvd+vqT1fL3VIz7edvNs7BPB0tK2J05vKyv7cwbwGIlhaRoo
 Ax/XMfFYjjdDnUfJ9m0aX7xzijUCGH3MKE8fczpzAode8DiXLtBCB1m
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All syscon regmaps share one lockdep class, so on RK3588 lockdep reports
a false circular dependency and turns itself off. Patch 1 adds an
optional lockdep key to regmap_config, patch 2 gives each syscon one.

Patch 2 needs patch 1, so both could go through regmap with Lee's ack,
or through mfd with Mark's. Based on regmap for-next; patch 2 also
merges cleanly with for-mfd-next.

Tested on an Orange Pi 5 (RK3588S) with a 7.3 based kernel that has
out-of-tree DisplayPort patches, lockdep and KASAN on. Without the series
lockdep reports the cycle during boot. With it there is no report and
lockdep stays on.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v3:
- Move the fix into regmap: new regmap_config.lock_key; syscon passes a
  per-syscon key and drops its own lock (Lee).
- Drop the prerequisite, it is in for-mfd-next.
- Link to v2: https://patch.msgid.link/20261122-syscon-lockdep-v2-1-868056a6a808@gmail.com

Changes in v2:
- __acquires/__releases: name the argument, not a local (Sashiko).
- Link to v1: https://patch.msgid.link/20261120-syscon-lockdep-v1-1-aed779a004b8@gmail.com

---
Arun Iyengar (2):
      regmap: Add an optional lockdep class to struct regmap_config
      mfd: syscon: Give each syscon its own lockdep class

 drivers/base/regmap/regmap.c | 3 +++
 drivers/mfd/syscon.c         | 6 ++++++
 include/linux/regmap.h       | 3 +++
 3 files changed, 12 insertions(+)
---
base-commit: 222b61e9c570dac6c7a786d039e4c226624b426d
change-id: 20261115-syscon-lockdep-d133fb58c2be

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

