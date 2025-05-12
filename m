From: Mahesh Rao <mahesh.rao@altera.com>
Date: Mon, 12 May 2025 19:39:57 +0800
Subject: [PATCH v2 7/7] firmware: stratix10-svc: Add support for HWMON
 temperature and voltage read command.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250512-sip_svc_upstream-v2-7-fae5c45c059d@altera.com>
References: <20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com>
In-Reply-To: <20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747050016; l=5773;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=JivcqKDOJIt5kDrV3wGuv8X3Vtjgv7lk5n3TnWoduZM=;
 b=xvCa7P+zu3SXxb5VoGVvj7apxcDojRruWUKgEzgdh8aYApRyzNDxkENG3zTcShsT4DyjnpeCK
 qfg1wojZZApDLgXaEqOorsS42kjoujDCBlLzv7kivAD6JaEvej6cAs2
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for HWMON commands in stratix10
Asynchronous communication

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/firmware/stratix10-svc.c                   | 20 +++++++++++-
 include/linux/firmware/intel/stratix10-smc.h       | 38 ++++++++++++++++++++++
 .../linux/firmware/intel/stratix10-svc-client.h    | 11 +++++++
 3 files changed, 68 insertions(+), 1 deletion(-)

diff --git a/drivers/firmware/stratix10-svc.c b/drivers/firmware/stratix10-svc.c
index d60808cc077da6d88ca6cc1043f6da46df31ebad..4ee89980319dcde5198d7112d08708b543881f73 100644
--- a/drivers/firmware/stratix10-svc.c
+++ b/drivers/firmware/stratix10-svc.c
@@ -40,7 +40,7 @@
  * timeout is set to 30 seconds (30 * 1000) at Intel Stratix10 SoC.
  */
 #define SVC_NUM_DATA_IN_FIFO			32
-#define SVC_NUM_CHANNEL				3
+#define SVC_NUM_CHANNEL				4
 #define FPGA_CONFIG_DATA_CLAIM_TIMEOUT_MS	200
 #define FPGA_CONFIG_STATUS_TIMEOUT_SEC		30
 #define BYTE_TO_WORD_SIZE              4
@@ -1429,6 +1429,14 @@ int stratix10_svc_async_send(struct stratix10_svc_chan *chan, void *msg, void **
 		STRATIX10_SIP_SMC_SET_TRANSACTIONID_X1(handle->transaction_id);
 
 	switch (p_msg->command) {
+	case COMMAND_HWMON_READTEMP:
+		args.a0 = INTEL_SIP_SMC_ASYNC_HWMON_READTEMP;
+		args.a2 = p_msg->arg[0];
+		break;
+	case COMMAND_HWMON_READVOLT:
+		args.a0 = INTEL_SIP_SMC_ASYNC_HWMON_READVOLT;
+		args.a2 = p_msg->arg[0];
+		break;
 	default:
 		dev_err(ctrl->dev, "Invalid command ,%d\n", p_msg->command);
 		ret = -EINVAL;
@@ -1508,6 +1516,11 @@ static int stratix10_svc_async_prepare_response(struct stratix10_svc_chan *chan,
 	data->status = STRATIX10_GET_SDM_STATUS_CODE(handle->res.a1);
 
 	switch (p_msg->command) {
+	case COMMAND_HWMON_READTEMP:
+	case COMMAND_HWMON_READVOLT:
+		data->kaddr1 = (void *)&handle->res.a2;
+		break;
+
 	default:
 		dev_alert(ctrl->dev, "Invalid command\n ,%d", p_msg->command);
 		return -ENOENT;
@@ -2136,6 +2149,11 @@ static int stratix10_svc_drv_probe(struct platform_device *pdev)
 	chans[2].name = SVC_CLIENT_FCS;
 	spin_lock_init(&chans[2].lock);
 
+	chans[3].scl = NULL;
+	chans[3].ctrl = controller;
+	chans[3].name = SVC_CLIENT_HWMON;
+	spin_lock_init(&chans[3].lock);
+
 	list_add_tail(&controller->node, &svc_ctrl);
 	platform_set_drvdata(pdev, controller);
 
diff --git a/include/linux/firmware/intel/stratix10-smc.h b/include/linux/firmware/intel/stratix10-smc.h
index ee00f17ea9f6c7a1114fb617d4d6393f2c27e2a9..78055b0234cee990515f01a509a75e1c8142c68b 100644
--- a/include/linux/firmware/intel/stratix10-smc.h
+++ b/include/linux/firmware/intel/stratix10-smc.h
@@ -625,6 +625,44 @@ INTEL_SIP_SMC_FAST_CALL_VAL(INTEL_SIP_SMC_FUNCID_FPGA_CONFIG_COMPLETED_WRITE)
 #define INTEL_SIP_SMC_FCS_GET_PROVISION_DATA \
 	INTEL_SIP_SMC_FAST_CALL_VAL(INTEL_SIP_SMC_FUNCID_FCS_GET_PROVISION_DATA)
 
+/**
+ * Request INTEL_SIP_SMC_ASYNC_HWMON_READTEMP
+ * Async call to request temperature
+ *
+ * Call register usage:
+ * a0 INTEL_SIP_SMC_ASYNC_FUNCID_HWMON_READTEMP
+ * a1 transaction job id
+ * a2 Temperature Channel
+ * a3-a17 not used
+ *
+ * Return status
+ * a0 INTEL_SIP_SMC_STATUS_OK ,INTEL_SIP_SMC_STATUS_REJECTED
+ * or INTEL_SIP_SMC_STATUS_BUSY
+ * a1-a17 not used
+ */
+#define INTEL_SIP_SMC_ASYNC_FUNCID_HWMON_READTEMP (0xE8)
+#define INTEL_SIP_SMC_ASYNC_HWMON_READTEMP \
+	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNCID_HWMON_READTEMP)
+
+/**
+ * Request INTEL_SIP_SMC_ASYNC_HWMON_READVOLT
+ * Async call to request voltage
+ *
+ * Call register usage:
+ * a0 INTEL_SIP_SMC_ASYNC_HWMON_READVOLT
+ * a1 transaction job id
+ * a2 Voltage Channel
+ * a3-a17 not used
+ *
+ * Return status
+ * a0 INTEL_SIP_SMC_STATUS_OK ,INTEL_SIP_SMC_STATUS_REJECTED
+ * or INTEL_SIP_SMC_STATUS_BUSY
+ * a1-17 not used
+ */
+#define INTEL_SIP_SMC_ASYNC_FUNCID_HWMON_READVOLT (0xE9)
+#define INTEL_SIP_SMC_ASYNC_HWMON_READVOLT \
+	INTEL_SIP_SMC_ASYNC_VAL(INTEL_SIP_SMC_ASYNC_FUNCID_HWMON_READVOLT)
+
 /**
  * Request INTEL_SIP_SMC_ASYNC_POLL
  * Async call used by service driver at EL1 to query mailbox response from SDM.
diff --git a/include/linux/firmware/intel/stratix10-svc-client.h b/include/linux/firmware/intel/stratix10-svc-client.h
index bda837815bae35fbf4df6280dba5bc02d747426e..032e780c7b545e2e238f9dea712779d979e491d6 100644
--- a/include/linux/firmware/intel/stratix10-svc-client.h
+++ b/include/linux/firmware/intel/stratix10-svc-client.h
@@ -16,6 +16,7 @@
 #define SVC_CLIENT_FPGA			"fpga"
 #define SVC_CLIENT_RSU			"rsu"
 #define SVC_CLIENT_FCS			"fcs"
+#define SVC_CLIENT_HWMON		"hwmon"
 
 /*
  * Status of the sent command, in bit number
@@ -71,6 +72,7 @@
 #define SVC_RSU_REQUEST_TIMEOUT_MS              300
 #define SVC_FCS_REQUEST_TIMEOUT_MS		2000
 #define SVC_COMPLETED_TIMEOUT_MS		30000
+#define SVC_HWMON_REQUEST_TIMEOUT_MS		2000
 
 struct stratix10_svc_chan;
 
@@ -142,6 +144,12 @@ struct stratix10_svc_chan;
  *
  * @COMMAND_FCS_RANDOM_NUMBER_GEN: generate a random number, return status
  * is SVC_STATUS_OK, SVC_STATUS_ERROR
+ *
+ * @COMMAND_HWMON_READTEMP: read temperature from the hardware sensor connected
+ * to the FPGA, return status is SVC_STATUS_OK, SVC_STATUS_ERROR
+ *
+ * @COMMAND_HWMON_READVOLT: read voltage from the hardware sensor connected
+ * to the FPGA, return status is SVC_STATUS_OK, SVC_STATUS_ERROR
  */
 enum stratix10_svc_command_code {
 	/* for FPGA */
@@ -172,6 +180,9 @@ enum stratix10_svc_command_code {
 	COMMAND_MBOX_SEND_CMD = 100,
 	/* Non-mailbox SMC Call */
 	COMMAND_SMC_SVC_VERSION = 200,
+	/* for HWMON */
+	COMMAND_HWMON_READTEMP,
+	COMMAND_HWMON_READVOLT
 };
 
 /**

-- 
2.35.3

