From: Igor Velkov <iav@iav.lv>
Date: Tue, 27 Oct 2026 05:57:26 +0000
Subject: [PATCH v2] cmd: sf: Probe a flash at the requested speed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-spi-probe-speed-v2-1-2f27ddb6a03b@iav.lv>
X-B4-Tracking: v=1; b=H4sIAEU94GoC/3WNwQrDIBBEfyXsuVvUBok99T9KDhrXZqFE0SItw
 X+vzb23eQPzZodCmanAddghU+XCceugTgMsq90ehOw7gxJKC3MRWBJjytFRT0QepVbToqeRtBq
 hr1KmwO/DeJ87r1xeMX+Ogyp/7X9XlSgxBGPJBXI+mBvben5WmFtrX6aglCqrAAAA
To: Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, Marek Vasut <marek.vasut@mailbox.org>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4412; i=iav@iav.lv;
 h=from:subject:message-id; bh=0HDgpoWNl/+3OQN05UdUj934gpGhIHKqqblVEey/MMY=;
 b=kA0DAAoWMpeVi+pfeQMByyZiAGrgPUejvnbwwEYuhzU1cPbtbuBpuZaiVTTrQkloeQgblezKo
 Ih1BAAWCgAdFiEEkMIo2mik1f1PSDfgMpeVi+pfeQMFAmrgPUcACgkQMpeVi+pfeQOrNAD+MG71
 2xIa8Q1/eSJu1BF9v7QRUnC9wI2BMQRJKb/WqnkA/2RJqErJ5pmc1UpdU5AvC8i8b3ZWbkEh2Zi
 WAqpFvvID
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'sf probe <bus>:<cs> <speed>' ignores the speed for a flash that has a
device tree node: the probe, and with it the JEDEC ID read, runs at
spi-max-frequency, and the requested speed reaches the controller only
after it.

On ROCK Pi 4A the device tree sets spi-max-frequency = <108000000> and
the flash does not answer at the resulting clock, at any requested
speed:

  => sf probe 1:0 1000000
  jedec_spi_nor flash@0: unrecognized JEDEC id bytes: ff, ff, ff

Before the probe, set the requested speed in the platform data of the
device, as _spi_get_bus_and_cs() already does for a device it binds
without a device tree node, and restore the saved value right after it,
so the platform data ends up unchanged. slave->mode keeps the device
tree value. A speed above spi-max-frequency is honoured, as it already
is after the probe. Only sf probe with an explicit speed changes: sf
probe without one and the other spi_flash_probe() callers still probe a
device tree flash at spi-max-frequency.

With this change:

  => sf probe 1:0 1000000
  SF: Detected xt25f32 with page size 256 Bytes, erase size 4 KiB, total 4 MiB

Add a sandbox test for it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested in sandbox (the new test fails without the change) and on ROCK
Pi 4A with U-Boot proper chainloaded: without the change sf probe 1:0
at 1 and 10 MHz reads ff ff ff, with it the flash is detected.
---
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
 cmd/sf.c     | 11 +++++++++++
 test/dm/sf.c | 29 +++++++++++++++++++++++++++++
 2 files changed, 40 insertions(+)

diff --git a/cmd/sf.c b/cmd/sf.c
index ec9ebde2aaf..7dabb4d1684 100644
--- a/cmd/sf.c
+++ b/cmd/sf.c
@@ -146,7 +146,18 @@ static int do_spi_flash_probe(int argc, char *const argv[])
 			}
 		}
 	} else {
+		struct dm_spi_slave_plat *plat = NULL;
+		uint saved_max_hz = 0;
+
+		/* Probe at the requested speed: the flash reads its ID there */
+		if (!ret && speed) {
+			plat = dev_get_parent_plat(new);
+			saved_max_hz = plat->max_hz;
+			plat->max_hz = speed;
+		}
 		flash = spi_flash_probe(bus, cs, speed, mode);
+		if (plat)
+			plat->max_hz = saved_max_hz;
 	}
 
 	if (!flash) {
diff --git a/test/dm/sf.c b/test/dm/sf.c
index 0ec02ac694b..ea93f0b65b0 100644
--- a/test/dm/sf.c
+++ b/test/dm/sf.c
@@ -106,3 +106,32 @@ static int dm_test_spi_flash_func(struct unit_test_state *uts)
 	return 0;
 }
 DM_TEST(dm_test_spi_flash_func, UTF_SCAN_PDATA | UTF_SCAN_FDT);
+
+/* Test that 'sf probe' with a speed probes a DT flash at that speed */
+static int dm_test_spi_flash_probe_speed(struct unit_test_state *uts)
+{
+	struct dm_spi_slave_plat *plat;
+	struct spi_slave *slave;
+	struct udevice *bus, *dev;
+
+	/* spi.bin@1 has spi-max-frequency = <50000000>, spi-cpol and spi-cpha */
+	ut_assertok(run_command("host save hostfs - 0 spi.bin 200000", 0));
+	ut_assertok(run_command("sf probe 0:1 1000000", 0));
+	ut_assertok(spi_find_bus_and_cs(0, 1, &bus, &dev));
+	slave = dev_get_parent_priv(dev);
+	plat = dev_get_parent_plat(dev);
+	ut_asserteq(1000000, slave->max_hz);
+	ut_asserteq(50000000, plat->max_hz);
+	ut_asserteq(SPI_CPOL | SPI_CPHA, slave->mode & (SPI_CPOL | SPI_CPHA));
+
+	/* Without a speed, the DT value applies again */
+	ut_assertok(run_command("sf probe 0:1", 0));
+	ut_assertok(spi_find_bus_and_cs(0, 1, &bus, &dev));
+	slave = dev_get_parent_priv(dev);
+	ut_asserteq(50000000, slave->max_hz);
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

