From: =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
Date: Wed, 03 Sep 2025 16:46:05 +0200
Subject: [PATCH] fec_imx: Fix ENODEV in fec_probe on i.MX27
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250903-fec_imx-fix-enodev-v1-1-0dd4c42fc293@airbus.com>
X-B4-Tracking: v=1; b=H4sIAKxUuGgC/x2MWwqAIBAArxL73cL2wuoqESG21n6koSBCdPekz
 2GYeSByEI4wVw8EThLFuwJNXYE5tTsYZS8MLbUDTdShZbPJldFKRnZ+54RW6YlGRUNvRijhHbj
 Yf7qs7/sBgeaILWQAAAA=
X-Change-ID: 20250903-fec_imx-fix-enodev-f7a9087054c8
To: BAREBOX <barebox@lists.infradead.org>
Cc: =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756910772; l=4139;
 i=christian.thiessen@airbus.com; s=20250902; h=from:subject:message-id;
 bh=XFKPIv88ugljtV+KWINy7eR1OlNtbCCJvHz4x+4ROys=;
 b=MpGSpANLnaOThfS4wPW7Nq+bqT3AlRPMkuA/QPKx7jEvCPDxk7S8IqiQhpb2879YA730rmDcH
 RujByihngNfAE638uYtv+f5ZD/o8aEc+EY76NB6o2W93t5QG10C6l39
X-Developer-Key: i=christian.thiessen@airbus.com; a=ed25519;
 pk=NCvzeydU+5OZKp2shtC3Zp/OS1LfbLmhNZNws46FeWk=
X-Endpoint-Received: by B4 Relay for christian.thiessen@airbus.com/20250902 with auth_id=508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fec_imx driver stores an enum fec_type value in the match data
pointer. When retrieving this value in fec_probe(), it handles
FEC_TYPE_IMX27 (which is 0) like an error result from
device_get_match_data and returns -ENODEV.

To be able to differentiate NULL from errors, introduce a new function
device_get_match_data_default which returns its defaultval argument
instead of NULL in case of errors.
Add an FEC_TYPE_COUNT value to the fec_type enum.
In fec_probe, pass FEC_TYPE_COUNT as defaultval and return -ENODEV for
all type values greater or equal to that.

Fixes: 20d87123a6 ("treewide: replace dev_get_drvdata with        device_get_match_data")
Signed-off-by: Christian Thießen <christian.thiessen@airbus.com>
---
Hi again,

this patch addresses the issue discussed in
https://github.com/barebox/barebox/issues/40 ("fec_imx (and possibly
others): Probe fails with ENODEV").

Cheers,
Christian
---
 drivers/base/driver.c | 13 +++++++++++++
 drivers/net/fec_imx.c | 12 +++++-------
 drivers/net/fec_imx.h |  1 +
 include/driver.h      | 10 ++++++++++
 4 files changed, 29 insertions(+), 7 deletions(-)

diff --git a/drivers/base/driver.c b/drivers/base/driver.c
index 61118385f1df0f8d36208d236be66b077fa5e54d..614c3c26b04c6f252e3970e014a43bae6a1d9c2b 100644
--- a/drivers/base/driver.c
+++ b/drivers/base/driver.c
@@ -690,6 +690,19 @@ const void *device_get_match_data(struct device *dev)
 }
 EXPORT_SYMBOL(device_get_match_data);
 
+const void *device_get_match_data_default(struct device *dev,
+					  const void *defaultval)
+{
+	if (dev->of_id_entry)
+		return dev->of_id_entry->data;
+
+	if (dev->id_entry)
+		return (const void *)dev->id_entry->driver_data;
+
+	return defaultval;
+}
+EXPORT_SYMBOL(device_get_match_data_default);
+
 static void device_set_deferred_probe_reason(struct device *dev,
 					     const struct va_format *vaf)
 {
diff --git a/drivers/net/fec_imx.c b/drivers/net/fec_imx.c
index 8474e6d5be9c6225af5708d21b0249b2618d36f6..fac190e6ea51950ed6085264e12617969847acbf 100644
--- a/drivers/net/fec_imx.c
+++ b/drivers/net/fec_imx.c
@@ -763,20 +763,18 @@ static int fec_probe(struct device *dev)
 	struct fec_priv *fec;
 	void *base;
 	int ret;
-	enum fec_type type;
-	void const *type_v;
+	uintptr_t type_v;
 	int phy_reset;
 	u32 msec = 1, phy_post_delay = 0;
 	u32 reg;
 
-	type_v = device_get_match_data(dev);
-	if (!type_v)
+	type_v = (uintptr_t)device_get_match_data_default(dev,
+		(const void *)FEC_TYPE_COUNT);
+	if (type_v >= FEC_TYPE_COUNT)
 		return -ENODEV;
 
-	type = (uintptr_t)(type_v);
-
 	fec = xzalloc(sizeof(*fec));
-	fec->type = type;
+	fec->type = type_v;
 	fec->dev = dev;
 	edev = &fec->edev;
 	dev->priv = fec;
diff --git a/drivers/net/fec_imx.h b/drivers/net/fec_imx.h
index 1aaff87fddfb44cf558436ab4a846757c6cd51aa..9549dab0f8e88288bd9fe3a02ff8bd5573147842 100644
--- a/drivers/net/fec_imx.h
+++ b/drivers/net/fec_imx.h
@@ -117,6 +117,7 @@ enum fec_type {
 	FEC_TYPE_IMX27,
 	FEC_TYPE_IMX28,
 	FEC_TYPE_IMX6,
+	FEC_TYPE_COUNT,
 };
 
 enum fec_clock {
diff --git a/include/driver.h b/include/driver.h
index c130a3cd63fd5e6dc365a33c765a22dc4e2ca90a..223799294fc0e32ceb13fc5bda2e3b8a78d71647 100644
--- a/include/driver.h
+++ b/include/driver.h
@@ -650,6 +650,16 @@ int cdevfs_del_partition(struct cdev *cdev);
  */
 const void *device_get_match_data(struct device *dev);
 
+/**
+ * device_get_match_data_default - get driver match data associated with device
+ * @dev: device instance
+ * @defaultval: Value to return if no match data is associated with dev
+ *
+ * Returns match data on success and defaultval otherwise
+ */
+const void *device_get_match_data_default(struct device *dev,
+					  const void *defaultval);
+
 int device_match_of_modalias(struct device *dev, const struct driver *drv);
 
 struct device *device_find_child(struct device *parent, void *data,

---
base-commit: 7689314d0a78605e7d4a0c3ce4953d9d768aa343
change-id: 20250903-fec_imx-fix-enodev-f7a9087054c8

Best regards,
-- 
Christian Thießen <christian.thiessen@airbus.com>

