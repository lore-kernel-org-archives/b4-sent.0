From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v5 0/3] hwmon: pmbus: add MPS MPQ8646 support
Date: Fri, 24 Jul 2026 01:55:26 +0200
Message-Id: <20260724-mpq8646_v0-v5-0-5915b5ae9aa2@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO6pYmoC/3XNTQ7CIBCG4asY1mKAGX505T2MMS0Fy8K2giGap
 neXdmOa2OU3yfPOSJKLwSVy2o0kuhxS6Lsy5H5HbFt1d0dDUzYRTCimBdDH8DQK1S0zCmDA1lJ
 joytSwBCdD+8ldrmW3Yb06uNnaWc+X/9mMqeMcgQFVssjV/7so3MHH8kcyWIbigLBoq019wIsW
 0PYhjB/rDz30IAxaNYQtyEWWCsQ0EhvpcAfnKbpC740YtRNAQAA
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784850929; l=4434;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=U16UC5BvUuRszpY0VNExfYqCXucGSF+t90LbRKL/D5U=;
 b=Yfsiaz1e7e+/mBd38gICpzAOLOPjCEW/bigTM1GTVgd/lpH8jTBnUYsqyVFLdDrRNFWmkU4FC
 gbIo354oQ/cD+ElBX7vdb6fYEGqSWK8/UUUtE+sfdWJLYp3VtMcR1YI
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Monolithic Power Systems MPQ8646 step-down
converter as a PMBus device.

  1/3 pmbus core: add and export pmbus_get_hwmon_device() so a chip
      driver can call hwmon_notify_event() from an in-driver
      alarm-poll fallback (lm90-style) on boards where the chip's
      SMBALERT# pin is unavailable to the CPU.
  2/3 dt-bindings: the MPQ8646 binding; schema inspired from the
      mpq8785 (same mps,vout-fb-divider-ratio-permille property).
  3/3 the MPQ8646 driver: PMBus telemetry plus MFR_CFG_EXT
      gate-close retry after CLEAR_LAST_FAULT, alarm acknowledge via
      inX_reset_history, MPS-extended STATUS_WORD decode and
      post-mortem clear, the alarm-poll fallback for boards without
      SMBALERT, and on_off_config / vout_margin / mfr_pmbus_lock
      sysfs.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
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
Vincent Jardin (3):
      hwmon: pmbus: event notification with alarms
      dt-bindings: hwmon: pmbus: add MPS MPQ8646 binding
      hwmon: pmbus: add MPQ8646 driver

 .../bindings/hwmon/pmbus/mps,mpq8646.yaml          |   50 +
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/mpq8646.rst                    |  313 +++++
 MAINTAINERS                                        |    8 +
 drivers/hwmon/pmbus/Kconfig                        |   11 +
 drivers/hwmon/pmbus/Makefile                       |    1 +
 drivers/hwmon/pmbus/mpq8646.c                      | 1253 ++++++++++++++++++++
 drivers/hwmon/pmbus/pmbus.h                        |    1 +
 drivers/hwmon/pmbus/pmbus_core.c                   |    8 +
 9 files changed, 1646 insertions(+)
---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260723-mpq8646_v0-3383cb574d7a

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

