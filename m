From: Igor Velkov <iav@iav.lv>
Date: Tue, 27 Oct 2026 17:57:37 +0000
Subject: [PATCH v3] spi: sf: Probe a flash at the requested speed and mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-spi-probe-speed-v3-1-33e056720925@iav.lv>
X-B4-Tracking: v=1; b=H4sIABDm4GoC/3WNQQqDMBBFryKzbkoykahd9R6li8RM6kBRSUpoE
 e/e6MJN6W7eh/dmgUSRKcGlWiBS5sTTWECfKugHOz5IsC8MKNHITkuRZhZznByVi8gLZbDtTVu
 TwRqKNUcK/N6Lt3vhgdNrip/9QVbb+r+VlVAihM6SC+R86K5s8/mZYQtlPGQlsfmVscgYsPHeG
 Su1O+R1Xb+BoFOf6AAAAA==
To: Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, Marek Vasut <marek.vasut@mailbox.org>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=13174; i=iav@iav.lv;
 h=from:subject:message-id; bh=X3x8oOVTPgY1MYNTLnaUm3JJ+kOwGo1CYOle8Sz+VLg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkPngm1eujwc6VfWd93VGvHybnT5CxlUuN//VhYlNY5L
 2HG6emGHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiGf6MDC/2t/vIX//39bXj
 OfYd0+Sfzz1bwn6z+sGcpZuqJokEJogyMjyZkHjg3J+XJ4MWizI684lvkFjL97It99/1IAbJR+d
 U17ACAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'sf probe <bus>:<cs> <speed> [<mode>]' ignores the speed and the mode
for a flash that has a device tree node: the probe, and with it the
JEDEC ID read, runs at spi-max-frequency and in the device tree mode.
The requested values reach the controller only after the probe, through
spi_set_speed_mode(), while slave->max_hz and slave->mode keep the
device tree values. Without a mode, sf probe passes
CONFIG_SF_DEFAULT_MODE, so after the probe the controller runs in that
mode rather than in the device tree one. A mode given once also stays
in the controller for later probes without one, since the bus still
caches the device tree mode and the bus claim does not reprogram it.

On ROCK Pi 4A the device tree sets spi-max-frequency = <108000000> and
the flash does not answer at the resulting clock, at any requested
speed:

  => sf probe 1:0 1000000
  jedec_spi_nor flash@0: unrecognized JEDEC id bytes: ff, ff, ff

Add _spi_get_bus_and_cs_at() to the SPI uclass. It probes a slave that
has platform data with the requested speed and mode and restores the
platform data right after the probe, so the slave keeps the requested
values and the platform data stays as the device tree set it. With
dt_mode it keeps the device tree mode. Add spi_flash_probe_at() on top
of it and use it in sf probe with an explicit speed; without a mode
argument the device tree mode stays. A speed above spi-max-frequency is
honoured, as it already is after the probe. The other callers of
spi_flash_probe() and _spi_get_bus_and_cs() do not change.

With this change:

  => sf probe 1:0 1000000
  SF: Detected xt25f32 with page size 256 Bytes, erase size 4 KiB, total 4 MiB

Add a sandbox test for it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested in sandbox (the new test fails at slave->max_hz without the
change, and at the controller mode with v2) and on ROCK Pi 4A with
U-Boot proper chainloaded: sf probe 1:0 at 1 and 10 MHz detects the
flash, without a speed it reads ff ff ff at the DT 108 MHz, modes 0
and 3 detect it, modes 1 and 2 read ff ff ff. With v2, modes 1 and 2
detect it, and the next 'sf probe 1:0 1000000' reads ff ff ff.
---
Changes in v3:
- Move the override into _spi_get_bus_and_cs_at() in the SPI uclass,
  with spi_flash_probe_at() for sf probe, so the command does not touch
  the platform data (Simon)
- Probe in the requested mode too: in v2 it reached the controller only
  after the probe, and slave->mode kept the DT mode (Simon)
- Without a mode, keep the DT mode after the probe as well, instead of
  switching to SF_DEFAULT_MODE
- Test the controller mode and plat->mode as well
- Link to v2: https://lore.kernel.org/r/20261027-spi-probe-speed-v2-1-2f27ddb6a03b@iav.lv

Changes in v2:
- Move the override from _spi_get_bus_and_cs() to sf probe, so only an
  explicit speed from the shell changes; other callers keep probing at
  the DT speed (Simon)
- Override only max_hz and keep the DT mode (Simon)
- Test through sf probe on spi.bin@1 (spi-cpol, spi-cpha) that
  plat->max_hz and the DT mode bits survive (Simon)
- Drop the wrong v1 claim that the next bus claim returns to the DT speed
- Leave the post-probe spi_set_speed_mode() from e2e95e5e2542 as is:
  SF_DEFAULT_SPEED takes effect there, and 117 of 153 SPL_SPI_LOAD
  defconfigs set it
- Link to v1: https://lore.kernel.org/r/20260930-spi-probe-speed-v1-1-ff9aebfebdf9@iav.lv
---
 cmd/sf.c                    |  2 +-
 drivers/mtd/spi/sf-uclass.c | 33 +++++++++++++++++++++++++++++----
 drivers/spi/spi-uclass.c    | 41 ++++++++++++++++++++++++++++++++++++++---
 include/spi.h               | 23 +++++++++++++++++++++++
 include/spi_flash.h         | 18 ++++++++++++++++++
 test/dm/sf.c                | 42 ++++++++++++++++++++++++++++++++++++++++++
 6 files changed, 151 insertions(+), 8 deletions(-)

diff --git a/cmd/sf.c b/cmd/sf.c
index ec9ebde2aaf..fb5b9627444 100644
--- a/cmd/sf.c
+++ b/cmd/sf.c
@@ -146,7 +146,7 @@ static int do_spi_flash_probe(int argc, char *const argv[])
 			}
 		}
 	} else {
-		flash = spi_flash_probe(bus, cs, speed, mode);
+		flash = spi_flash_probe_at(bus, cs, speed, mode, argc < 4);
 	}
 
 	if (!flash) {
diff --git a/drivers/mtd/spi/sf-uclass.c b/drivers/mtd/spi/sf-uclass.c
index a9db5296b2d..7b487b8aff8 100644
--- a/drivers/mtd/spi/sf-uclass.c
+++ b/drivers/mtd/spi/sf-uclass.c
@@ -44,12 +44,16 @@ int spl_flash_get_sw_write_prot(struct udevice *dev)
  * TODO(sjg@chromium.org): This is an old-style function. We should remove
  * it when all SPI flash drivers use dm
  */
-struct spi_flash *spi_flash_probe(unsigned int busnum, unsigned int cs,
-				  unsigned int max_hz, unsigned int spi_mode)
+static struct spi_flash *spi_flash_probe_common(unsigned int busnum,
+						unsigned int cs,
+						unsigned int max_hz,
+						unsigned int spi_mode, bool at,
+						bool dt_mode)
 {
 	struct spi_slave *slave;
 	struct udevice *bus;
 	char *str;
+	int ret;
 
 #if defined(CONFIG_XPL_BUILD) && CONFIG_IS_ENABLED(USE_TINY_PRINTF)
 	str = "spi_flash";
@@ -60,13 +64,34 @@ struct spi_flash *spi_flash_probe(unsigned int busnum, unsigned int cs,
 	str = strdup(name);
 #endif
 
-	if (_spi_get_bus_and_cs(busnum, cs, max_hz, spi_mode,
-				"jedec_spi_nor", str, &bus, &slave))
+	if (at)
+		ret = _spi_get_bus_and_cs_at(busnum, cs, max_hz, spi_mode,
+					     dt_mode, "jedec_spi_nor", str,
+					     &bus, &slave);
+	else
+		ret = _spi_get_bus_and_cs(busnum, cs, max_hz, spi_mode,
+					  "jedec_spi_nor", str, &bus, &slave);
+	if (ret)
 		return NULL;
 
 	return dev_get_uclass_priv(slave->dev);
 }
 
+struct spi_flash *spi_flash_probe(unsigned int busnum, unsigned int cs,
+				  unsigned int max_hz, unsigned int spi_mode)
+{
+	return spi_flash_probe_common(busnum, cs, max_hz, spi_mode, false,
+				      false);
+}
+
+struct spi_flash *spi_flash_probe_at(unsigned int busnum, unsigned int cs,
+				     unsigned int max_hz,
+				     unsigned int spi_mode, bool dt_mode)
+{
+	return spi_flash_probe_common(busnum, cs, max_hz, spi_mode, true,
+				      dt_mode);
+}
+
 int spi_flash_probe_bus_cs(unsigned int busnum, unsigned int cs,
 			   struct udevice **devp)
 {
diff --git a/drivers/spi/spi-uclass.c b/drivers/spi/spi-uclass.c
index dd1843ffac1..b8f8e021019 100644
--- a/drivers/spi/spi-uclass.c
+++ b/drivers/spi/spi-uclass.c
@@ -476,9 +476,11 @@ err:
 	return ret;
 }
 
-int _spi_get_bus_and_cs(int busnum, int cs, int speed, int mode,
-			const char *drv_name, const char *dev_name,
-			struct udevice **busp, struct spi_slave **devp)
+static int spi_get_bus_and_cs_common(int busnum, int cs, int speed, int mode,
+				     bool at, bool dt_mode,
+				     const char *drv_name, const char *dev_name,
+				     struct udevice **busp,
+				     struct spi_slave **devp)
 {
 	struct udevice *bus, *dev;
 	struct dm_spi_slave_plat *plat;
@@ -529,12 +531,28 @@ int _spi_get_bus_and_cs(int busnum, int cs, int speed, int mode,
 		return ret;
 	} else if (dev) {
 		plat = dev_get_parent_plat(dev);
+		if (at && dt_mode)
+			mode = plat->mode;
 	}
 
 	if (!device_active(dev)) {
+		bool override = at && !created;
+		uint saved_max_hz = 0, saved_mode = 0;
 		struct spi_slave *slave;
 
+		/* A flash reads its ID in the probe: probe at the requested values */
+		if (override) {
+			saved_max_hz = plat->max_hz;
+			saved_mode = plat->mode;
+			if (speed)
+				plat->max_hz = speed;
+			plat->mode = mode;
+		}
 		ret = device_probe(dev);
+		if (override) {
+			plat->max_hz = saved_max_hz;
+			plat->mode = saved_mode;
+		}
 		if (ret)
 			goto err;
 		slave = dev_get_parent_priv(dev);
@@ -588,6 +606,23 @@ err:
 	return ret;
 }
 
+int _spi_get_bus_and_cs(int busnum, int cs, int speed, int mode,
+			const char *drv_name, const char *dev_name,
+			struct udevice **busp, struct spi_slave **devp)
+{
+	return spi_get_bus_and_cs_common(busnum, cs, speed, mode, false, false,
+					 drv_name, dev_name, busp, devp);
+}
+
+int _spi_get_bus_and_cs_at(int busnum, int cs, int speed, int mode,
+			   bool dt_mode, const char *drv_name,
+			   const char *dev_name, struct udevice **busp,
+			   struct spi_slave **devp)
+{
+	return spi_get_bus_and_cs_common(busnum, cs, speed, mode, true, dt_mode,
+					 drv_name, dev_name, busp, devp);
+}
+
 /* Compatibility function - to be removed */
 struct spi_slave *spi_setup_slave(unsigned int busnum, unsigned int cs,
 				  unsigned int speed, unsigned int mode)
diff --git a/include/spi.h b/include/spi.h
index f477763bdc6..698ca8c8358 100644
--- a/include/spi.h
+++ b/include/spi.h
@@ -644,6 +644,29 @@ int _spi_get_bus_and_cs(int busnum, int cs, int speed, int mode,
 			const char *drv_name, const char *dev_name,
 			struct udevice **busp, struct spi_slave **devp);
 
+/**
+ * _spi_get_bus_and_cs_at() - Find and activate a slave at the requested speed
+ *
+ * As _spi_get_bus_and_cs(), but a slave that is not active and has plat
+ * (from the device tree) is probed with the requested speed and mode instead,
+ * and keeps them after the probe. Its plat is left unchanged.
+ *
+ * @busnum:	SPI bus number
+ * @cs:		Chip select to look for
+ * @speed:	SPI speed to use for this slave, or 0 for the plat value
+ * @mode:	SPI mode to use for this slave
+ * @dt_mode:	Use the plat mode of a slave that has plat, rather than @mode
+ * @drv_name:	Name of driver to attach to this chip select
+ * @dev_name:	Name of the new device thus created
+ * @busp:	Returns bus device
+ * @devp:	Return slave device
+ * Return: 0 if found, -ve on error
+ */
+int _spi_get_bus_and_cs_at(int busnum, int cs, int speed, int mode,
+			   bool dt_mode, const char *drv_name,
+			   const char *dev_name, struct udevice **busp,
+			   struct spi_slave **devp);
+
 /**
  * spi_chip_select() - Get the chip select for a slave
  *
diff --git a/include/spi_flash.h b/include/spi_flash.h
index 2e703e85250..1109df01700 100644
--- a/include/spi_flash.h
+++ b/include/spi_flash.h
@@ -108,6 +108,24 @@ int spi_flash_probe_bus_cs(unsigned int busnum, unsigned int cs,
 struct spi_flash *spi_flash_probe(unsigned int bus, unsigned int cs,
 				  unsigned int max_hz, unsigned int spi_mode);
 
+/**
+ * spi_flash_probe_at() - Probe a flash at the requested speed and mode
+ *
+ * As spi_flash_probe(), but a flash with a device tree node reads its ID
+ * and runs at @max_hz and @spi_mode instead of the device tree values.
+ *
+ * @bus:	SPI bus number
+ * @cs:		Chip select
+ * @max_hz:	SPI speed, or 0 for the device tree value
+ * @spi_mode:	SPI mode
+ * @dt_mode:	Use the device tree mode of a flash that has a node, rather
+ *		than @spi_mode
+ * Return: the flash, or NULL on error
+ */
+struct spi_flash *spi_flash_probe_at(unsigned int bus, unsigned int cs,
+				     unsigned int max_hz,
+				     unsigned int spi_mode, bool dt_mode);
+
 /* Compatibility function - this is the old U-Boot API */
 static inline void spi_flash_free(struct spi_flash *flash)
 {
diff --git a/test/dm/sf.c b/test/dm/sf.c
index 0ec02ac694b..f24457ecf33 100644
--- a/test/dm/sf.c
+++ b/test/dm/sf.c
@@ -106,3 +106,45 @@ static int dm_test_spi_flash_func(struct unit_test_state *uts)
 	return 0;
 }
 DM_TEST(dm_test_spi_flash_func, UTF_SCAN_PDATA | UTF_SCAN_FDT);
+
+/* Test that 'sf probe' with a speed and mode probes a DT flash with them */
+static int dm_test_spi_flash_probe_speed(struct unit_test_state *uts)
+{
+	struct dm_spi_slave_plat *plat;
+	struct spi_slave *slave;
+	struct udevice *bus, *dev;
+
+	/* spi.bin@1 has spi-max-frequency = <50000000>, spi-cpol and spi-cpha */
+	ut_assertok(run_command("host save hostfs - 0 spi.bin 200000", 0));
+
+	/* Without a mode, the DT mode stays */
+	ut_assertok(run_command("sf probe 0:1 1000000", 0));
+	ut_assertok(spi_find_bus_and_cs(0, 1, &bus, &dev));
+	slave = dev_get_parent_priv(dev);
+	ut_asserteq(1000000, slave->max_hz);
+	ut_asserteq(SPI_CPOL | SPI_CPHA, slave->mode);
+	ut_asserteq(1000000, sandbox_spi_get_speed(bus));
+	ut_asserteq(SPI_CPOL | SPI_CPHA, sandbox_spi_get_mode(bus));
+
+	ut_assertok(run_command("sf probe 0:1 1000000 0", 0));
+	ut_assertok(spi_find_bus_and_cs(0, 1, &bus, &dev));
+	slave = dev_get_parent_priv(dev);
+	plat = dev_get_parent_plat(dev);
+	ut_asserteq(1000000, slave->max_hz);
+	ut_asserteq(0, slave->mode);
+	ut_asserteq(0, sandbox_spi_get_mode(bus));
+	ut_asserteq(50000000, plat->max_hz);
+	ut_asserteq(SPI_CPOL | SPI_CPHA, plat->mode);
+
+	/* Without a speed, the DT values apply again */
+	ut_assertok(run_command("sf probe 0:1", 0));
+	ut_assertok(spi_find_bus_and_cs(0, 1, &bus, &dev));
+	slave = dev_get_parent_priv(dev);
+	ut_asserteq(50000000, slave->max_hz);
+	ut_asserteq(SPI_CPOL | SPI_CPHA, slave->mode);
+
+	sandbox_sf_unbind_emul(state_get_current(), 0, 1);
+
+	return 0;
+}
+DM_TEST(dm_test_spi_flash_probe_speed, UTF_SCAN_PDATA | UTF_SCAN_FDT);

---
base-commit: dfcfc4c9f78d1743f490a497082a4ec8e058aae8
change-id: 20260930-spi-probe-speed-1628c684e624

Best regards,
-- 
Igor Velkov <iav@iav.lv>

