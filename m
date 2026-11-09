From: Tin Posavec <tin.posavec04@gmail.com>
Date: Mon, 09 Nov 2026 19:17:50 +0100
Subject: [PATCH v2 1/3] media: i2c: ov9734: Return -EPROBE_DEFER if no
 endpoint is found
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ov9734-ipu6-v2-1-0481b512c4c0@gmail.com>
References: <20261109-ov9734-ipu6-v2-0-0481b512c4c0@gmail.com>
In-Reply-To: <20261109-ov9734-ipu6-v2-0-0481b512c4c0@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Afonso Figuinha <afonso.figuinha@gmail.com>, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794248315; l=1997;
 i=tin.posavec04@gmail.com; s=20261109; h=from:subject:message-id;
 bh=hZlhgr7t27xWi5riQyDtNa929Y92ZQWSKOxXOnT5Jec=;
 b=1DQaXamNgIOeEsrMg8uF62lXMBw7Lki1z4WySjsX17gDSYQITGxwLmUDvjflXhtae4Q3fUsFb
 aoNOcnFjGK+Btf0U9LGIM86BCKPH24Fswcpcwlh0bplyCrWE63Jo0me
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=h4O+VaAXzwd3B9L6H8RltugTkzF65lam1c1ls5knAVg=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261109 with auth_id=1463
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With ipu-bridge, the fwnode graph endpoint of the sensor is only created
when ipu-bridge is initialized, which may happen after the sensor driver
has first probed. ov9734_check_hwcfg() then returns -ENXIO, so the probe
fails and is not retried, and the sensor stays unbound.

Drop the check for a missing endpoint and return the error code of
v4l2_fwnode_endpoint_alloc_parse() instead, which is -EPROBE_DEFER for
a NULL endpoint since commit 8015a49d8b33 ("media: v4l2-fwnode: Return
-EPROBE_DEFER on parsing NULL endpoints"). Report the error with
dev_err_probe(), so that the reason for a deferral is recorded and
parsing errors are logged.

Also drop the generic error message from probe, which would otherwise
be logged on every deferred probe attempt.

Signed-off-by: Tin Posavec <tin.posavec04@gmail.com>
Tested-by: Afonso Figuinha <afonso.figuinha@gmail.com> # Surface Laptop 1 (IPU3)
---
 drivers/media/i2c/ov9734.c | 10 ++--------
 1 file changed, 2 insertions(+), 8 deletions(-)

diff --git a/drivers/media/i2c/ov9734.c b/drivers/media/i2c/ov9734.c
index 8f39609ad..49711fa17 100644
--- a/drivers/media/i2c/ov9734.c
+++ b/drivers/media/i2c/ov9734.c
@@ -838,13 +838,10 @@ static int ov9734_check_hwcfg(struct device *dev)
 		return -ENXIO;
 
 	ep = fwnode_graph_get_next_endpoint(fwnode, NULL);
-	if (!ep)
-		return -ENXIO;
-
 	ret = v4l2_fwnode_endpoint_alloc_parse(ep, &bus_cfg);
 	fwnode_handle_put(ep);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to parse endpoint\n");
 
 	if (!bus_cfg.nr_of_link_frequencies) {
 		dev_err(dev, "no link frequencies defined");
@@ -893,11 +890,8 @@ static int ov9734_probe(struct i2c_client *client)
 	int ret;
 
 	ret = ov9734_check_hwcfg(&client->dev);
-	if (ret) {
-		dev_err(&client->dev, "failed to check HW configuration: %d",
-			ret);
+	if (ret)
 		return ret;
-	}
 
 	ov9734 = devm_kzalloc(&client->dev, sizeof(*ov9734), GFP_KERNEL);
 	if (!ov9734)

-- 
2.53.0

