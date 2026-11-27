From: Fabio Forni <development@redaril.me>
Date: Sat, 28 Nov 2026 00:22:09 +0100
Subject: [PATCH v2 1/2] drivers: core: platform: Add
 platform_get_match_data() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-iio_rescale_platform_ids-v2-1-4c35f16c4f77@redaril.me>
References: <20261128-iio_rescale_platform_ids-v2-0-4c35f16c4f77@redaril.me>
In-Reply-To: <20261128-iio_rescale_platform_ids-v2-0-4c35f16c4f77@redaril.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Peter Rosin <peda@lysator.liu.se>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: driver-core@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2613;
 i=development@redaril.me; h=from:subject:message-id;
 bh=rc/1GfvZE2caXdT5SgAYu19YzMLIslhAQZef0ezkqlo=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLK5BDYmlpf3L+LeVz9x/Vt1ze/S6WsKGX/GM2W56R7NE
 pcSu+TSUcrCIMbFICumyPLfyWhTt5mJ0a1+iVqYOaxMIEMYuDgFYCJ60xn+R/H1XtZSOhpTMUvZ
 qj7YLfCpWuY7/3ctOV2u07T+3Vq9kpHhvYLQdrG9UVJRD1fqTFc7lvLu8tvlZS0/JD6nsf2v5Op
 mBQA=
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

device_get_match_data() retrieves driver data through the device's
fwnode. However, software nodes don't implement
fwnode->device_get_match_data(), so for a platform device that is
dynamically instantiated, device_get_match_data() is of no use.
platform_get_device_id() can be used instead, but this doesn't make the
driver code abstract enough.

Add the platform_get_match_data() helper, so that driver data can be
retrieved from platform_device's fwnode *or* device_id as a fallback.

Signed-off-by: Fabio Forni <development@redaril.me>
---
 drivers/base/platform.c         | 28 ++++++++++++++++++++++++++++
 include/linux/platform_device.h |  2 ++
 2 files changed, 30 insertions(+)

diff --git a/drivers/base/platform.c b/drivers/base/platform.c
index 3593d45f4a7a..7db56ffbb6b1 100644
--- a/drivers/base/platform.c
+++ b/drivers/base/platform.c
@@ -1090,6 +1090,34 @@ int __init_or_module __platform_driver_probe(struct platform_driver *drv,
 }
 EXPORT_SYMBOL_GPL(__platform_driver_probe);
 
+/**
+ * platform_get_match_data - get match data from fwnode or device ID
+ * @pdev: platform device to get data of
+ *
+ * Get match data from fwnode if available, otherwise get match data
+ * from pdev's platform_device_id->driver_data. driver_data is
+ * cast into a void* pointer.
+ *
+ * Return: -ENODATA if no match data is available.
+ */
+const void *platform_get_match_data(const struct platform_device *pdev)
+{
+	const struct platform_device_id *id;
+	const void *ret;
+
+	ret = device_get_match_data(&pdev->dev);
+	if (ret)
+		return ret;
+
+	id = platform_get_device_id(pdev);
+	if (id && id->driver_data)
+		return (const void *)id->driver_data;
+
+	return ERR_PTR(dev_err_probe(&pdev->dev, -ENODATA,
+				     "no match data available"));
+}
+EXPORT_SYMBOL_GPL(platform_get_match_data);
+
 /**
  * __platform_create_bundle - register driver and create corresponding device
  * @driver: platform driver structure
diff --git a/include/linux/platform_device.h b/include/linux/platform_device.h
index 3bd0f1f0d870..426148768b38 100644
--- a/include/linux/platform_device.h
+++ b/include/linux/platform_device.h
@@ -326,6 +326,8 @@ static inline void platform_set_drvdata(struct platform_device *pdev,
 	dev_set_drvdata(&pdev->dev, data);
 }
 
+const void *platform_get_match_data(const struct platform_device *pdev);
+
 /* module_platform_driver() - Helper macro for drivers that don't do
  * anything special in module init/exit.  This eliminates a lot of
  * boilerplate.  Each module may only use this macro once, and

-- 
2.56.1

