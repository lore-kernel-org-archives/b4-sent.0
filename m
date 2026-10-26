From: Remy Demangeot <remy@demangeot.net>
Subject: [PATCH 0/3] hwmon: (asus-ec-sensors) more MAXIMUS IX EXTREME
 sensors
Date: Mon, 26 Oct 2026 09:57:34 +0100
Message-Id: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP4V32oC/1WOy27CMBREfyXyurfyI06cCCH+A7HwY2i9cNLaB
 iEh/h1DNu3iLs5IM+feWUGOKGzu7izjGktclwbio2P+2y5foBgaM8nlINqR6ylNINwqFSxlzYX
 UxGEUjBmnwFrxJ+Mcb+/R42njjN9L265b+C+hhFLsWzR3u80j9B9PRgJdBQkapAh2kgJK8kNAe
 v231s8Fdf/yOltAfk0p1rmDcMrLQfGgnXF+1PqM3lkzBMkDN35UPZzmPTs9Hk+IzYzmBgEAAA=
 =
X-Change-ID: 20261026-b4-m9e-ext-sensors-390e83e8879d
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793005066; l=2835;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=zn8DXKlaE4UvmTPoDcyez0qpguM1Sh9lNNufMZLHhXU=;
 b=/If33aB3oe4ancoLuekn6b85La6zjisVvdKxW3O5dP1i/D9Iz7HJ+4t5gok6QzVKJSbcdMCdr
 Upgx4aayxCwBsQ+ov+wLaiI1V5v1dwnEiqv6/UVtEcq2VzuVpSIwU2n
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the remaining sensors of the MAXIMUS IX EXTREME EC
that HWiNFO reads. It applies on top of "hwmon: (asus-ec-sensors) add
MAXIMUS IX EXTREME", which Guenter applied:
https://lore.kernel.org/r/20261015-b4-m9e-extreme-v1-1-621da921e320@demangeot.net

Guenter asked why I assumed these might not be acceptable. No
particular reason: two of them need access patterns the driver does
not have yet (a selector register written before the read, and a
second EC on its own I/O ports), so I preferred to ask before touching
the read path.

 1/3: EXT_Sensor1-3, plain reads at bank 0, 0x60-0x62.
 2/3: EXT_FAN1-3 speeds, read after writing the fan number to the
      selector register 0x43, which is restored afterwards.
 3/3: the four water temperatures, on a second EC at I/O ports
      0x68/0x6c, bank 1.

Notes:
 - After 3/3, enum ec_sensors has 32 entries, which fills the
   unsigned long sensor mask on 32-bit builds. Any further sensor
   will need a wider mask (u64 and BIT_ULL()). I can send that as a
   preparatory patch if you prefer.
 - asus_ec2_wait() polls with udelay(10). checkpatch suggests
   usleep_range(), but the EC normally answers within a few
   microseconds, so I kept udelay(). Happy to change it.

A related question, independent of this series. The EC also holds the
fan curves of the extension card fans: after selecting a fan through
0x43, registers 0x4a-0x4f hold a 3-point curve (temperature in degrees
Celsius, duty 0-255) that the BIOS writes at boot. Writing these
registers changes the fan speed immediately, and writing the same duty
at the three points gives a fixed speed. My out-of-tree driver uses
this to expose pwmN and pwmN_enable (1: fixed duty through a flat
curve, 2: BIOS curve, saved at probe and restored at unload and
shutdown, and re-applied after resume), so that these fans can be
driven from userspace like the Super I/O ones.

Would write support like this be acceptable in asus-ec-sensors, or is
it better kept out of tree or in a separate driver? I understand the
driver is read-only by design, so "no" is a fine answer.

Tested on the MAXIMUS IX EXTREME (BIOS 1501): readings match HWiNFO
8.54 and the out-of-tree driver on the same machine.

---
Remy Demangeot (3):
      hwmon: (asus-ec-sensors) add EXT_Sensor temperatures for MAXIMUS IX EXTREME
      hwmon: (asus-ec-sensors) add fan extension card fans for MAXIMUS IX EXTREME
      hwmon: (asus-ec-sensors) add water temperatures for MAXIMUS IX EXTREME

 drivers/hwmon/asus-ec-sensors.c | 219 +++++++++++++++++++++++++++++++++++++---
 1 file changed, 205 insertions(+), 14 deletions(-)
---
base-commit: e1b3c2630d5b8bc755fe4ba86d20d08c734eb504
change-id: 20261026-b4-m9e-ext-sensors-390e83e8879d

Best regards,
-- 
Remy Demangeot <remy@demangeot.net>

