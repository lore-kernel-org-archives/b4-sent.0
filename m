From: Markus Haberlander <markus.haberlander@rosenberger.com>
Date: Mon, 23 Nov 2026 13:33:49 +0100
Subject: [PATCH] i2c: cgbc: Fetch the status of a write transfer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cgbc-i2c-write-status-v1-1-5b0fa0322b57@rosenberger.com>
X-B4-Tracking: v=1; b=H4sIAKwyBGsC/y2OS24DIRBErzJiHSRoeoDxVSIv6KbHJpI/ASaxZ
 PnuxnGWT6p6VXfVpBZpajfdVZWf0srlPMB+TIqP6XwQXfJgBQa8teA0H4h1Ada/tXTRrae+NQ1
 mxTlImGNY1Oheq6zl9uf93L+5bfQl3F+y/0SV720M9ndMXVPn45jbTSgQsosy24wLmBwQQ0wkw
 WdMYhIgmuycvDyUmmi+nE6lj9tMAXwk711ktHZlB6sLThY/C0VKiywEhGr/eDwBSvegF/sAAAA
 =
X-Change-ID: 20261123-cgbc-i2c-write-status-20f457e75879
To: Thomas Richard <thomas.richard@bootlin.com>, 
 Andi Shyti <andi.shyti@kernel.org>
Cc: Lee Jones <lee@kernel.org>, mfd@lists.linux.dev, 
 linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Markus Haberlander <markus.haberlander@rosenberger.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795437231; l=3950;
 i=markus.haberlander@rosenberger.com; s=20261123; h=from:subject:message-id;
 bh=XQwD6EKXMi+lwJWT9kCfMA1cmv/s0ZvtS6yQ8uN2KzM=;
 b=NZLJpn+y3fV4UzqY8xCgHdLb8y/ndlimNJyE9xDBp025pxxjv43FgrolBchQx1geGMSqthwKc
 G0pIgwfE/iRBVmyglI0BJ/p9hgMdp+wTZtJa2a5z1RFoVwwigO86i7D
X-Developer-Key: i=markus.haberlander@rosenberger.com; a=ed25519;
 pk=baNIWlZCf58g17gE2FS6ir0ymNwyBXguoQENSJkXdeQ=
X-Endpoint-Received: by B4 Relay for markus.haberlander@rosenberger.com/20261123 with auth_id=1612
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A write transfer sends the I2C command to the board controller and
returns without reading the controller's I2C status, while a read polls
the status until the controller is no longer busy. The status of a write
is therefore never fetched:

- the write reports success before the bus transfer has finished, and
  an error such as a NAK is only reported by the next transfer;
- the controller keeps the status of the last write pending. On a
  conga-PA7 (BIOS PA70R026, board controller CGBCP032), a board reset
  with a write status pending does not power the board up again: after
  a reboot that follows a write on the general purpose bus, the board
  stays off until it is power cycled.

Read the status after a write as well, as the read path does: poll until
the controller is no longer busy, return the error it reports, and treat
any state other than idle as an error.

Tested on a conga-PA7 with v6.18.64 and "i2c: cgbc: Propagate hardware
errors when polling read status": without this patch, a write to an
absent address returns success, the next read fails, and a reboot after
a write does not come back. With it, the write itself fails, the next
transfer succeeds, and 14 reboots, each right after an acknowledged or a
NAKed write, all came back.

The patch and this changelog were drafted with the help of Claude
Opus 5.5 and reviewed and tested by me.

Fixes: 6894f640b8f3 ("i2c: Congatec Board Controller i2c bus driver")
Cc: stable@vger.kernel.org
Signed-off-by: Markus Haberlander <markus.haberlander@rosenberger.com>
---
Hi Thomas, hi all,

this is my first patch for this driver, so please bear with me if
something is not done the usual way.

We use the conga-PA7 in a product, with the mainline cgbc drivers. While
bringing it up, we found that the board does not power up again after a
reboot that follows an I2C write on the general purpose bus. The patch
below describes the cause and fixes it.

While preparing it, I saw your series "Congatec Board Controller: Add
storage devices support" v6:
https://lore.kernel.org/r/20261117-cgbc-i2c-storage-devices-support-v6-0-bb070ad3e9aa@bootlin.com
Its patch 2/10 ("i2c: cgbc: Propagate hardware errors when polling read
status") fixes the read side of the same function, and this patch is the
write side of it. As Lee wants to take the series as a whole, I based it
on top of 2/10 rather than send something that conflicts with it.

Whatever suits you best is fine with me: carrying it in a v7 right after
2/10, or me resending it once your series is applied. Right after 2/10,
it backports to stable together with 2/10, as both carry Cc: stable.
After 5/10, it would no longer build on stable kernels without
"i2c->read_maxtime_us", so I would send the backport myself.

Thanks for having a look!
---
 drivers/i2c/busses/i2c-cgbc.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/i2c/busses/i2c-cgbc.c b/drivers/i2c/busses/i2c-cgbc.c
index dfdb9ffc6..2361591a1 100644
--- a/drivers/i2c/busses/i2c-cgbc.c
+++ b/drivers/i2c/busses/i2c-cgbc.c
@@ -254,6 +254,22 @@ static int cgbc_i2c_xfer_msg(struct i2c_adapter *adap)
 		ret = cgbc_command(cgbc, &cmd, cmd_len, NULL, 0, NULL);
 		if (ret)
 			goto err;
+
+		ret = read_poll_timeout(cgbc_i2c_get_status, status,
+					status != CGBC_I2C_STAT_BUSY, 0,
+					2 * algo_data->read_maxtime_us, false, adap);
+		if (ret)
+			goto err;
+
+		if (status < 0) {
+			ret = status;
+			goto err;
+		}
+
+		if (status != CGBC_I2C_STAT_IDL) {
+			ret = -EIO;
+			goto err;
+		}
 	} else if (i2c->state == CGBC_I2C_STATE_READ) {
 		xfer.write = 0;
 		xfer.read = len;

---
base-commit: 1cb7268b6638c411fc32f373e965eb8ba9e9b2b4
change-id: 20261123-cgbc-i2c-write-status-20f457e75879
prerequisite-patch-id: 4e27d38e51d4920d74478abe76d4ae0a2440d33e

Best regards,
--  
Markus Haberlander <markus.haberlander@rosenberger.com>

