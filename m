From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:59 +0000
Subject: [PATCH] driver core: fw_devlink: Don't report refused
 sync_state-only links as errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-fw-devlink-sync-state-v1-1-6385be961c2b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPduEcgDxVYyHdXRSNNOsEzWEd
 2fK8Tv8/wImScXgVC2QZFbTRyygQwV+dPEqqEMxNHXTElGN4Y2DzHeNN7Rv9GjZZcHQETvm0Ld
 HhtI+kwT9/L/ny2578SQ+/2awrhuYv127eQAAAA==
X-Change-ID: 20261110-fw-devlink-sync-state-f71babbf968b
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: driver-core@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294718; l=2670;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=im/hNd0AVyCdDuE0XZG+ciJxIyRE1L2sv39Qoyr9F+k=;
 b=VlzWbbYyVi5WPSTZS/BfGJ70oOOrABy71NP7acb8J651n3NHp51NssB8U8cUA0L5Xh6DiflGJ
 B/3mufVOdNNBMn8grQFkm+tFxd/kXn7sjYrp7Tb6dvnIKEEMys5j2bx
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A SYNC_STATE_ONLY device link is refused by device_link_add() once the
consumer has already probed, since such a link only orders sync_state()
callbacks and would be useless. This legitimately happens when a consumer
that probes early (for example the Rockchip power domain provider, whose
domains reference a PMIC regulator through domain-supply) is inferred to
depend on a supplier device that is added later, and results in boot-time
"Failed to create device link (0x180)" errors for a harmless condition.

Log the refusal of a sync_state-only link at debug level and keep the error
for links that matter for probe ordering.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S): the three "Failed to create device
link (0x180)" lines that the Rockchip power controller logged on every
boot (suppliers: the RK806 PMIC on SPI and an RK8602 on I2C, referenced
through domain-supply of two of its power domains) are gone, and the
regulators are still acquired and held by those domains.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/base/core.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/base/core.c b/drivers/base/core.c
index bf97b06337a1..4cdfc156ffbc 100644
--- a/drivers/base/core.c
+++ b/drivers/base/core.c
@@ -2241,8 +2241,20 @@ static int fw_devlink_create_devlink(struct device *con,
 		}
 
 		if (con != sup_dev && !device_link_add(con, sup_dev, flags)) {
-			dev_err(con, "Failed to create device link (0x%x) with supplier %s for %pfwf\n",
-				flags, dev_name(sup_dev), link->consumer);
+			/*
+			 * A SYNC_STATE_ONLY link only orders sync_state() and
+			 * is refused once the consumer has probed. That is
+			 * expected when a consumer that probes early (e.g. a
+			 * power domain provider referencing a regulator
+			 * supplier that is added later) is linked to a late
+			 * supplier, so don't report it as an error.
+			 */
+			if (device_link_flag_is_sync_state_only(flags))
+				dev_dbg(con, "Not creating sync_state-only device link (0x%x) with supplier %s for %pfwf\n",
+					flags, dev_name(sup_dev), link->consumer);
+			else
+				dev_err(con, "Failed to create device link (0x%x) with supplier %s for %pfwf\n",
+					flags, dev_name(sup_dev), link->consumer);
 			ret = -EINVAL;
 		}
 

---
base-commit: ec1db86e7bb3ec13c90456efac43659a723ac068
change-id: 20261110-fw-devlink-sync-state-f71babbf968b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

