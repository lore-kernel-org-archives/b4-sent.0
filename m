From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 10 Jan 2026 12:26:26 +0530
Subject: [PATCH v3 08/14] serdev: Add support for swnode based driver
 matching and uevent/modalias
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-pci-m2-e-v3-8-4faee7d0d5ae@oss.qualcomm.com>
References: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
In-Reply-To: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1971;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ztgleD54+6Zk3c7WxZw+JwZdp+qXwtb/lr5ljYSVfhE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpYfg9QNXjpaheJP5YAT8ny7fL5q87y0Zdwg2/U
 gsFL4mjHGqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWH4PQAKCRBVnxHm/pHO
 9T4vCACF2a5507fcpAKDXWuFhB/oYAjv61TYBcrL2Z5hZg5EHYqirBilvLQC9qcrr09bB/BxeJj
 GG0ov28WTuPluQ6ViKsenJveutLYm4bYch5fgua61cf34pkub6VMv+02aRjItRZ2K9iElznvuAk
 GDZ8qSNoOmhTAvjnvW32wEFbGgtoS07B9vxbAHJ0nN9JjL57Q4As+cJi6iOLO/ah/os6m+Ya5cS
 gMe1Be9zM55LiW+SC0VwEdazv1i8hZJ7EoQQqkET+UnZ0Vv0+T6weAIekMUH+y/dsEVsxBe/Or/
 f+wnEdqqZiPGbona7MGvCtxh4ncWT3sXCV6FSLbXb9D8EGYt
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Serdev devices that do not use OF or ACPI can use swnode to expose the
device specific properties that could be used to match the serdev driver.
For such devices, provide the swnode based driver matching and
uevent/modalias support.

If a serdev device doesn't support neither OF, nor ACPI, swnode will be
tried as a last resort.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/tty/serdev/core.c | 20 ++++++++++++++------
 1 file changed, 14 insertions(+), 6 deletions(-)

diff --git a/drivers/tty/serdev/core.c b/drivers/tty/serdev/core.c
index f8093b606dda..9d42bd5f550a 100644
--- a/drivers/tty/serdev/core.c
+++ b/drivers/tty/serdev/core.c
@@ -35,7 +35,11 @@ static ssize_t modalias_show(struct device *dev,
 	if (len != -ENODEV)
 		return len;
 
-	return of_device_modalias(dev, buf, PAGE_SIZE);
+	len = of_device_modalias(dev, buf, PAGE_SIZE);
+	if (len != -ENODEV)
+		return len;
+
+	return software_node_device_modalias(dev, buf, PAGE_SIZE);
 }
 static DEVICE_ATTR_RO(modalias);
 
@@ -49,13 +53,15 @@ static int serdev_device_uevent(const struct device *dev, struct kobj_uevent_env
 {
 	int rc;
 
-	/* TODO: platform modalias */
-
 	rc = acpi_device_uevent_modalias(dev, env);
 	if (rc != -ENODEV)
 		return rc;
 
-	return of_device_uevent_modalias(dev, env);
+	rc = of_device_uevent_modalias(dev, env);
+	if (rc != -ENODEV)
+		return rc;
+
+	return software_node_device_uevent(dev, env);
 }
 
 static void serdev_device_release(struct device *dev)
@@ -91,11 +97,13 @@ static int serdev_device_match(struct device *dev, const struct device_driver *d
 	if (!is_serdev_device(dev))
 		return 0;
 
-	/* TODO: platform matching */
 	if (acpi_driver_match_device(dev, drv))
 		return 1;
 
-	return of_driver_match_device(dev, drv);
+	if (of_driver_match_device(dev, drv))
+		return 1;
+
+	return software_node_match_device(dev, drv);
 }
 
 /**

-- 
2.48.1

