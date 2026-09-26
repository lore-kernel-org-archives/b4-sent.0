From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:20 +0200
Subject: [PATCH RFC 01/12] usb: typec: tcpm: qcom: Release the connector
 fwnode reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-1-31adc19f32c6@ixit.cz>
References: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
In-Reply-To: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1915; i=david@ixit.cz;
 h=from:subject:message-id; bh=22jx8Je1oP+cSCrbfrUS4MrSfcA6caRWGdeZuml3fJs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt709qm2CM8rlvlYjeHgjttYvncP5LGHE4UVfp
 0le9TwMS8GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PQAKCRBgAj/E00kg
 covmD/91dII+0d3mG6Rh9eecL3hmADWuOqoOY6jnNuvevQ85iyRM7ef0uZHQ7GPOR/p4GU4fK24
 f1J5yw86lLpCzy5voipaf5579rByui4r/RC5fS6x4NfyTYV5uLhnS4HzgZzpkZBVM6or0nDHP+i
 n8WmIjWl8ErpyX3GjRm11gG0/SHjdtHpotIt29rUrsN+2E9CD8G6x4iulBEhRZqklphX4f7fCba
 g6t7jjZSTNL2hLwolVl7duIa7HWv29uTWkkdkKh02ZbNPdhL3k52mdTt7VZHIZceI4ZuO+/v+wq
 H2Uv0QJkMG4Ox5brnG2szJ157Aq0SLTX5JQnR50AMEc6zd/HaOyXCB1bc/isK6epMYVJpEHIhww
 FCyBX/WMyitfHGI3vVM+8HZJKMlA6TJ70uSodFV8JKpuZVt7WiF2I8ASwgtKtdRmYeTNJb5zyj2
 oDhUepZRWO74W0g4eSlPepn0FbKBESvKAGPUzgjE70/ue3xBlYSO7IweWdRpLZWMhDDt5VZFk62
 CKchhsY0w8Cd7f2EPmOqHyiY3nWN/p93aX7tfIRCdY/p2wmJv0LtwLdxciVu0ywCVkUv+ZREErD
 Y7IkPl03xLeZ9SyzfZMkrgB+EYWXJ3EYsh3E28Oa5hUUPg3zeRI/mkIbwQ1JtsR+JkP4/0TEUOc
 M518ylOwa1Jl+MA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

device_get_named_child_node() returns the connector node with its
reference count incremented, but the port probe never drops it. The node
is only needed for the VBUS regulator lookup, so release it right after.

Assisted-by: LLM
Fixes: 506927b6bf29 ("usb: typec: tcpm: qcom: prefer VBUS supply from the connector node")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
index bf985efe1cd6b..f8308d66b9d67 100644
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
 
@@ -723,16 +724,17 @@ int qcom_pmic_typec_port_probe(struct platform_device *pdev,
 
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

-- 
2.55.0

