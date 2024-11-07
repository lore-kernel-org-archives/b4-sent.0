From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 07 Nov 2024 22:20:06 +0100
Subject: [PATCH] iio: imu: inv_icm42600: fix spi burst write not supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-inv-icm42600-fix-spi-burst-write-not-supported-v1-1-800b22574d01@tdk.com>
X-B4-Tracking: v=1; b=H4sIAAUvLWcC/x2NQQ6CMBAAv0L27CZtQap+hXBAuuAebJvdgiaEv
 9t4nMPMHKAkTAqP5gChnZVTrGAvDcyvKa6EHCqDM66z1njkuCPP7871xuDCX9TM+NxEC36EC2F
 MBXXLOUmhgLSQvwXf+vt0hRrNQlX6D4fxPH9mAghhgAAAAA==
X-Change-ID: 20241107-inv-icm42600-fix-spi-burst-write-not-supported-efe78d7379a5
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731014416; l=2772;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=eEsvkfouCdMgwkJJdk752XAqwbz3MkUlI7SGBMxVUEA=;
 b=rGRs/voApe1d3FHAtobH1O1wnVlfw8ltZ85xR27K9NB5sP2Y6y0Ko+FLzwKAKK1tSmud64sjq
 8rH/UkcvuMHBG90IpziZBixkIu53Rx/IjT5HG3d7/SkMxXT7fmT59R5
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Burst write with SPI is not working for all icm42600 chips. It was
only used for setting user offsets with regmap_bulk_write.

Allow tweak of common regmap_config for using only single write for
spi.

Fixes: 9f9ff91b775b ("iio: imu: inv_icm42600: add SPI driver for inv_icm42600 driver")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h      | 2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c | 2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c  | 3 +++
 3 files changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index 3a07e43e4cf154f3107c015c30248330d8e677f8..36a3b0795fb7d6cb0c178fadd93896fbc346ba0d 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -402,7 +402,7 @@ struct inv_icm42600_sensor_state {
 
 typedef int (*inv_icm42600_bus_setup)(struct inv_icm42600_state *);
 
-extern const struct regmap_config inv_icm42600_regmap_config;
+extern struct regmap_config inv_icm42600_regmap_config;
 extern const struct dev_pm_ops inv_icm42600_pm_ops;
 
 const struct iio_mount_matrix *
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index 93b5d7a3339ccff16b21bf6c40ed7b2311317cf4..680373f6267b37d386e4e7bda543ba4efe97e66b 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -74,7 +74,7 @@ static const struct regmap_access_table inv_icm42600_regmap_rd_noinc_accesses[]
 	},
 };
 
-const struct regmap_config inv_icm42600_regmap_config = {
+struct regmap_config inv_icm42600_regmap_config = {
 	.name = "inv_icm42600",
 	.reg_bits = 8,
 	.val_bits = 8,
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
index 3b6d05fce65d544524b25299c6d342af92cfd1e0..73cacfd157a4538ae8c9d1c8d97157afa28aa672 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
@@ -59,6 +59,9 @@ static int inv_icm42600_probe(struct spi_device *spi)
 		return -EINVAL;
 	chip = (uintptr_t)match;
 
+	/* spi doesn't support burst write */
+	inv_icm42600_regmap_config.use_single_write = true;
+
 	regmap = devm_regmap_init_spi(spi, &inv_icm42600_regmap_config);
 	if (IS_ERR(regmap))
 		return PTR_ERR(regmap);

---
base-commit: c9f8285ec18c08fae0de08835eb8e5953339e664
change-id: 20241107-inv-icm42600-fix-spi-burst-write-not-supported-efe78d7379a5

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

