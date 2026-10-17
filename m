From: Tin Posavec <tin.posavec04@gmail.com>
Date: Sat, 17 Oct 2026 10:31:57 +0200
Subject: [PATCH 1/3] media: i2c: ov9734: Return -EPROBE_DEFER if no
 endpoint is found
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-ov9734-ipu6-v1-1-86eab22ae258@gmail.com>
References: <20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com>
In-Reply-To: <20261017-ov9734-ipu6-v1-0-86eab22ae258@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Bingbu Cao <bingbu.cao@amd.com>, Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tin Posavec <tin.posavec04@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792225933; l=2048;
 i=tin.posavec04@gmail.com; s=20261017; h=from:subject:message-id;
 bh=JT2GJOl0pbtZgN6lvGHmUjRBY/6MhdLO/F5PS4KtNhw=;
 b=pExtRj6LrrgRcWLhnjntYE8W+OWWQGNCRml/3FuLz6n0iV+3a75sJw5v6jq+CkPUpp+OTVysN
 waWZNhlwemSA0UgE4+3cghmszKpIYwf4fb6Jl/ZubcOMdKjti7+IFmt
X-Developer-Key: i=tin.posavec04@gmail.com; a=ed25519;
 pk=SHQVmXmK88mO08JT/P9vzu9gKd208IICWLSbsX3TmcI=
X-Endpoint-Received: by B4 Relay for tin.posavec04@gmail.com/20261017 with auth_id=1222
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With ipu-bridge, the fwnode graph endpoint of the sensor is only created
when ipu-bridge is initialized, which may happen after the sensor driver
has first probed. ov9734_check_hwcfg() then returns -ENXIO, so the probe
fails and is not retried, and the sensor stays unbound.

Return -EPROBE_DEFER instead, as several other sensor drivers used with
ipu-bridge do (e.g. ov2740 and hi556), and use dev_err_probe() to record
the reason for the deferral.

Also log an error when parsing the endpoint fails, as the link
frequency checks already do, and drop the generic error message from
probe, which would otherwise be logged on every deferred probe attempt.

Assisted-by: LLM
Signed-off-by: Tin Posavec <tin.posavec04@gmail.com>
---
 drivers/media/i2c/ov9734.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/ov9734.c b/drivers/media/i2c/ov9734.c
index 8f39609ad..f9280ef0e 100644
--- a/drivers/media/i2c/ov9734.c
+++ b/drivers/media/i2c/ov9734.c
@@ -837,14 +837,19 @@ static int ov9734_check_hwcfg(struct device *dev)
 	if (!fwnode)
 		return -ENXIO;
 
+	/*
+	 * Sometimes the fwnode graph is initialized by the bridge driver,
+	 * wait for this.
+	 */
 	ep = fwnode_graph_get_next_endpoint(fwnode, NULL);
 	if (!ep)
-		return -ENXIO;
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "waiting for fwnode graph endpoint\n");
 
 	ret = v4l2_fwnode_endpoint_alloc_parse(ep, &bus_cfg);
 	fwnode_handle_put(ep);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to parse endpoint\n");
 
 	if (!bus_cfg.nr_of_link_frequencies) {
 		dev_err(dev, "no link frequencies defined");
@@ -893,11 +898,8 @@ static int ov9734_probe(struct i2c_client *client)
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

