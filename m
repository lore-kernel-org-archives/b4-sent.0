From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 12 Nov 2025 20:15:18 +0530
Subject: [PATCH 6/9] serdev: Skip registering serdev devices from DT is
 external connector is used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251112-pci-m2-e-v1-6-97413d6bf824@oss.qualcomm.com>
References: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
In-Reply-To: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
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
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1489;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=9l0vV6HXXlRQhGb6LPV2j9zLb+eL0Fpf0v/SXfsrOaY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpFJ2HYIFtN5v5bNyD8H02BJPR+1uACNYqLJQdu
 pU9f/L5A+2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaRSdhwAKCRBVnxHm/pHO
 9RwgB/47EH+jLOBR8bp8aP5M5wGWY4SysKJtZO4fkj97iCzy/SsK9prWiuuaBDNz/F5VfGuxdtE
 Kin9UH7qcWGK/P3pKH7xvC9p6Mm8NlJjS6oni2Z3zPLX6VllhharFcxCAoHHjXEvdbaw4EPGomr
 S7Bq9ooyzXH3s3+GqPs7RdiqKCh3HIEhlt1xa550XiX7bCQDgjrsNVHqLy4jWaCrdWhfQ74eZlV
 pJaVlLxPif2eLcTh562fAWZ2dA/Oknb7ywQKC0VSBcQyZqRuMwRMHr0eZOkcPwWg8i7QsB5jXun
 UbBPcW1fXEPr3OZDqWb5SWwrc8t+apPpHsnLxxflovrsrkqs
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If an external connector like M.2 is connected to the serdev controller
in DT, then the serdev devices will be created dynamically by the connector
driver. So skip registering devices from DT node as there will be no
statically defined devices.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/tty/serdev/core.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/tty/serdev/core.c b/drivers/tty/serdev/core.c
index 8c2a40a537d93f4b9353a2f128cdf51b521929b1..1378587d386356ca4415fa455b2ee722b5e44d3e 100644
--- a/drivers/tty/serdev/core.c
+++ b/drivers/tty/serdev/core.c
@@ -12,6 +12,7 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/of.h>
+#include <linux/of_graph.h>
 #include <linux/of_device.h>
 #include <linux/pm_domain.h>
 #include <linux/pm_runtime.h>
@@ -560,6 +561,15 @@ static int of_serdev_register_devices(struct serdev_controller *ctrl)
 	int err;
 	bool found = false;
 
+	/*
+	 * When the serdev controller is connected to an external connector like
+	 * M.2 in DT, then the serdev devices will be created dynamically by the
+	 * connector driver. So skip looking for devices in DT node as there will
+	 * be no statically defined devices.
+	 */
+	if (of_graph_is_present(ctrl->dev.of_node))
+		return 0;
+
 	for_each_available_child_of_node(ctrl->dev.of_node, node) {
 		if (!of_property_present(node, "compatible"))
 			continue;

-- 
2.48.1

