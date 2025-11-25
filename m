From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 25 Nov 2025 20:15:05 +0530
Subject: [PATCH v2 01/10] serdev: Convert to_serdev_*() helpers to macros
 and use container_of_const()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251125-pci-m2-e-v2-1-32826de07cc5@oss.qualcomm.com>
References: <20251125-pci-m2-e-v2-0-32826de07cc5@oss.qualcomm.com>
In-Reply-To: <20251125-pci-m2-e-v2-0-32826de07cc5@oss.qualcomm.com>
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
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2123;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=gp2plOukmLsK8Wz0sYhXr+7v4Z6uCCCmxZxVG517B/M=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpJcDyeFLCzWDU7DbBpggspqjnYeo3HN+5r50pB
 iGA2Xp8WLeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaSXA8gAKCRBVnxHm/pHO
 9RlvB/9CbifjQ3jZwZtMwC+hnrlvILHtu+kiJsXQ3WfhvHxz5q0Fcm0nkfdBBgSUwx/bFhMqidX
 /GyfwPv1MHx3GEX3AH41y1whdyQO02CzHOwLE+yu7n7gGnz5009PCzMinAD06jW9aZrHWzlx4Qa
 Voe1JgB5+FRVKs8ppyCu9GEiOdQ2mrnnd2PoWslfpd5KX7DbJvqkAFG2CdPXmWe2f/yJKQZ10S4
 KTR3UoQ1qHi3PQQHP35gajlhY+DXW6Ilc4F3HXG5ohmDGa3i8lJ0qsNb//RwdfdGbkGCgYDJg0Z
 IDLx/gjMjBJuZlTxmgbt6Ot3q3BBG4UnBbmWvKq5nbkoP8/Z
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If these helpers receive the 'const struct device' pointer, then the const
qualifier will get dropped, leading to below warning:

warning: passing argument 1 of ‘to_serdev_device_driver’ discards 'const'
qualifier from pointer target type [-Wdiscarded-qualifiers]

This is not an issue as of now, but with the future commits adding serdev
device based driver matching, this warning will get triggered. Hence,
convert these helpers to macros so that the qualifier get preserved and
also use container_of_const() as container_of() is deprecated.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 include/linux/serdev.h | 15 +++------------
 1 file changed, 3 insertions(+), 12 deletions(-)

diff --git a/include/linux/serdev.h b/include/linux/serdev.h
index 34562eb99931..ecde0ad3e248 100644
--- a/include/linux/serdev.h
+++ b/include/linux/serdev.h
@@ -49,10 +49,7 @@ struct serdev_device {
 	struct mutex write_lock;
 };
 
-static inline struct serdev_device *to_serdev_device(struct device *d)
-{
-	return container_of(d, struct serdev_device, dev);
-}
+#define to_serdev_device(d) container_of_const(d, struct serdev_device, dev)
 
 /**
  * struct serdev_device_driver - serdev slave device driver
@@ -67,10 +64,7 @@ struct serdev_device_driver {
 	void	(*remove)(struct serdev_device *);
 };
 
-static inline struct serdev_device_driver *to_serdev_device_driver(struct device_driver *d)
-{
-	return container_of(d, struct serdev_device_driver, driver);
-}
+#define to_serdev_device_driver(d) container_of_const(d, struct serdev_device_driver, driver)
 
 enum serdev_parity {
 	SERDEV_PARITY_NONE,
@@ -111,10 +105,7 @@ struct serdev_controller {
 	const struct serdev_controller_ops *ops;
 };
 
-static inline struct serdev_controller *to_serdev_controller(struct device *d)
-{
-	return container_of(d, struct serdev_controller, dev);
-}
+#define to_serdev_controller(d) container_of_const(d, struct serdev_controller, dev)
 
 static inline void *serdev_device_get_drvdata(const struct serdev_device *serdev)
 {

-- 
2.48.1

