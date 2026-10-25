From: David Heidelberg <david@ixit.cz>
Date: Sun, 25 Oct 2026 22:54:01 +0100
Subject: [PATCH] usb: typec: tcpm: qcom: Release the connector fwnode
 reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-typec-of-fix-v1-1-06bfc16a7846@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrE1SbdC4ilhQg7FopUWIuLti+
 b3k/RcE8kwBquQCTzsHdjYiSxMwU2tHQu6jQQpZZELmuJ4LGXQDDnygLlWnWqNzLRTEy+Ipzl+
 ubn6HrZvJrG8D7vsBbJNlm3AAAAA=
X-Change-ID: 20261025-typec-of-fix-873b3ac85803
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Selby Mashiki <mashikiselby@gmail.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2217; i=david@ixit.cz;
 h=from:subject:message-id; bh=wXV9haqapMKGQNSewUN4c3h43256Fd/Lnk+wuYRTZWM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq3np/VtuNlfdNDQsmOnb1DMkwGZSlfij8G1UNP
 ZraDEArBESJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCat56fwAKCRBgAj/E00kg
 cv4xEAC7j7ZSblq50tssC6MUVCJEF1l2TMGXXMZ45V+mqK0KjPmOPQA9n4IwLRS7ozvSt4vPiHm
 38nwy+jX4nNQ9H3P3G/BRimv77x6gAZYm8OCUNA8EAcWBNLgLGSH+sI21ADgkSZVs7p4gwobujX
 9aQ/IMv0OwFlX+y1WTGmeDWKqZ83CcH+d698YBzrxK2nZmzHoY688BZtxb4kxfhVmt9LhS7+DCJ
 Scl3AAVpgvopiSzyMhGmczr9vepjUvDYUz9rHZGZ12VfEc8LMoOr5/dSU/q73uvczXB2G7hqv2G
 4+eycz1FnXAoN3SaMdwj4kBr390Socw4z/esA4LJJEBeDoY5UL2C1UuUoPLrTANUn0mdS37wVb5
 jfh7vjK6kGtf42Xpaa7ONty9fKasg38OLMUW9nguWxV+69SyNGKKlCmNJRJufteySqwNmBn70cA
 eRhd430VxRsyQky5DGlyGLb1dszaXPST08chtDKFHSaJBl/7NceomcUTu48TS1pB695kKjtWi53
 Kpa5KAmZsB0yQ7HYChtHePhFjIMxpy87hB+r6H7AxrDj1V4u+wiWJ6K23u+4bDEM2dE0YQlW8Nh
 NbU9//nD1nTNqGz78w+Zvx0QnuqT6Nkf232BmMe6718ucwygX8Qf7/GJdfDHhaWaGwcBI5wqAOS
 683ql/eLubxDDsQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

device_get_named_child_node() returns the connector node with its
reference count incremented, but the port probe never drops it. The node
is only needed for the VBUS regulator lookup, so release it right after.

Fixes: 506927b6bf29 ("usb: typec: tcpm: qcom: prefer VBUS supply from the connector node")
Acked-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Separated from (for stable):

https://lore.kernel.org/all/20260926-typec-v1-0-31adc19f32c6@ixit.cz/
---
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
index d3523435f3e01..6029d51db4393 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
@@ -5,16 +5,17 @@
 
 #include <linux/delay.h>
 #include <linux/err.h>
 #include <linux/interrupt.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/platform_device.h>
+#include <linux/property.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 #include <linux/slab.h>
 #include <linux/string_choices.h>
 #include <linux/usb/tcpm.h>
 #include <linux/usb/typec_mux.h>
 #include <linux/workqueue.h>
 
@@ -728,16 +729,17 @@ int qcom_pmic_typec_port_probe(struct platform_device *pdev,
 
 	connector = device_get_named_child_node(dev, "connector");
 	if (!connector)
 		return -EINVAL;
 
 	pmic_typec_port->vdd_vbus = devm_of_regulator_get_optional(dev,
 								   to_of_node(connector),
 								   "vbus");
+	fwnode_handle_put(connector);
 	if (pmic_typec_port->vdd_vbus == ERR_PTR(-ENODEV))
 		pmic_typec_port->vdd_vbus = devm_regulator_get(dev, "vdd-vbus");
 	if (IS_ERR(pmic_typec_port->vdd_vbus))
 		return PTR_ERR(pmic_typec_port->vdd_vbus);
 
 	pmic_typec_port->dev = dev;
 	pmic_typec_port->base = base;
 	pmic_typec_port->regmap = regmap;

---
base-commit: 20a33c6b6cbe7e4805dfb6cd68816937443aa148
change-id: 20261025-typec-of-fix-873b3ac85803

Best regards,
--  
David Heidelberg <david@ixit.cz>

