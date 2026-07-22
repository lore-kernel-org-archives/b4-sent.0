From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 22 Jul 2026 10:42:47 +0200
Subject: [PATCH RFC 2/2] regmap: implement no-sequential-read firmware
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-regmap-single-read-v1-2-aaaf31591669@linux.dev>
References: <20260722-regmap-single-read-v1-0-aaaf31591669@linux.dev>
In-Reply-To: <20260722-regmap-single-read-v1-0-aaaf31591669@linux.dev>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Alexander Stein <alexander.stein@ew.tq-group.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 driver-core@lists.linux.dev, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784709824; l=2027;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=FSQEUR5lT0QLgko7oEg3PWkGA9UVMNb6nFeAFck4zDA=;
 b=yhW5fWkALMD91mWste1/aLkqZojp0RQkFIQWkzILzZZXVRUTbbPSSSLnD4VoDSvfUAdSzATdi
 9GEwKk+OvUdAYg8MHRD/hVLN4b+AktqlRnF8p1/PD/BIVsni8XiYVG4
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices are integrated in hardware modules where incrementing
multi-register reads are not reliable, even though the underlying chip
normally supports them.

regmap already owns a configuration that selects between bulk reads and
single-register reads. Letting regmap consume this firmware property
makes use of this configuration and therefore keeps the override in the
actual layer of implementation.

If the property is absent, existing behaviour is unchanged.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/base/regmap/regmap.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/base/regmap/regmap.c b/drivers/base/regmap/regmap.c
index e6e022b026375..ed08db764cdcb 100644
--- a/drivers/base/regmap/regmap.c
+++ b/drivers/base/regmap/regmap.c
@@ -674,6 +674,18 @@ enum regmap_endian regmap_get_val_endian(struct device *dev,
 }
 EXPORT_SYMBOL_GPL(regmap_get_val_endian);
 
+static bool regmap_get_use_single_read(struct device *dev,
+				       const struct regmap_bus *bus,
+				       const struct regmap_config *config)
+{
+	struct fwnode_handle *fwnode = dev ? dev_fwnode(dev) : NULL;
+
+	if (fwnode_property_read_bool(fwnode, "no-sequential-read"))
+		return true;
+
+	return config->use_single_read || !(config->read || (bus && bus->read));
+}
+
 struct regmap *__regmap_init(struct device *dev,
 			     const struct regmap_bus *bus,
 			     void *bus_context,
@@ -786,7 +798,7 @@ struct regmap *__regmap_init(struct device *dev,
 		map->reg_stride_order = ilog2(map->reg_stride);
 	else
 		map->reg_stride_order = -1;
-	map->use_single_read = config->use_single_read || !(config->read || (bus && bus->read));
+	map->use_single_read = regmap_get_use_single_read(dev, bus, config);
 	map->use_single_write = config->use_single_write || !(config->write || (bus && bus->write));
 	map->can_multi_write = config->can_multi_write && (config->write || (bus && bus->write));
 	if (bus) {

-- 
2.53.0

