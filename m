From: Manuel Levi <mlevif@gmail.com>
Date: Thu, 12 Nov 2026 15:39:29 +0000
Subject: [PATCH] media: atomisp: csi2-bridge: Only change the PMC clock
 rate when needed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-atomisp-pmc-clk-rate-v1-1-d6b3ef392ccf@gmail.com>
X-B4-Tracking: v=1; b=H4sIALDd9WoC/x3MwQrCMAyA4VcZORtYiozhq4iHtGZb0HUlKTIYe
 3erx+/w/we4mIrDrTvA5KOuW26gSwdp4TwL6rMZQh8GIgrIdVvVC5Y1YXq/0LgKTv3IMVxpiML
 Q0mIy6f7f3h/NkV0wGue0/GZZ9grn+QWM7hVBfQAAAA==
X-Change-ID: 20261112-atomisp-pmc-clk-rate-f08ab2416bea
To: Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-staging@lists.linux.dev, Manuel Levi <mlevif@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794497984; l=3543;
 i=mlevif@gmail.com; s=miix320; h=from:subject:message-id;
 bh=bZ4amSOmRbtAS3Gr8P2aAqXS4SXIOeSbgHibbWxJNVQ=;
 b=XHQlZE7IQvJaBMbwVCXE+DVjs4tIS+XLX3oenO4E1v9bdHGrf86jTe1w360DmpP+FkmUb0Ejv
 lZfJur3dG0vBDwHRNkXKxeLu2gAv1Q5hh7f1fzevRbNzFczXQo3ez7G
X-Developer-Key: i=mlevif@gmail.com; a=ed25519;
 pk=Ich6VcjyjXrqkJedoL17cXSlYNA9kK/oKhBxDM9IYyA=
X-Endpoint-Received: by B4 Relay for mlevif@gmail.com/miix320 with auth_id=1501
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

atomisp_csi2_set_pmc_clk_freq() enables and then disables the sensor's
PMC platform clock before setting its rate to 19.2 MHz, which leaves the
clock forced off in hardware.

The sensor's clock is also controlled by ACPI: the CLKn power resource
in the sensor's _PR0 writes the same PMC clock control field that
clk-pmc-atom writes (1 = force on, 2 = force off), and the two do not
coordinate. If the sensor is in D0 while the bridge runs, the clock is
switched off under it and the sensor stops responding on I2C.

This happens when the sensor driver probes at the same time as the
bridge: the i2c core powers the sensor to D0 for every probe attempt,
including those that end in -EPROBE_DEFER while waiting for the bridge's
fwnode graph. On a Lenovo Miix 320-10ICR (Cherry Trail) the ov2680 probe
then fails to read the chip ID in about 1 out of 10 boots:

  ov2680 i2c-OVTI2680:00: Error reading reg 0x300a: -121
  ov2680 i2c-OVTI2680:00: failed to read chip id

The sensor never binds, so atomisp registers no camera at all.

This can be reproduced on demand: with the ov2680 runtime-resumed
(CLK2 on, chip ID reads fine), running the same clk_prepare_enable(),
clk_disable_unprepare(), clk_set_rate() sequence on pmc_plt_clk_2 from
a test module makes the sensor NAK (-EREMOTEIO) until its power
resources are cycled.

The enable/disable sequence is only needed to change the rate, which can
default to 25 MHz on Bay Trail. On Cherry Trail the clocks already run at
19.2 MHz. Skip the sequence when the clock already has the right rate,
so that the bridge leaves the clock state to ACPI.

Tested on a Lenovo Miix 320-10ICR with the atomisp driver from Debian's
6.12.116 kernel (this function is unchanged in mainline): with this
patch pmc_plt_clk_2 and pmc_plt_clk_4 are no longer switched off during
bridge init (checked with clk trace events), and both sensors were
registered on all 10 test boots.

Fixes: 0af9078315c1 ("media: atomisp: csi2-bridge: Set PMC clk-rate for sensors to 19.2 MHz")
Signed-off-by: Manuel Levi <mlevif@gmail.com>
---
I can test further changes on the Lenovo Miix 320 if useful.
---
 drivers/staging/media/atomisp/pci/atomisp_csi2_bridge.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/staging/media/atomisp/pci/atomisp_csi2_bridge.c b/drivers/staging/media/atomisp/pci/atomisp_csi2_bridge.c
index cca91c6d71a596594425a6401292a82bb4f8db12..06340533ee87b972c2ca577f73960d00a15ac135 100644
--- a/drivers/staging/media/atomisp/pci/atomisp_csi2_bridge.c
+++ b/drivers/staging/media/atomisp/pci/atomisp_csi2_bridge.c
@@ -257,6 +257,19 @@ static int atomisp_csi2_set_pmc_clk_freq(struct acpi_device *adev, int clock_num
 		return ret;
 	}
 
+	/*
+	 * Only touch the clock when its rate needs changing (on BYT it may
+	 * default to 25 MHz). The enable + disable below leaves the clock
+	 * forced off, while ACPI controls the same clock through the CLKn
+	 * power resource in the sensor's _PR0. If the sensor is powered up at
+	 * this point, e.g. by a concurrent probe of its driver, it would lose
+	 * its clock and stop responding.
+	 */
+	if (clk_get_rate(clk) == PMC_CLK_RATE_19_2MHZ) {
+		clk_put(clk);
+		return 0;
+	}
+
 	/*
 	 * The firmware might enable the clock at boot, to change
 	 * the rate we must ensure the clock is disabled.

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-atomisp-pmc-clk-rate-f08ab2416bea

Best regards,
-- 
Manuel Levi <mlevif@gmail.com>

