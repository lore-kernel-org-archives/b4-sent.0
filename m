From: Babis Danias <b.danias@tutamail.com>
Date: Wed, 04 Nov 2026 11:42:49 +0200
Subject: [PATCH 3/3] media: i2c: ov8856: Power off the sensor during system
 suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ov8856-pm-fixes-v1-3-1958b730ce66@tutamail.com>
References: <20261104-ov8856-pm-fixes-v1-0-1958b730ce66@tutamail.com>
In-Reply-To: <20261104-ov8856-pm-fixes-v1-0-1958b730ce66@tutamail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Serin Yeh <serin.yeh@intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Robert Foss <rfoss@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Babis Danias <b.danias@tutamail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793785376; l=2806;
 i=b.danias@tutamail.com; s=20261103; h=from:subject:message-id;
 bh=D6TzCaSHwO5sxfGpSVeAfyeQYpOZbznZnsTWQvfOylA=;
 b=RaX+DSEFW0zQSOLC+4Irzx1Rw9oIY89rIlVs810BM1jeOii2AqSXcbpcaJcKLy6AviB3b1Sd5
 ItiBQ2Jm82EA5myR/D/Lq7D0r/+A5uGsqms2TaXMz1eXkbmzvbn04JC
X-Developer-Key: i=b.danias@tutamail.com; a=ed25519;
 pk=6DWeigdk0D3JwBjwvmxo9RW8cG8S1Eku42cb9PP+ghk=
X-Endpoint-Received: by B4 Relay for b.danias@tutamail.com/20261103 with auth_id=1406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a Dell Latitude 7320 Detachable, the rear OV8856 stays powered for
the whole of s2idle once the dw9714 VCM driver is bound, even with the
camera idle. Tracing a 20 second suspend shows the sensor's clock and
regulators enabled about 0.5 s after "PM: suspend entry", and disabled
only just before "PM: suspend exit". Without the VCM driver bound, they
stay off.

ipu-bridge links the VCM to the sensor with a runtime PM device link,
which makes the sensor a supplier of the VCM. The dw9714 driver has
system sleep callbacks, so the VCM can't use direct-complete, and
dpm_clear_superiors_direct_complete() then clears direct_complete for
the sensor as well. The sensor goes through the full system suspend
path, where acpi_subsys_suspend() runtime-resumes it before calling the
driver's suspend callback. But ov8856 has had no system sleep callbacks
since commit 19ae6ba57f88 ("media: i2c: ov8856: Drop system suspend and
resume handlers"), so nothing powers the sensor off again.

This matters since commit 609a71568664 ("media: i2c: ov8856 : remove
ACPI node bypass mechanism") made the runtime PM callbacks control the
sensor's power on ACPI systems.

Use DEFINE_RUNTIME_DEV_PM_OPS(), so that pm_runtime_force_suspend()
powers the sensor off during system suspend, and
pm_runtime_force_resume() powers it on again only if it was in use. With
this, the sensor is off for the whole suspend. It is still powered up
for a few milliseconds at suspend entry, by acpi_subsys_suspend().

The problem was found, and this patch written, with the help of an AI
coding assistant (Claude Opus 5.5). See the cover letter for details.

Fixes: 609a71568664 ("media: i2c: ov8856 : remove ACPI node bypass mechanism")
Cc: stable@vger.kernel.org
Signed-off-by: Babis Danias <b.danias@tutamail.com>
---
 drivers/media/i2c/ov8856.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/media/i2c/ov8856.c b/drivers/media/i2c/ov8856.c
index f9bcdd412..848e981ff 100644
--- a/drivers/media/i2c/ov8856.c
+++ b/drivers/media/i2c/ov8856.c
@@ -2462,9 +2462,8 @@ static int ov8856_probe(struct i2c_client *client)
 	return ret;
 }
 
-static const struct dev_pm_ops ov8856_pm_ops = {
-	SET_RUNTIME_PM_OPS(ov8856_power_off, ov8856_power_on, NULL)
-};
+static DEFINE_RUNTIME_DEV_PM_OPS(ov8856_pm_ops, ov8856_power_off,
+				 ov8856_power_on, NULL);
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id ov8856_acpi_ids[] = {
@@ -2484,7 +2483,7 @@ MODULE_DEVICE_TABLE(of, ov8856_of_match);
 static struct i2c_driver ov8856_i2c_driver = {
 	.driver = {
 		.name = "ov8856",
-		.pm = &ov8856_pm_ops,
+		.pm = pm_ptr(&ov8856_pm_ops),
 		.acpi_match_table = ACPI_PTR(ov8856_acpi_ids),
 		.of_match_table = ov8856_of_match,
 	},

-- 
2.56.0

