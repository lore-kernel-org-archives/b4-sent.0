From: Mahesh Rao <mahesh.rao@altera.com>
Date: Mon, 27 Oct 2025 22:54:42 +0800
Subject: [PATCH v7 3/4] firmware: stratix10-svc: Add support for RSU
 commands in asynchronous framework
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-sip_svc_upstream-v7-3-6e9ab26d7480@altera.com>
References: <20251027-sip_svc_upstream-v7-0-6e9ab26d7480@altera.com>
In-Reply-To: <20251027-sip_svc_upstream-v7-0-6e9ab26d7480@altera.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>, 
 Richard Gong <richard.gong@intel.com>, Alan Tull <atull@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761576953; l=8313;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=iA9XcG2q+a/TSsO5lZazATVYnuLeYIBDmU/cEvshLSY=;
 b=4+WeLDIvrs/GggwINQS6AJxf7I2FXLRxzwFOfG388QWCxhEq/wIdjKVrgT15ykPFEqhxtpTMC
 mLUYg9G+HMgBDOnCSlKVmdcGonio+er1kILb2h8OEAvt6CHa6rOKhn3
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Integrate Remote System Update(RSU) service commands into the
asynchronous framework for communicating with SDM. This allows the RSU
commands to be processed asynchronously, improving the responsiveness
of the Stratix10 service channel.

The asynchronous framework now supports the following RSU commands:
* COMMAND_RSU_GET_SPT_TABLE
* COMMAND_RSU_STATUS
* COMMAND_RSU_NOTIFY

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
Signed-off-by: Dinh Nguyen <dinguyen@kernel.org>
---
 drivers/firmware/stratix10-svc.c                   | 72 ++++++++++++++++++++++
 include/linux/firmware/intel/stratix10-smc.h       | 52 ++++++++++++++++
 .../linux/firmware/intel/stratix10-svc-client.h    |  4 ++
 3 files changed, 128 insertions(+)

diff --git a/drivers/firmware/stratix10-svc.c b/drivers/firmware/stratix10-svc.c
index 14bfa36a58ed38a19de9f54142827a29ced0851d..3acfa067c5dda5a1a2d8848a18e0627860395902 100644
--- a/drivers/firmware/stratix10-svc.c
+++ b/drivers/firmware/stratix10-svc.c
@@ -90,6 +90,12 @@
 #define STRATIX10_SIP_SMC_SET_TRANSACTIONID_X1(transaction_id) \
 	(FIELD_PREP(STRATIX10_TRANS_ID_FIELD, transaction_id))
 
+/* 10-bit mask for extracting the SDM status code */
+#define STRATIX10_SDM_STATUS_MASK GENMASK(9, 0)
+/* Macro to get the SDM mailbox error status */
+#define STRATIX10_GET_SDM_STATUS_CODE(status) \
+	(FIELD_GET(STRATIX10_SDM_STATUS_MASK, status))
+
 typedef void (svc_invoke_fn)(unsigned long, unsigned long, unsigned long,
 			     unsigned long, unsigned long, unsigned long,
 			     unsigned long, unsigned long,
@@ -1273,6 +1279,16 @@ int stratix10_svc_async_send(struct stratix10_svc_chan *chan, void *msg,
 		STRATIX10_SIP_SMC_SET_TRANSACTIONID_X1(handle->transaction_id);
 
 	switch (p_msg->command) {
+	case COMMAND_RSU_GET_SPT_TABLE:
+		args.a0 = INTEL_SIP_SMC_ASYNC_RSU_GET_SPT;
+		break;
+	case COMMAND_RSU_STATUS:
+		args.a0 = INTEL_SIP_SMC_ASYNC_RSU_GET_ERROR_STATUS;
+		break;
+	case COMMAND_RSU_NOTIFY:
+		args.a0 = INTEL_SIP_SMC_ASYNC_RSU_NOTIFY;
+		args.a2 = p_msg->arg[0];
+		break;
 	default:
 		dev_err(ctrl->dev, "Invalid command ,%d\n", p_msg->command);
 		ret = -EINVAL;
@@ -1326,6 +1342,56 @@ int stratix10_svc_async_send(struct stratix10_svc_chan *chan, void *msg,
 	return ret;
 }
 EXPORT_SYMBOL_GPL(stratix10_svc_async_send);
+
+/**
+ * stratix10_svc_async_prepare_response - Prepare the response data for
+ * an asynchronous transaction.
+ * @chan: Pointer to the service channel structure.
+ * @handle: Pointer to the asynchronous handler structure.
+ * @data: Pointer to the callback data structure.
+ *
+ * This function prepares the response data for an asynchronous transaction. It
+ * extracts the response data from the SMC response structure and stores it in
+ * the callback data structure. The function also logs the completion of the
+ * asynchronous transaction.
+ *
+ * Return: 0 on success, -ENOENT if the command is invalid
+ */
+static int stratix10_svc_async_prepare_response(struct stratix10_svc_chan *chan,
+						struct stratix10_svc_async_handler *handle,
+						struct stratix10_svc_cb_data *data)
+{
+	struct stratix10_svc_client_msg *p_msg =
+		(struct stratix10_svc_client_msg *)handle->msg;
+	struct stratix10_svc_controller *ctrl = chan->ctrl;
+
+	data->status = STRATIX10_GET_SDM_STATUS_CODE(handle->res.a1);
+
+	switch (p_msg->command) {
+	case COMMAND_RSU_NOTIFY:
+		break;
+	case COMMAND_RSU_GET_SPT_TABLE:
+		data->kaddr1 = (void *)&handle->res.a2;
+		data->kaddr2 = (void *)&handle->res.a3;
+		break;
+	case COMMAND_RSU_STATUS:
+		/* COMMAND_RSU_STATUS has more elements than the cb_data
+		 * can acomodate, so passing the response structure to the
+		 * response function to be handled before done command is
+		 * executed by the client.
+		 */
+		data->kaddr1 = (void *)&handle->res;
+		break;
+
+	default:
+		dev_alert(ctrl->dev, "Invalid command\n ,%d", p_msg->command);
+		return -ENOENT;
+	}
+	dev_dbg(ctrl->dev, "Async message completed transaction_id 0x%02x\n",
+		handle->transaction_id);
+	return 0;
+}
+
 /**
  * stratix10_svc_async_poll - Polls the status of an asynchronous
  * transaction.
@@ -1355,6 +1421,7 @@ int stratix10_svc_async_poll(struct stratix10_svc_chan *chan,
 	struct stratix10_svc_controller *ctrl;
 	struct stratix10_async_ctrl *actrl;
 	struct stratix10_async_chan *achan;
+	int ret;
 
 	if (!chan || !tx_handle || !data)
 		return -EINVAL;
@@ -1386,6 +1453,11 @@ int stratix10_svc_async_poll(struct stratix10_svc_chan *chan,
 	memset(data, 0, sizeof(*data));
 
 	if (handle->res.a0 == INTEL_SIP_SMC_STATUS_OK) {
+		ret = stratix10_svc_async_prepare_response(chan, handle, data);
+		if (ret) {
+			dev_err(ctrl->dev, "Error in preparation of response,%d\n", ret);
+			WARN_ON_ONCE(1);
+		}
 		return 0;
 	} else if (handle->res.a0 == INTEL_SIP_SMC_STATUS_BUSY) {
 		dev_dbg(ctrl->dev, "async message is still in progress\n");
diff --git a/include/linux/firmware/intel/stratix10-smc.h b/include/linux/firmware/intel/stratix10-smc.h
index 3995d5d70cce029466da8943ebea392ee2f19777..935dba3633b5ba2d559eeb052903456b69babd76 100644
--- a/include/linux/firmware/intel/stratix10-smc.h
+++ b/include/linux/firmware/intel/stratix10-smc.h
@@ -679,4 +679,56 @@ INTEL_SIP_SMC_FAST_CALL_VAL(INTEL_SIP_SMC_FUNCID_FPGA_CONFIG_COMPLETED_WRITE)
 #define INTEL_SIP_SMC_ASYNC_FUNC_ID_POLL (0xC8)
 #define INTEL_SIP_SMC_ASYNC_POLL \
 	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNC_ID_POLL)
+
+/**
+ * Request INTEL_SIP_SMC_ASYNC_RSU_GET_SPT
+ * Async call to get RSU SPT from SDM.
+ * Call register usage:
+ * a0 INTEL_SIP_SMC_ASYNC_RSU_GET_SPT
+ * a1 transaction job id
+ * a2-a17 not used
+ *
+ * Return status:
+ * a0 INTEL_SIP_SMC_STATUS_OK ,INTEL_SIP_SMC_STATUS_REJECTED
+ * or INTEL_SIP_SMC_STATUS_BUSY
+ * a1-a17 not used
+ */
+#define INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_GET_SPT (0xEA)
+#define INTEL_SIP_SMC_ASYNC_RSU_GET_SPT \
+	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_GET_SPT)
+
+/**
+ * Request INTEL_SIP_SMC_ASYNC_RSU_GET_ERROR_STATUS
+ * Async call to get RSU error status from SDM.
+ * Call register usage:
+ * a0 INTEL_SIP_SMC_ASYNC_RSU_GET_ERROR_STATUS
+ * a1 transaction job id
+ * a2-a17 not used
+ *
+ * Return status:
+ * a0 INTEL_SIP_SMC_STATUS_OK ,INTEL_SIP_SMC_STATUS_REJECTED
+ * or INTEL_SIP_SMC_STATUS_BUSY
+ * a1-a17 not used
+ */
+#define INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_GET_ERROR_STATUS (0xEB)
+#define INTEL_SIP_SMC_ASYNC_RSU_GET_ERROR_STATUS \
+	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_GET_ERROR_STATUS)
+
+/**
+ * Request INTEL_SIP_SMC_ASYNC_RSU_NOTIFY
+ * Async call to send NOTIFY value to SDM.
+ * Call register usage:
+ * a0 INTEL_SIP_SMC_ASYNC_RSU_NOTIFY
+ * a1 transaction job id
+ * a2 notify value
+ * a3-a17 not used
+ *
+ * Return status:
+ * a0 INTEL_SIP_SMC_STATUS_OK ,INTEL_SIP_SMC_STATUS_REJECTED
+ * or INTEL_SIP_SMC_STATUS_BUSY
+ * a1-a17 not used
+ */
+#define INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_NOTIFY (0xEC)
+#define INTEL_SIP_SMC_ASYNC_RSU_NOTIFY \
+	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNC_ID_RSU_NOTIFY)
 #endif
diff --git a/include/linux/firmware/intel/stratix10-svc-client.h b/include/linux/firmware/intel/stratix10-svc-client.h
index 532dd4bd76dd8e2144a2a8e3158168ed776b3fa8..1bcc56d14080d8950a5af60bb31052d3bffa8904 100644
--- a/include/linux/firmware/intel/stratix10-svc-client.h
+++ b/include/linux/firmware/intel/stratix10-svc-client.h
@@ -128,6 +128,9 @@ struct stratix10_svc_chan;
  * @COMMAND_RSU_DCMF_STATUS: query firmware for the DCMF status
  * return status is SVC_STATUS_OK or SVC_STATUS_ERROR
  *
+ * @COMMAND_RSU_GET_SPT_TABLE: query firmware for SPT table
+ * return status is SVC_STATUS_OK or SVC_STATUS_ERROR
+ *
  * @COMMAND_FCS_REQUEST_SERVICE: request validation of image from firmware,
  * return status is SVC_STATUS_OK, SVC_STATUS_INVALID_PARAM
  *
@@ -162,6 +165,7 @@ enum stratix10_svc_command_code {
 	COMMAND_RSU_DCMF_VERSION,
 	COMMAND_RSU_DCMF_STATUS,
 	COMMAND_FIRMWARE_VERSION,
+	COMMAND_RSU_GET_SPT_TABLE,
 	/* for FCS */
 	COMMAND_FCS_REQUEST_SERVICE = 20,
 	COMMAND_FCS_SEND_CERTIFICATE,

-- 
2.43.7

