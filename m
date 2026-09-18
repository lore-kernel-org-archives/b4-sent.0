From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:32 +0800
Subject: [PATCH 17/21] media: i2c: it6625: require a DT endpoint and
 simplify endpoint parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-17-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=3504;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=MkgaFi0YkzZts+Nod07WKhmRFmBveGro/77MU+eqB+8=;
 b=55NHn9PbFvUfsc4RiYBDrjDl6wKwG8O7ronfw6KPa+uiUp4YyDfEJZPLQGg1HKKEwU0J9zGqP
 d0Y6bpO7SO4BmGBkRdBhVZZUKYuO2RhudMoaDeUarN/UAjvVe67XbZ5
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_init_data() preset csi_lanes/port_num/bus_type before DT
parsing ran, and it6625_parse_endpoint() fell back to those hardcoded
defaults whenever no CSI-2 endpoint node was found instead of failing.
The binding requires port@0, so a missing endpoint should surface as a
probe error, not silently apply a hardcoded D-PHY/4-lane
configuration.

Drop the presets from it6625_init_data() -- these values must come
only from DT -- and delete the no-endpoint fallback entirely rather
than reshaping it. This is safe: of_fwnode_handle(NULL) returns NULL,
and v4l2_fwnode_endpoint_alloc_parse() -> __v4l2_fwnode_endpoint_parse()
already returns -EPROBE_DEFER for a NULL fwnode before touching
anything else, which is a strictly better result for the no-endpoint
case than a driver-local -EINVAL.

While here, consolidate the three -EINVAL return sites in
it6625_parse_endpoint() through a single error-path label instead of
repeating v4l2_fwnode_endpoint_free() at each one.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 26 +++++++++-----------------
 1 file changed, 9 insertions(+), 17 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 4a54de2eb42bba7a6efc84c0b43cad4d2465d3a7..5fa8441f073691425c64fbd2b4e537129a43a2b7 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -2050,9 +2050,6 @@ static void it6625_init_data(struct it6625 *it6625)
 	static struct v4l2_dv_timings default_timing =
 			V4L2_DV_BT_CEA_1920X1080P60;
 
-	it6625->csi_lanes = 4;
-	it6625->port_num = 1;
-	it6625->bus_type = V4L2_MBUS_CSI2_DPHY;
 	it6625->csi_format = it6625_formats[0].csi_format;
 	it6625->mbus_fmt_code = it6625_formats[0].mbus_fmt_code;
 	it6625->timings = default_timing;
@@ -2098,13 +2095,6 @@ static int it6625_parse_endpoint(struct it6625 *it6625)
 			of_node_put(port_ep);
 	}
 
-	if (!ep) {
-		it6625->port_num = 1;
-		dev_dbg(dev, "no CSI-2 endpoint node found, using default %u CSI lanes",
-			it6625->csi_lanes);
-		return 0;
-	}
-
 	ret = v4l2_fwnode_endpoint_alloc_parse(of_fwnode_handle(ep), &endpoint);
 	of_node_put(ep);
 	if (ret) {
@@ -2116,15 +2106,15 @@ static int it6625_parse_endpoint(struct it6625 *it6625)
 	    endpoint.bus_type != V4L2_MBUS_CSI2_CPHY) {
 		dev_err(dev, "unsupported bus type %d, expected CSI-2 D-PHY or C-PHY",
 			endpoint.bus_type);
-		v4l2_fwnode_endpoint_free(&endpoint);
-		return -EINVAL;
+		ret = -EINVAL;
+		goto out_free_endpoint;
 	}
 
 	if (endpoint.bus_type == V4L2_MBUS_CSI2_CPHY &&
 	    it6625->chip_type != IT6626_CHIP) {
 		dev_err(dev, "IT6625 does not support C-PHY, only IT6626 does");
-		v4l2_fwnode_endpoint_free(&endpoint);
-		return -EINVAL;
+		ret = -EINVAL;
+		goto out_free_endpoint;
 	}
 
 	max_lanes = (endpoint.bus_type == V4L2_MBUS_CSI2_CPHY) ? 3 : 4;
@@ -2134,15 +2124,17 @@ static int it6625_parse_endpoint(struct it6625 *it6625)
 		dev_err(dev,
 			"invalid number of CSI data lanes: %u (max %u for this bus type)",
 			endpoint.bus.mipi_csi2.num_data_lanes, max_lanes);
-		v4l2_fwnode_endpoint_free(&endpoint);
-		return -EINVAL;
+		ret = -EINVAL;
+		goto out_free_endpoint;
 	}
 
 	it6625->csi_lanes = endpoint.bus.mipi_csi2.num_data_lanes;
 	it6625->bus_type = endpoint.bus_type;
+
+out_free_endpoint:
 	v4l2_fwnode_endpoint_free(&endpoint);
 
-	return 0;
+	return ret;
 }
 
 static int it6625_parse_dt(struct it6625 *it6625)

-- 
2.34.1

