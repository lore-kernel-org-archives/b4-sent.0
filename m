From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:51:35 -0400
Subject: [PATCH] firmware: imx: scu: publish the SCU IPC handles with
 release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-imx-scu-v1-1-2e2eae4246dd@vt.edu>
X-B4-Tracking: v=1; b=H4sIABbRsWoC/yXMwQ6CMBAE0F8he3YNLUqDv0I8tMsqa0I1XSEkh
 H+3xeObzMwGyklY4VZtkHgRlXfMMKcKaPTxyShDNtjatnVnDU4BZVpRaUYeXNe0xnpnr5AHn8Q
 PWY+z/v63zuHF9C0PpRG8MobkI40lOri4c4OJLrDvPx8cMMGOAAAA
X-Change-ID: 20260921-mb-imx-scu-ed793612a725
To: Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038296; l=4658;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=0RORvg2PXLot2bwSJtUZCYO8QEXAWE0X1XX02gJE4Rc=;
 b=5B0OQ62kUCr6hzg4bQqVlmfOATttk1UYAXWkEske9/yWnUbQhqgjPXSDLgw9da8Q6JzILEn/v
 Z5LqaULjNDHD5N38U9jhSWj37uA7QYbPqurec/7H5tiAxmtfOm7QaUV
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

imx_scu_probe() fills struct imx_sc_ipc with the mailbox channels, the
fast_ipc flag, the mutex and the completion, then stores its address to
imx_sc_ipc_handle with a plain store. The clk, pinctrl, nvmem, rtc,
thermal, gpio, reset, pmdomain, remoteproc, fec, flexcan and SOF drivers
fetch it through imx_scu_get_handle() from their own probe and pass it
to imx_scu_call_rpc(). Most are not children of the SCU node, so they
probe from the deferred probe worker or a module load on another CPU
while imx_scu_probe() is still running.

The publication store is not ordered after the stores that built the
object, so a consumer that passes the NULL check can dereference
uninitialised channel pointers. The address dependency on the consumer
side orders its own loads but says nothing about the producer.

imx_sc_irq_ipc_handle has the same shape:
imx_scu_enable_general_irq_channel() publishes it with a plain store and
imx_scu_irq_group_enable() uses it as an -EPROBE_DEFER gate for the rtc,
key and watchdog drivers.

Publish both handles with smp_store_release() and read them with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/firmware/imx/imx-scu-irq.c | 18 +++++++++++++++---
 drivers/firmware/imx/imx-scu.c     | 14 +++++++++++---
 2 files changed, 26 insertions(+), 6 deletions(-)

diff --git a/drivers/firmware/imx/imx-scu-irq.c b/drivers/firmware/imx/imx-scu-irq.c
index a68d38f89..4f24e3c08 100644
--- a/drivers/firmware/imx/imx-scu-irq.c
+++ b/drivers/firmware/imx/imx-scu-irq.c
@@ -143,9 +143,12 @@ int imx_scu_irq_group_enable(u8 group, u32 mask, u8 enable)
 {
 	struct imx_sc_msg_irq_enable msg;
 	struct imx_sc_rpc_msg *hdr = &msg.hdr;
+	struct imx_sc_ipc *ipc;
 	int ret;
 
-	if (!imx_sc_irq_ipc_handle)
+	/* Pairs with the smp_store_release() in imx_scu_enable_general_irq_channel(). */
+	ipc = smp_load_acquire(&imx_sc_irq_ipc_handle);
+	if (!ipc)
 		return -EPROBE_DEFER;
 
 	hdr->ver = IMX_SC_RPC_VERSION;
@@ -158,7 +161,7 @@ int imx_scu_irq_group_enable(u8 group, u32 mask, u8 enable)
 	msg.mask = mask;
 	msg.enable = enable;
 
-	ret = imx_scu_call_rpc(imx_sc_irq_ipc_handle, &msg, true);
+	ret = imx_scu_call_rpc(ipc, &msg, true);
 	if (ret)
 		pr_err("enable irq failed, group %d, mask %d, ret %d\n",
 			group, mask, ret);
@@ -201,6 +204,7 @@ int imx_scu_enable_general_irq_channel(struct device *dev)
 	struct of_phandle_args spec;
 	struct mbox_client *cl;
 	struct mbox_chan *ch;
+	struct imx_sc_ipc *ipc;
 	int ret = 0, i = 0;
 
 	if (!of_parse_phandle_with_args(dev->of_node, "mboxes",
@@ -215,10 +219,18 @@ int imx_scu_enable_general_irq_channel(struct device *dev)
 
 	mu_resource_id = IMX_SC_R_MU_0A + i;
 
-	ret = imx_scu_get_handle(&imx_sc_irq_ipc_handle);
+	ret = imx_scu_get_handle(&ipc);
 	if (ret)
 		return ret;
 
+	/*
+	 * imx_scu_irq_group_enable() tests imx_sc_irq_ipc_handle from other
+	 * drivers' probe paths and then passes it to imx_scu_call_rpc().
+	 * Publish it with release semantics so that the SCU state it points
+	 * to is visible to them.
+	 */
+	smp_store_release(&imx_sc_irq_ipc_handle, ipc);
+
 	cl = devm_kzalloc(dev, sizeof(*cl), GFP_KERNEL);
 	if (!cl)
 		return -ENOMEM;
diff --git a/drivers/firmware/imx/imx-scu.c b/drivers/firmware/imx/imx-scu.c
index 203aac421..e1b9d51a5 100644
--- a/drivers/firmware/imx/imx-scu.c
+++ b/drivers/firmware/imx/imx-scu.c
@@ -105,10 +105,13 @@ static inline int imx_sc_to_linux_errno(int errno)
  */
 int imx_scu_get_handle(struct imx_sc_ipc **ipc)
 {
-	if (!imx_sc_ipc_handle)
+	/* Pairs with the smp_store_release() in imx_scu_probe(). */
+	struct imx_sc_ipc *sc_ipc = smp_load_acquire(&imx_sc_ipc_handle);
+
+	if (!sc_ipc)
 		return -EPROBE_DEFER;
 
-	*ipc = imx_sc_ipc_handle;
+	*ipc = sc_ipc;
 	return 0;
 }
 EXPORT_SYMBOL(imx_scu_get_handle);
@@ -345,7 +348,12 @@ static int imx_scu_probe(struct platform_device *pdev)
 		return ret;
 	init_completion(&sc_ipc->done);
 
-	imx_sc_ipc_handle = sc_ipc;
+	/*
+	 * Consumers fetch the handle from their own probe, possibly on
+	 * another CPU, and then use the channels, the mutex and the completion
+	 * initialised above. Publish it with release semantics.
+	 */
+	smp_store_release(&imx_sc_ipc_handle, sc_ipc);
 	ret = devm_add_action_or_reset(dev, imx_scu_clear_handle, sc_ipc);
 	if (ret)
 		return ret;

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-imx-scu-ed793612a725

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

