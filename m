From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v7 0/4] hwmon: pmbus: add MPS MPQ8646 support
Date: Thu, 30 Jul 2026 17:43:58 +0200
Message-Id: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD5xa2oC/3XPTW4DIQwF4KtErEsFGAOTVe8RVRW/DYsmKROhV
 tHcvZ6sBqmzfJa+Z/vB5txqntnx8GAt9zrX64WCfTmwePaXz8xrosyUUEZYBfzr9u2MNh9dcAA
 HMaDVyXpG4NZyqT/PstM75XOd79f2++zucp3+W9MlF1xqMBAtTtKUt9Jyfi2NrSVd7UNFEKKOw
 cqiIIoRwj6EdaMvskAC57Qbod6HmmAwoCBhiaj0CHEL9QCRID2HAX2evFcjNFs4DdAQnNYbJcq
 Ywmbjsix/1TwnAb8BAAA=
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785426244; l=6925;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=3iDUiCnsFYnzTLKv3nb+4gpu8mkR6j8++KHr1PvRxP0=;
 b=0BS/v/XurP/AYzHoBTHPNMpvbz/ZLq61vXjTPMb744ZA4VMP/2z791HTiLQpM4wIy75Ca3/Us
 tCHimB0pDzvDNDiQETIryg6u4w0djwrVYn8vlCZ8R/9hBzGbWlKLmp0
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Monolithic Power Systems MPQ8646 step-down
converter as a PMBus device.

  1/4 pmbus core: export pmbus_check_and_notify_faults() so a chip
      driver can run the SMBALERT# path check and notify sequence
      from a polling work item when the chip's SMBALERT# pin is
      unavailable to the CPU.
  2/4 dt-bindings: add the MPQ8646 compatible to the existing
      mps,mpq8785 schema (same mps,vout-fb-divider-ratio-permille
      property, same constraints).
  3/4 the MPQ8646 driver: PMBus telemetry
  4/4 the provisioning/NVM write entries, compiled out by default
      thanks to SENSORS_MPQ8646_DEBUG_UNSAFE.

To: Guenter Roeck <linux@roeck-us.net>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
To: Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>
Cc: linux-hwmon@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Signed-off-by: Vincent Jardin <vjardin@free.fr>

Changes in v7:
- driver: named initializer for the i2c_device_id table (reported by
  the Sashiko AI, confirmed by Guenter Roeck it is a real issue)
- add pmbus_lock in every debugfs accessor that touches, so reads cannot
  race the pmbus core and no write can slip through while
  clear_protection_last_force temporarily lowers WRITE_PROTECT
  (reported by the Sashiko AI, confirmed by Guenter Roeck)
- propagate the i2c error codes from the debugfs write handlers instead
  of returning success
- explicit Kconfig and documentation warnings, and add a WARNING banner
  at probing of the device. (requested by Guenter Roeck)
- reword some commit logs (reported by Markus Elfring)
- Link to v6: https://lore.kernel.org/r/20260729-mpq8646_v0-v6-0-98848151cdb4@free.fr

Changes in v6:
- core: replace the pmbus_get_hwmon_device() accessor with an exported
  pmbus_check_and_notify_faults() (suggested by Guenter Roeck on v5)
- driver: drop the bring-up probe/instrumentation debugfs entries
  (challenged by Guenter Roeck on v4)
- new patch 4/4: move the write/provisioning debugfs entries
  behind a new default-n SENSORS_MPQ8646_DEBUG_UNSAFE
- move the debugfs files into the client's pmbus debugfs directory
  (pmbus_get_debugfs_dir()), mask using VOUT_MODE checks, MPQ8646_DEBUG()
  using dev_dbg(), drop the 0xFF VOUT_MODE probe check and the
  source-attribution comments (many inline reviews reported
  by Guenter Roeck on v5)
- driver: drop the WRITE_PROTECT read shim: the HW implements the
  register (reads back 0x00, unprotected), so the core handles write
  protection as designed (reported by Guenter Roeck on v5)
- dt-bindings: fold the MPQ8646 into the existing mps,mpq8785.yaml
  (suggested by Krzysztof Kozlowski on v5)
- scope locking, guard() and scoped_guard() (suggested by Markus
  Elfring on v5)
- XXX TBD: should pmbus_check_and_notify_faults() also update
  the pmbus registered thermal zones, or is that follow-up material ?
  Currently, neither the SMBALERT# path nor this helper does it.
- Link to v5: https://lore.kernel.org/r/20260724-mpq8646_v0-v5-0-5915b5ae9aa2@free.fr

Changes in v5:
- driver: fix the hwmon channel indices used by the in*_alarm poll
  notifications (thanks Sashiko AI, v4)
- driver: remove the shared debugfs root on module unload, by creating
  it in module_init() and removing it in module_exit(). It also drops
  the v4 per-probe root mutex and debugfs_lookup()
  (Sashiko AI review of v4)
- doc: add Documentation/hwmon/mpq8646.rst to the toctree (kernel test robot)
- doc: fix a malformed table and drop the stale probe_page_write row
  (removed since v3) and fix typo
- Link to v4: https://lore.kernel.org/r/20260723-mpq8646_v0-v4-0-b6323d5fc524@free.fr

Changes in v4 (all reported by the Sashiko AI review on v3):
- driver: register debugfs only after a successful pmbus_do_probe() --
  the debugfs handlers take pmbus_lock() and rely on the pmbus clientdata
  that pmbus_do_probe() installs (NULL-deref window in v3)
- driver: in remove(), unregister debugfs before cancel_delayed_work_sync()
  so a debugfs write cannot re-arm the poll worker after it is cancelled
- driver: serialise the shared debugfs root create against concurrent
  probes with a static mutex
- driver: move the remaining last_probe_* updates (clear_protection_last,
  store_all, restore_all) inside mps_lock
- dt-bindings: describe the hardware, not the driver, in the description
- Link to v3: https://lore.kernel.org/r/20260723-mpq8646_v0-v3-0-1af1f3d38848@free.fr

Changes in v3 (all reported by the Sashiko AI review on v2):
- driver: alarm_poll_interval_ms is now a debugfs fops
- driver: pmbus_lock() around the async raw i2c accesses: the poll
  worker and the CLEAR_LAST_FAULT force sequence, the nvmem snapshot read
  keeps mps_lock (read-only, no chip-state change)
- driver: update last_probe_rc/last_probe_data under mps_lock to avoid
  torn diagnostics
- driver: remove the dead PMBUS_PAGE swallow in write_byte
- driver: remove the probe_page_write debugfs hook
- Link to v2: https://lore.kernel.org/r/20260723-mpq8646_v0-v2-0-3c4cb71f23c0@free.fr

Changes in v2:
- driver: register debugfs only after the DT-property validation, to
  avoid an early probe error to avoid dangling debugfs entries
- driver: do not schedule the alarm-poll worker when SMBALERT# (irq)
  is wired, and do not re-arm it from the worker in that case
- driver: dput() the dentry returned by debugfs_lookup()
- driver: hold mps_lock around the nvmem snapshot reads
- driver: fix VID coefficients comment
- dt-bindings: fix typo of the commit message
- Link to v1: https://lore.kernel.org/r/20260723-mpq8646_v0-v1-0-14363c75916f@free.fr

---
Vincent Jardin (4):
      hwmon: (pmbus/core) export pmbus_check_and_notify_faults()
      dt-bindings: hwmon: pmbus: add MPS MPQ8646
      hwmon: pmbus: add MPQ8646 driver
      hwmon: pmbus: mpq8646: gate the writes

 .../bindings/hwmon/pmbus/mps,mpq8785.yaml          |   5 +-
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/mpq8646.rst                    | 300 +++++++
 MAINTAINERS                                        |   7 +
 drivers/hwmon/pmbus/Kconfig                        |  31 +
 drivers/hwmon/pmbus/Makefile                       |   1 +
 drivers/hwmon/pmbus/mpq8646.c                      | 976 +++++++++++++++++++++
 drivers/hwmon/pmbus/pmbus.h                        |   1 +
 drivers/hwmon/pmbus/pmbus_core.c                   |  14 +-
 9 files changed, 1332 insertions(+), 4 deletions(-)
---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260723-mpq8646_v0-3383cb574d7a

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

