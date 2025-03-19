From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:42 +0100
Subject: [PATCH v2 03/13] iio: light: al3010: Remove DRV_NAME definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-3-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1274; i=david@ixit.cz;
 h=from:subject:message-id; bh=rjD7NN5hHGkzdwx0H9EXzCR9U7T+XzOGq1m3plbXlAM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9al3AYypMpivfMaBR1hM1f2Y7pM8bS3dry
 CzxjkJTbj2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 cpucEACjlvOHIMuHfuq5nzpaSfeMcnWUsm5WePgke94UZjrUunMzIVhjS7MpzSKu5Kq7YNSiOI9
 n5PEZNW/bq4tAme726JfDF4A9hveQhHEOwJmj3pa81Or8SBXiA5pp2PJY2IfoYM6KN/rh7W9Rzf
 x6XsfdXq0NI9m3X1zztyK/oK5VGYA/67UaShLtFKH6s4r/gxp+iyHvE86dO88NBtZQnTngQGXVR
 FNC4fKZK/Plt7ImP66lhFxbqmHW3Jg4PV7dktE7Vf0+g2pz4H1tG93Uq94UzIHuh0FK94x/Fifp
 MZjEdOowVt9bDYakZTfABwVUO3CYpgTe/DUTvp/Gt2rxr3aMDqkvUIsvLJDEIfRDBfcLLez98lA
 EjZ8UCNdpJX6MxBoUkkuJWC0F2Df8dytkngAOzSaBYULlXO4otgwxoxvwty4jMZ+Y/MER8wEY7Y
 iBomR+fWFX8s1eexbUj966X21OVtUj8HjNPsOy7XdVYUx502pmBrxszX1ApCoT2ONv+BD7kBa1p
 JdtkCqMDkt8/03bAhKvh2PO0P7HLaTXBaPNWR79oG52ZbIQK4p5aj55YXy69RxMkBRoRJilcDej
 dPR84mpC+wYUuzJ9maV7hJurJFNoR0HDuh9r4qAIq+OMhP9iu3AWijzRtkT1ccVP/5nCPaS7GNP
 56GijoWPvme8d3A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver name should be passed directly.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 4c2fd88ab32cd73f4735b0fa3014af084037c94d..7fe91049b55e57558aef69d088d168437a6819ec 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -22,8 +22,6 @@
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
-#define AL3010_DRV_NAME "al3010"
-
 #define AL3010_REG_SYSTEM		0x00
 #define AL3010_REG_DATA_LOW		0x0c
 #define AL3010_REG_CONFIG		0x10
@@ -184,7 +182,7 @@ static int al3010_probe(struct i2c_client *client)
 	data->client = client;
 
 	indio_dev->info = &al3010_info;
-	indio_dev->name = AL3010_DRV_NAME;
+	indio_dev->name = "al3010";
 	indio_dev->channels = al3010_channels;
 	indio_dev->num_channels = ARRAY_SIZE(al3010_channels);
 	indio_dev->modes = INDIO_DIRECT_MODE;
@@ -224,7 +222,7 @@ MODULE_DEVICE_TABLE(of, al3010_of_match);
 
 static struct i2c_driver al3010_driver = {
 	.driver = {
-		.name = AL3010_DRV_NAME,
+		.name = "al3010",
 		.of_match_table = al3010_of_match,
 		.pm = pm_sleep_ptr(&al3010_pm_ops),
 	},

-- 
2.49.0

