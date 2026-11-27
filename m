From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 20:47:01 +0000
Subject: [PATCH 6.6.y 1/3] usb: typec: qcom-pmic: fix use-after-free on
 late probe errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-typec-66b-v1-1-6fe3a0983e5e@certik.com>
In-Reply-To: <2026090807-unbalance-starlet-1c55@gregkh>
References: <2026090807-unbalance-starlet-1c55@gregkh>
To: stable@vger.kernel.org
Cc: Fan Wu <fanwu01@zju.edu.cn>, Johan Hovold <johan+linaro@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812420; l=2149;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=3+jRieiIiLtkEBFh8rjXnHAz91HQKwbqmAEfeXhAQGU=;
 b=fRUIE/RbUYn4YbVOAI8nGW7LIguH2UDaMptsjlGU52TyK+kKLzwk47eT31c85v33VTwVDHbuG
 A0TIXjqaoP8DrcE6dP8lBgKzaRB0oaeIr8HXErA66yLmTJT0dj3QpU3
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Johan Hovold <johan+linaro@kernel.org>

commit d80eee97cb4e90768a81c856ac71d721996d86b7 upstream.

Make sure to stop and deregister the port in case of late probe errors
to avoid use-after-free issues when the underlying memory is released by
devres.

Fixes: a4422ff22142 ("usb: typec: qcom: Add Qualcomm PMIC Type-C driver")
Cc: stable@vger.kernel.org	# 6.5
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Johan Hovold <johan+linaro@kernel.org>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Link: https://lore.kernel.org/r/20240418145730.4605-2-johan+linaro@kernel.org
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 6.6.y: use direct port helpers and fwnode_handle_put() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
On 6.6 the unwind calls the port helpers directly and keeps
fwnode_handle_put(); the tcpm ops layout upstream uses came later.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c
index 5f67925a19d3..a8fc86099f32 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c
@@ -258,15 +258,19 @@ static int qcom_pmic_typec_probe(struct platform_device *pdev)
 	ret = qcom_pmic_typec_port_start(tcpm->pmic_typec_port,
 					 tcpm->tcpm_port);
 	if (ret)
-		goto fwnode_remove;
+		goto port_unregister;
 
 	ret = qcom_pmic_typec_pdphy_start(tcpm->pmic_typec_pdphy,
 					  tcpm->tcpm_port);
 	if (ret)
-		goto fwnode_remove;
+		goto port_stop;
 
 	return 0;
 
+port_stop:
+	qcom_pmic_typec_port_stop(tcpm->pmic_typec_port);
+port_unregister:
+	tcpm_unregister_port(tcpm->tcpm_port);
 fwnode_remove:
 	fwnode_handle_put(tcpm->tcpc.fwnode);
 

-- 
2.43.0

