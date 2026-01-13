From: Fredrik Markstrom <fredrik.markstrom@est.tech>
Date: Tue, 13 Jan 2026 14:08:53 +0100
Subject: [PATCH] i3c: master: Set the device name only after we initialize
 i3c_bus->id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-set_i3c_master_name-v1-1-eafc5dcd1eee@est.tech>
X-B4-Tracking: v=1; b=H4sIAORDZmkC/x3M0QpAMBSH8VfRubYyRngVaS3+OBdGO5Ja3t1y+
 bv4vkiCwBDqs0gBNwsfPkHnGU2b8ysUz8lUFmVTaF0pwWW5muzu5EKw3u1QZoGp57rtdGMolWf
 Aws9/Hcb3/QArezuKZQAAAA==
X-Change-ID: 20260113-set_i3c_master_name-4fe45d589164
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>
Cc: linux-i3c@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Fredrik Markstrom <fredrik.markstrom@est.tech>, 
 Ivar Holmqvist <ivar.holmqvist@est.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768309749; l=1634;
 i=fredrik.markstrom@est.tech; s=20260113; h=from:subject:message-id;
 bh=Cj/PcPQgBRHLVNwxGOBxQSUcqNPrcPktOg7QDmunmp0=;
 b=zQP+HGju9wkWqadBVxYUs2O19SAd49QBc7kFC8efIx6zOKkv65y4yCnB5sn6NZrksufqZxLPm
 ZmFYHawN1iPAVRX1G+zObPMQ3D5mVCvXSuT5ntV+MwCBqpn/Y3azjVn
X-Developer-Key: i=fredrik.markstrom@est.tech; a=ed25519;
 pk=0a8IXHEgAX55JPS8VZfTf1sDp7q/oAOf459tDQd40Eg=
X-Endpoint-Received: by B4 Relay for fredrik.markstrom@est.tech/20260113 with auth_id=600
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The i3c_bus->id field is used to construct the unique name of the I3C
bus device. This field is initialized and assigned its unique value
within the i3c_bus_init() function.

However, the existing code was referencing i3c_bus->id *before* the
call to i3c_bus_init(), leading to all the masters having the same
device name string.

This commit moves the reference to i3c_bus->id to *after* the call to
i3c_bus_init().

Fixes: 9d4f219807d5 ("i3c: fix refcount inconsistency in i3c_master_register")
Signed-off-by: Fredrik Markstrom <fredrik.markstrom@est.tech>
Reviewed-by: Ivar Holmqvist <ivar.holmqvist@est.tech>
---
 drivers/i3c/master.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/i3c/master.c b/drivers/i3c/master.c
index 7f606c871648..1bc3c9068402 100644
--- a/drivers/i3c/master.c
+++ b/drivers/i3c/master.c
@@ -2881,7 +2881,6 @@ int i3c_master_register(struct i3c_master_controller *master,
 	INIT_LIST_HEAD(&master->boardinfo.i3c);
 
 	device_initialize(&master->dev);
-	dev_set_name(&master->dev, "i3c-%d", i3cbus->id);
 
 	master->dev.dma_mask = parent->dma_mask;
 	master->dev.coherent_dma_mask = parent->coherent_dma_mask;
@@ -2891,6 +2890,8 @@ int i3c_master_register(struct i3c_master_controller *master,
 	if (ret)
 		goto err_put_dev;
 
+	dev_set_name(&master->dev, "i3c-%d", i3cbus->id);
+
 	ret = of_populate_i3c_bus(master);
 	if (ret)
 		goto err_put_dev;

---
base-commit: 0f61b1860cc3f52aef9036d7235ed1f017632193
change-id: 20260113-set_i3c_master_name-4fe45d589164

Best regards,
-- 
Fredrik Markstrom <fredrik.markstrom@est.tech>

