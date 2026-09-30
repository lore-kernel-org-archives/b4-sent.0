From: Igor Velkov <iav@iav.lv>
Date: Wed, 30 Sep 2026 18:33:24 +0000
Subject: [PATCH] spi: Probe a device tree device at the requested speed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-spi-probe-speed-v1-1-ff9aebfebdf9@iav.lv>
X-B4-Tracking: v=1; b=H4sIAPRVvWoC/x2MQQqAIBQFryJ/naAmYl0lWpS+6m9SFCKI7p60m
 1nMPFRRGJVG8VDBxZXT2UR3gsKxnDskx+ZklHFq6JWsmWUuaUUjIErtjA/OWzhjqVW5YOP7P07
 z+37j3n31YQAAAA==
To: Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, Marek Vasut <marek.vasut@mailbox.org>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3232; i=iav@iav.lv;
 h=from:subject:message-id; bh=ucldvmMd2tUcQ8A+jI6CtdvI+UNcNOU6CDWXM4CU9To=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl7Q78EbO5Zt+TArxuF9praThEH2D/6KliciGiu2mNfd
 3P3zQVPO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE3NQZGd4GKv173mN1QJrz
 1Js7TG6KW1mb2I1Wbrhv7HN5cUTq/zCGP7yffO5P/a7a35fL2+VlGdN93D7ZLDOwsPjGZ+MEZbN
 TbAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`sf probe <bus>:<cs> <speed>` ignores the speed for a flash that has a
device tree node. _spi_get_bus_and_cs() probes the device, and with it
the flash reads its JEDEC ID, at spi-max-frequency from the device tree.
The requested speed is set only after the probe, and the slave keeps
max_hz from the device tree, so the next claim of the bus goes back to
that frequency.

A device bound without a device tree node already gets the requested
speed and mode before the probe. Do the same for a device from the
device tree, for the duration of the probe.

On ROCK Pi 4A the device tree sets spi-max-frequency = <108000000> and
the flash does not answer at the resulting clock, at any requested
speed:

  => sf probe 1:0 1000000
  jedec_spi_nor flash@0: unrecognized JEDEC id bytes: ff, ff, ff

With this change:

  => sf probe 1:0 1000000
  SF: Detected xt25f32 with page size 256 Bytes, erase size 4 KiB, total 4 MiB

Add a sandbox test for it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested in sandbox (the new test fails without the change) and on
ROCK Pi 4A with U-Boot proper chainloaded from the running one.
---
 drivers/spi/spi-uclass.c |  9 +++++++++
 test/dm/spi.c            | 20 ++++++++++++++++++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/spi/spi-uclass.c b/drivers/spi/spi-uclass.c
index 120565df149..097c1ae665e 100644
--- a/drivers/spi/spi-uclass.c
+++ b/drivers/spi/spi-uclass.c
@@ -517,8 +517,17 @@ int _spi_get_bus_and_cs(int busnum, int cs, int speed, int mode,
 
 	if (!device_active(dev)) {
 		struct spi_slave *slave;
+		uint dt_max_hz = plat->max_hz;
+		uint dt_mode = plat->mode;
 
+		/* Probe at the caller's speed and mode: a flash reads its ID here */
+		if (speed && !created) {
+			plat->max_hz = speed;
+			plat->mode = mode;
+		}
 		ret = device_probe(dev);
+		plat->max_hz = dt_max_hz;
+		plat->mode = dt_mode;
 		if (ret)
 			goto err;
 		slave = dev_get_parent_priv(dev);
diff --git a/test/dm/spi.c b/test/dm/spi.c
index a89ba06274f..4ea4bcd1196 100644
--- a/test/dm/spi.c
+++ b/test/dm/spi.c
@@ -91,6 +91,26 @@ static int dm_test_spi_find(struct unit_test_state *uts)
 }
 DM_TEST(dm_test_spi_find, UTF_SCAN_PDATA | UTF_SCAN_FDT);
 
+/* Test that the first probe of a device from the DT uses the caller's speed */
+static int dm_test_spi_probe_speed(struct unit_test_state *uts)
+{
+	const int busnum = 0, cs = 0, mode = 0, speed = 1000000;
+	struct spi_slave *slave;
+	struct udevice *bus;
+
+	/* spi.bin@0 has spi-max-frequency = <40000000> */
+	ut_assertok(_spi_get_bus_and_cs(busnum, cs, speed, mode, NULL, NULL,
+					&bus, &slave));
+	ut_asserteq(speed, slave->max_hz);
+
+	ut_assertok(spi_claim_bus(slave));
+	ut_asserteq(speed, sandbox_spi_get_speed(bus));
+	spi_release_bus(slave);
+
+	return 0;
+}
+DM_TEST(dm_test_spi_probe_speed, UTF_SCAN_PDATA | UTF_SCAN_FDT);
+
 /* dm_test_spi_switch_slaves - Helper function to check whether spi_claim_bus
  *                             operates correctly with two spi slaves.
  *

---
base-commit: f8eb3469e1a17c79b047b3fd38ae820e8816a115
change-id: 20260930-spi-probe-speed-1628c684e624

Best regards,
-- 
Igor Velkov <iav@iav.lv>

