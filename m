From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 20:47:02 +0000
Subject: [PATCH 6.6.y 2/3] usb: typec: qcom-pmic-typec: disable
 cc_debounce_dwork on stop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-typec-66b-v1-2-6fe3a0983e5e@certik.com>
In-Reply-To: <2026090807-unbalance-starlet-1c55@gregkh>
References: <2026090807-unbalance-starlet-1c55@gregkh>
To: stable@vger.kernel.org
Cc: Fan Wu <fanwu01@zju.edu.cn>, Johan Hovold <johan+linaro@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812420; l=3628;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=cbWbV6LY06byAH3dFx0kSfTR/qyusZYU9PRseIS90vU=;
 b=icHqSZ8f+1VZT8oOu08CrMysyAulSR+Fw1+zxIUTQTQDuDzC41igT4gVhMAyNM4zi1YHu6vZE
 6gUi5O3rnOTCExsiyOma9UwQA5KtFS8AUi3CIZugK2/VMPCjk+nCiof
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fan Wu <fanwu01@zju.edu.cn>

commit 263f7d61a4201cde16849b2d016251806e7418be upstream.

cc_debounce_dwork is queued from the set_cc() and start_toggling()
callbacks, which run from TCPM's kthread worker.  port_stop() returns
before tcpm_unregister_port() destroys that worker.  Flushing the worker
during unregister may therefore run a callback which queues the delayed
work after port_stop() has returned.

The delayed work can then run after devres has freed pmic_typec_port.

Use disable_delayed_work_sync() in port_stop() to cancel a pending
instance and prevent the TCPM callbacks from queueing another one.

This issue was found by an in-house static analysis tool.

Fixes: a4422ff22142 ("usb: typec: qcom: Add Qualcomm PMIC Type-C driver")
Cc: stable <stable@kernel.org>  # v6.10+
Assisted-by: Codex:gpt-5.6
Signed-off-by: Fan Wu <fanwu01@zju.edu.cn>
Acked-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Link: https://patch.msgid.link/20260820135307.153773-2-fanwu01@zju.edu.cn
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 6.6.y: gate enqueues under the port lock before cancel ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.6 has no disable_delayed_work_sync(). Port stop instead sets a flag
under the port lock, which both enqueue sites already hold, and then
cancels pending work synchronously. The flag is never cleared because
port stop only runs from remove and the probe error path.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
index d6607491fcef..f0e5e8ab06c0 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c
@@ -36,6 +36,7 @@ struct pmic_typec_port {
 
 	int				cc;
 	bool				debouncing_cc;
+	bool				cc_debounce_disabled;
 	struct delayed_work		cc_debounce_dwork;
 
 	spinlock_t			lock;	/* Register atomicity */
@@ -269,6 +270,9 @@ int qcom_pmic_typec_port_get_cc(struct pmic_typec_port *pmic_typec_port,
 
 static void qcom_pmic_set_cc_debounce(struct pmic_typec_port *pmic_typec_port)
 {
+	if (pmic_typec_port->cc_debounce_disabled)
+		return;
+
 	pmic_typec_port->debouncing_cc = true;
 	schedule_delayed_work(&pmic_typec_port->cc_debounce_dwork,
 			      msecs_to_jiffies(2));
@@ -440,6 +444,17 @@ int qcom_pmic_typec_port_start_toggling(struct pmic_typec_port *pmic_typec_port,
 	(TYPEC_STATE_MACHINE_CHANGE_INT_EN | TYPEC_VBUS_ERROR_INT_EN | \
 	 TYPEC_DEBOUNCE_DONE_INT_EN)
 
+static void qcom_pmic_typec_port_disable_debounce(struct pmic_typec_port *pmic_typec_port)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&pmic_typec_port->lock, flags);
+	pmic_typec_port->cc_debounce_disabled = true;
+	spin_unlock_irqrestore(&pmic_typec_port->lock, flags);
+
+	cancel_delayed_work_sync(&pmic_typec_port->cc_debounce_dwork);
+}
+
 int qcom_pmic_typec_port_start(struct pmic_typec_port *pmic_typec_port,
 			       struct tcpm_port *tcpm_port)
 {
@@ -496,6 +511,8 @@ void qcom_pmic_typec_port_stop(struct pmic_typec_port *pmic_typec_port)
 
 	for (i = 0; i < pmic_typec_port->nr_irqs; i++)
 		disable_irq(pmic_typec_port->irq_data[i].irq);
+
+	qcom_pmic_typec_port_disable_debounce(pmic_typec_port);
 }
 
 struct pmic_typec_port *qcom_pmic_typec_port_alloc(struct device *dev)

-- 
2.43.0

