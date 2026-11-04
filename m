From: Babis Danias <b.danias@tutamail.com>
Date: Wed, 04 Nov 2026 11:42:47 +0200
Subject: [PATCH 1/3] media: i2c: ov8856: Don't power off a suspended sensor
 in remove()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ov8856-pm-fixes-v1-1-1958b730ce66@tutamail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793785376; l=2491;
 i=b.danias@tutamail.com; s=20261103; h=from:subject:message-id;
 bh=L0hpfrqG49Zm1CXdfuZ2hjqTYWvnPHNuq5J1KgmEnBA=;
 b=whLpfC3mk7QF56y/tO7n53TWmypmoddnNr//nUy7Vk5xStgGCQKpq2iywsz20FCe+5nGDbu6b
 77a8xYa2RBnCJPK36i9i8SWexnpI6fc40W+Q8obPu8DlrBA0b10/cp7
X-Developer-Key: i=b.danias@tutamail.com; a=ed25519;
 pk=6DWeigdk0D3JwBjwvmxo9RW8cG8S1Eku42cb9PP+ghk=
X-Endpoint-Received: by B4 Relay for b.danias@tutamail.com/20261103 with auth_id=1406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov8856_remove() calls ov8856_power_off() unconditionally. The sensor is
normally runtime-suspended by then, so its regulators and clock get
disabled a second time. On every unbind, the regulator core refuses the
extra disable with an "unbalanced disables" warning, and the clock
framework warns that the clock is already disabled and unprepared.

For the clock this is more than a warning: the clock framework keeps
one enable count per clock, shared by all its consumers. Where sensors
share a clock, such as the TPS68470 clock that int3472 hands to every
sensor behind it, the extra disable can stop the clock under another
sensor that is streaming.

This has been the case on devicetree systems since the power handling
was added. Since commit 609a71568664 ("media: i2c: ov8856 : remove ACPI
node bypass mechanism"), it happens on ACPI systems too. Seen on a Dell
Latitude 7320 Detachable (rear OV8856 behind a TPS68470) when unbinding
the driver:

  [  220.072107] unbalanced disables for CORE
  [  220.072109] WARNING: drivers/regulator/core.c:3262 at _regulator_disable+0xc3/0x150, CPU#2: tee/8667
  [  220.072825] tps68470-clk already disabled
  [  220.072828] WARNING: drivers/clk/clk.c:1188 at clk_core_disable+0x82/0x140, CPU#2: tee/8667
  [  220.073620] tps68470-clk already unprepared
  [  220.073623] WARNING: drivers/clk/clk.c:1047 at clk_core_unprepare+0x1cf/0x200, CPU#2: tee/8667

Power the sensor off only if it isn't runtime-suspended, then mark it
suspended, as other sensor drivers such as ov5675 do.

The problem was found, and this patch written, with the help of an AI
coding assistant (Claude Opus 5.5). See the cover letter for details.

Fixes: 0c2c7a1e0d69 ("media: ov8856: Add devicetree support")
Cc: stable@vger.kernel.org
Signed-off-by: Babis Danias <b.danias@tutamail.com>
---
 drivers/media/i2c/ov8856.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov8856.c b/drivers/media/i2c/ov8856.c
index 42c4b9c4e..988ce0310 100644
--- a/drivers/media/i2c/ov8856.c
+++ b/drivers/media/i2c/ov8856.c
@@ -2367,7 +2367,9 @@ static void ov8856_remove(struct i2c_client *client)
 	pm_runtime_disable(ov8856->dev);
 	mutex_destroy(&ov8856->mutex);
 
-	ov8856_power_off(ov8856->dev);
+	if (!pm_runtime_status_suspended(ov8856->dev))
+		ov8856_power_off(ov8856->dev);
+	pm_runtime_set_suspended(ov8856->dev);
 }
 
 static int ov8856_probe(struct i2c_client *client)

-- 
2.56.0

