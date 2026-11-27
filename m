From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 20:47:03 +0000
Subject: [PATCH 6.6.y 3/3] usb: typec: qcom-pmic-typec: drain
 cc_debounce_dwork if port_start() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-typec-66b-v1-3-6fe3a0983e5e@certik.com>
In-Reply-To: <2026090807-unbalance-starlet-1c55@gregkh>
References: <2026090807-unbalance-starlet-1c55@gregkh>
To: stable@vger.kernel.org
Cc: Fan Wu <fanwu01@zju.edu.cn>, Johan Hovold <johan+linaro@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812420; l=2076;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=nBrPMxZDVb3jytbfrX3GVoE3b8fZwhurQBLseC2gUPM=;
 b=tRYhHn/o7+N91YSWuBhi2UyWTbZP9B7LfUTlRwvh3yA0bUcnfoM+Nh7UlM7nmLC/NY5EivA4r
 bEWhIfmsx3pDOT/hk4QPDVT7aCsmRPqOiVARZhhRL7D+iDMOUi9sORH
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fan Wu <fanwu01@zju.edu.cn>

commit c9273c83885835dbd1e8835d5665dfb8503d65e0 upstream.

cc_debounce_dwork can be queued before port_start() fails:
tcpm_register_port() runs first, and its state machine may invoke
set_cc() or start_toggling() from the TCPM worker.  The error path then
calls tcpm_unregister_port(), whose worker flush may queue the delayed
work before devres frees pmic_typec_port.

Disable and drain the delayed work directly at port_start()'s error
exit.  Do not use port_stop() for this path: its IRQs use IRQF_NO_AUTOEN
and are enabled only after a successful port_start().

This issue was found by an in-house static analysis tool.

Fixes: a4422ff22142 ("usb: typec: qcom: Add Qualcomm PMIC Type-C driver")
Cc: stable <stable@kernel.org>  # v6.10+
Suggested-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Assisted-by: Codex:gpt-5.6
Signed-off-by: Fan Wu <fanwu01@zju.edu.cn>
Acked-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Link: https://patch.msgid.link/20260820135307.153773-3-fanwu01@zju.edu.cn
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 6.6.y: call the port's debounce shutdown helper ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This reuses the helper from patch 2 at port_start()'s error exit.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
index f0e5e8ab06c0..8e6507ce895f 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
@@ -502,6 +502,9 @@ int qcom_pmic_typec_port_start(struct pmic_typec_port *pmic_typec_port,
 		enable_irq(pmic_typec_port->irq_data[i].irq);
 
 done:
+	if (ret)
+		qcom_pmic_typec_port_disable_debounce(pmic_typec_port);
+
 	return ret;
 }
 

-- 
2.43.0

