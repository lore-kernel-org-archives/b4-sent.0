From: Mahesh Rao <mahesh.rao@altera.com>
Date: Mon, 27 Oct 2025 22:54:43 +0800
Subject: [PATCH v7 4/4] firmware: stratix10-rsu: Migrate RSU driver to use
 stratix10 asynchronous framework.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-sip_svc_upstream-v7-4-6e9ab26d7480@altera.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761576953; l=13384;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=EasTpB3pb/7uVYkP5RQQljasDKgKBokFEn3X5P3uAvE=;
 b=sy9RkTxHaVvJlvz3uSmEV/Nu+utQDNcw7TBK4ne6Ek4VQEePhXv3aQCSj9mFSkRpp691xbMwj
 KwD5QBwhfARCT6o/osob94mSydhxZmeZ0fdgFeOsyef2UgxFto9nXET
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

* Add support for asynchronous communication to the RSU client channel.
* Migrate functions that communicate with the SDM to use the asynchronous
  framework.

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
Signed-off-by: Dinh Nguyen <dinguyen@kernel.org>
---
 drivers/firmware/stratix10-rsu.c | 272 ++++++++++++++++++++-------------------
 1 file changed, 142 insertions(+), 130 deletions(-)

diff --git a/drivers/firmware/stratix10-rsu.c b/drivers/firmware/stratix10-rsu.c
index 1ea39a0a76c787c6396300734b636b4b3a0ae04d..53b67b242cf0afa4102340aa099cef66b642effa 100644
--- a/drivers/firmware/stratix10-rsu.c
+++ b/drivers/firmware/stratix10-rsu.c
@@ -1,6 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
  * Copyright (C) 2018-2019, Intel Corporation
+ * Copyright (C) 2025, Altera Corporation
  */
 
 #include <linux/arm-smccc.h>
@@ -14,11 +15,9 @@
 #include <linux/firmware/intel/stratix10-svc-client.h>
 #include <linux/string.h>
 #include <linux/sysfs.h>
+#include <linux/delay.h>
 
-#define RSU_STATE_MASK			GENMASK_ULL(31, 0)
-#define RSU_VERSION_MASK		GENMASK_ULL(63, 32)
-#define RSU_ERROR_LOCATION_MASK		GENMASK_ULL(31, 0)
-#define RSU_ERROR_DETAIL_MASK		GENMASK_ULL(63, 32)
+#define RSU_ERASE_SIZE_MASK		GENMASK_ULL(63, 32)
 #define RSU_DCMF0_MASK			GENMASK_ULL(31, 0)
 #define RSU_DCMF1_MASK			GENMASK_ULL(63, 32)
 #define RSU_DCMF2_MASK			GENMASK_ULL(31, 0)
@@ -35,7 +34,8 @@
 #define INVALID_DCMF_STATUS		0xFFFFFFFF
 #define INVALID_SPT_ADDRESS		0x0
 
-#define RSU_GET_SPT_CMD			0x5A
+#define RSU_RETRY_SLEEP_MS		(1U)
+#define RSU_ASYNC_MSG_RETRY		(3U)
 #define RSU_GET_SPT_RESP_LEN		(4 * sizeof(unsigned int))
 
 typedef void (*rsu_callback)(struct stratix10_svc_client *client,
@@ -64,7 +64,6 @@ typedef void (*rsu_callback)(struct stratix10_svc_client *client,
  * @max_retry: the preset max retry value
  * @spt0_address: address of spt0
  * @spt1_address: address of spt1
- * @get_spt_response_buf: response from sdm for get_spt command
  */
 struct stratix10_rsu_priv {
 	struct stratix10_svc_chan *chan;
@@ -99,47 +98,32 @@ struct stratix10_rsu_priv {
 
 	unsigned long spt0_address;
 	unsigned long spt1_address;
-
-	unsigned int *get_spt_response_buf;
 };
 
+typedef void (*rsu_async_callback)(struct device *dev,
+	struct stratix10_rsu_priv *priv, struct stratix10_svc_cb_data *data);
+
 /**
- * rsu_status_callback() - Status callback from Intel Service Layer
- * @client: pointer to service client
+ * rsu_async_status_callback() - Status callback from rsu_async_send()
+ * @dev: pointer to device object
+ * @priv: pointer to priv object
  * @data: pointer to callback data structure
  *
- * Callback from Intel service layer for RSU status request. Status is
- * only updated after a system reboot, so a get updated status call is
- * made during driver probe.
+ * Callback from rsu_async_send() to get the system rsu error status.
  */
-static void rsu_status_callback(struct stratix10_svc_client *client,
-				struct stratix10_svc_cb_data *data)
+static void rsu_async_status_callback(struct device *dev,
+				      struct stratix10_rsu_priv *priv,
+				      struct stratix10_svc_cb_data *data)
 {
-	struct stratix10_rsu_priv *priv = client->priv;
-	struct arm_smccc_res *res = (struct arm_smccc_res *)data->kaddr1;
-
-	if (data->status == BIT(SVC_STATUS_OK)) {
-		priv->status.version = FIELD_GET(RSU_VERSION_MASK,
-						 res->a2);
-		priv->status.state = FIELD_GET(RSU_STATE_MASK, res->a2);
-		priv->status.fail_image = res->a1;
-		priv->status.current_image = res->a0;
-		priv->status.error_location =
-			FIELD_GET(RSU_ERROR_LOCATION_MASK, res->a3);
-		priv->status.error_details =
-			FIELD_GET(RSU_ERROR_DETAIL_MASK, res->a3);
-	} else {
-		dev_err(client->dev, "COMMAND_RSU_STATUS returned 0x%lX\n",
-			res->a0);
-		priv->status.version = 0;
-		priv->status.state = 0;
-		priv->status.fail_image = 0;
-		priv->status.current_image = 0;
-		priv->status.error_location = 0;
-		priv->status.error_details = 0;
-	}
-
-	complete(&priv->completion);
+	struct arm_smccc_1_2_regs *res = (struct arm_smccc_1_2_regs *)data->kaddr1;
+
+	priv->status.current_image = res->a2;
+	priv->status.fail_image = res->a3;
+	priv->status.state = res->a4;
+	priv->status.version = res->a5;
+	priv->status.error_location = res->a7;
+	priv->status.error_details = res->a8;
+	priv->retry_counter = res->a9;
 }
 
 /**
@@ -163,32 +147,6 @@ static void rsu_command_callback(struct stratix10_svc_client *client,
 	complete(&priv->completion);
 }
 
-/**
- * rsu_retry_callback() - Callback from Intel service layer for getting
- * the current image's retry counter from the firmware
- * @client: pointer to client
- * @data: pointer to callback data structure
- *
- * Callback from Intel service layer for retry counter, which is used by
- * user to know how many times the images is still allowed to reload
- * itself before giving up and starting RSU fail-over flow.
- */
-static void rsu_retry_callback(struct stratix10_svc_client *client,
-			       struct stratix10_svc_cb_data *data)
-{
-	struct stratix10_rsu_priv *priv = client->priv;
-	unsigned int *counter = (unsigned int *)data->kaddr1;
-
-	if (data->status == BIT(SVC_STATUS_OK))
-		priv->retry_counter = *counter;
-	else if (data->status == BIT(SVC_STATUS_NO_SUPPORT))
-		dev_warn(client->dev, "Secure FW doesn't support retry\n");
-	else
-		dev_err(client->dev, "Failed to get retry counter %lu\n",
-			BIT(data->status));
-
-	complete(&priv->completion);
-}
 
 /**
  * rsu_max_retry_callback() - Callback from Intel service layer for getting
@@ -270,34 +228,19 @@ static void rsu_dcmf_status_callback(struct stratix10_svc_client *client,
 	complete(&priv->completion);
 }
 
-static void rsu_get_spt_callback(struct stratix10_svc_client *client,
-				 struct stratix10_svc_cb_data *data)
+/**
+ * rsu_async_get_spt_table_callback() - Callback to be used by the rsu_async_send()
+ * to retrieve the SPT table information.
+ * @dev: pointer to device object
+ * @priv: pointer to priv object
+ * @data: pointer to callback data structure
+ */
+static void rsu_async_get_spt_table_callback(struct device *dev,
+					     struct stratix10_rsu_priv *priv,
+					     struct stratix10_svc_cb_data *data)
 {
-	struct stratix10_rsu_priv *priv = client->priv;
-	unsigned long *mbox_err = (unsigned long *)data->kaddr1;
-	unsigned long *resp_len = (unsigned long *)data->kaddr2;
-
-	if (data->status != BIT(SVC_STATUS_OK) || (*mbox_err) ||
-	    (*resp_len != RSU_GET_SPT_RESP_LEN))
-		goto error;
-
-	priv->spt0_address = priv->get_spt_response_buf[0];
-	priv->spt0_address <<= 32;
-	priv->spt0_address |= priv->get_spt_response_buf[1];
-
-	priv->spt1_address = priv->get_spt_response_buf[2];
-	priv->spt1_address <<= 32;
-	priv->spt1_address |= priv->get_spt_response_buf[3];
-
-	goto complete;
-
-error:
-	dev_err(client->dev, "failed to get SPTs\n");
-
-complete:
-	stratix10_svc_free_memory(priv->chan, priv->get_spt_response_buf);
-	priv->get_spt_response_buf = NULL;
-	complete(&priv->completion);
+	priv->spt0_address = *((unsigned long *)data->kaddr1);
+	priv->spt1_address = *((unsigned long *)data->kaddr2);
 }
 
 /**
@@ -329,14 +272,6 @@ static int rsu_send_msg(struct stratix10_rsu_priv *priv,
 	if (arg)
 		msg.arg[0] = arg;
 
-	if (command == COMMAND_MBOX_SEND_CMD) {
-		msg.arg[1] = 0;
-		msg.payload = NULL;
-		msg.payload_length = 0;
-		msg.payload_output = priv->get_spt_response_buf;
-		msg.payload_length_output = RSU_GET_SPT_RESP_LEN;
-	}
-
 	ret = stratix10_svc_send(priv->chan, &msg);
 	if (ret < 0)
 		goto status_done;
@@ -362,6 +297,95 @@ static int rsu_send_msg(struct stratix10_rsu_priv *priv,
 	return ret;
 }
 
+/**
+ * soc64_async_callback() - Callback from Intel service layer for async requests
+ * @ptr: pointer to the completion object
+ */
+static void soc64_async_callback(void *ptr)
+{
+	if (ptr)
+		complete(ptr);
+}
+
+/**
+ * rsu_send_async_msg() - send an async message to Intel service layer
+ * @dev: pointer to device object
+ * @priv: pointer to rsu private data
+ * @command: RSU status or update command
+ * @arg: the request argument, notify status
+ * @callback: function pointer for the callback (status or update)
+ */
+static int rsu_send_async_msg(struct device *dev, struct stratix10_rsu_priv *priv,
+			      enum stratix10_svc_command_code command,
+			      unsigned long arg,
+			      rsu_async_callback callback)
+{
+	struct stratix10_svc_client_msg msg = {0};
+	struct stratix10_svc_cb_data data = {0};
+	struct completion completion;
+	int status, index, ret;
+	void *handle = NULL;
+
+	msg.command = command;
+	msg.arg[0] = arg;
+
+	init_completion(&completion);
+
+	for (index = 0; index < RSU_ASYNC_MSG_RETRY; index++) {
+		status = stratix10_svc_async_send(priv->chan, &msg,
+						  &handle, soc64_async_callback,
+						  &completion);
+		if (status == 0)
+			break;
+		dev_warn(dev, "Failed to send async message\n");
+		msleep(RSU_RETRY_SLEEP_MS);
+	}
+
+	if (status && !handle) {
+		dev_err(dev, "Failed to send async message\n");
+		return -ETIMEDOUT;
+	}
+
+	ret = wait_for_completion_io_timeout(&completion, RSU_TIMEOUT);
+	if (ret > 0)
+		dev_dbg(dev, "Received async interrupt\n");
+	else if (ret == 0)
+		dev_dbg(dev, "Timeout occurred. Trying to poll the response\n");
+
+	for (index = 0; index < RSU_ASYNC_MSG_RETRY; index++) {
+		status = stratix10_svc_async_poll(priv->chan, handle, &data);
+		if (status == -EAGAIN) {
+			dev_dbg(dev, "Async message is still in progress\n");
+		} else if (status < 0) {
+			dev_alert(dev, "Failed to poll async message\n");
+			ret = -ETIMEDOUT;
+		} else if (status == 0) {
+			ret = 0;
+			break;
+		}
+		msleep(RSU_RETRY_SLEEP_MS);
+	}
+
+	if (ret) {
+		dev_err(dev, "Failed to get async response\n");
+		goto status_done;
+	}
+
+	if (data.status == 0) {
+		ret = 0;
+		if (callback)
+			callback(dev, priv, &data);
+	} else {
+		dev_err(dev, "%s returned 0x%x from SDM\n", __func__,
+			data.status);
+		ret = -EFAULT;
+	}
+
+status_done:
+	stratix10_svc_async_done(priv->chan, handle);
+	return ret;
+}
+
 /*
  * This driver exposes some optional features of the Intel Stratix 10 SoC FPGA.
  * The sysfs interfaces exposed here are FPGA Remote System Update (RSU)
@@ -597,27 +621,20 @@ static ssize_t notify_store(struct device *dev,
 	if (ret)
 		return ret;
 
-	ret = rsu_send_msg(priv, COMMAND_RSU_NOTIFY,
-			   status, rsu_command_callback);
+	ret = rsu_send_async_msg(dev, priv, COMMAND_RSU_NOTIFY, status, NULL);
 	if (ret) {
 		dev_err(dev, "Error, RSU notify returned %i\n", ret);
 		return ret;
 	}
 
 	/* to get the updated state */
-	ret = rsu_send_msg(priv, COMMAND_RSU_STATUS,
-			   0, rsu_status_callback);
+	ret = rsu_send_async_msg(dev, priv, COMMAND_RSU_STATUS, 0,
+				 rsu_async_status_callback);
 	if (ret) {
 		dev_err(dev, "Error, getting RSU status %i\n", ret);
 		return ret;
 	}
 
-	ret = rsu_send_msg(priv, COMMAND_RSU_RETRY, 0, rsu_retry_callback);
-	if (ret) {
-		dev_err(dev, "Error, getting RSU retry %i\n", ret);
-		return ret;
-	}
-
 	return count;
 }
 
@@ -737,12 +754,19 @@ static int stratix10_rsu_probe(struct platform_device *pdev)
 		return PTR_ERR(priv->chan);
 	}
 
+	ret = stratix10_svc_add_async_client(priv->chan, false);
+	if (ret) {
+		dev_err(dev, "failed to add async client\n");
+		stratix10_svc_free_channel(priv->chan);
+		return ret;
+	}
+
 	init_completion(&priv->completion);
 	platform_set_drvdata(pdev, priv);
 
 	/* get the initial state from firmware */
-	ret = rsu_send_msg(priv, COMMAND_RSU_STATUS,
-			   0, rsu_status_callback);
+	ret = rsu_send_async_msg(dev, priv, COMMAND_RSU_STATUS, 0,
+				 rsu_async_status_callback);
 	if (ret) {
 		dev_err(dev, "Error, getting RSU status %i\n", ret);
 		stratix10_svc_free_channel(priv->chan);
@@ -763,12 +787,6 @@ static int stratix10_rsu_probe(struct platform_device *pdev)
 		stratix10_svc_free_channel(priv->chan);
 	}
 
-	ret = rsu_send_msg(priv, COMMAND_RSU_RETRY, 0, rsu_retry_callback);
-	if (ret) {
-		dev_err(dev, "Error, getting RSU retry %i\n", ret);
-		stratix10_svc_free_channel(priv->chan);
-	}
-
 	ret = rsu_send_msg(priv, COMMAND_RSU_MAX_RETRY, 0,
 			   rsu_max_retry_callback);
 	if (ret) {
@@ -776,18 +794,12 @@ static int stratix10_rsu_probe(struct platform_device *pdev)
 		stratix10_svc_free_channel(priv->chan);
 	}
 
-	priv->get_spt_response_buf =
-		stratix10_svc_allocate_memory(priv->chan, RSU_GET_SPT_RESP_LEN);
 
-	if (IS_ERR(priv->get_spt_response_buf)) {
-		dev_err(dev, "failed to allocate get spt buffer\n");
-	} else {
-		ret = rsu_send_msg(priv, COMMAND_MBOX_SEND_CMD,
-				   RSU_GET_SPT_CMD, rsu_get_spt_callback);
-		if (ret) {
-			dev_err(dev, "Error, getting SPT table %i\n", ret);
-			stratix10_svc_free_channel(priv->chan);
-		}
+	ret = rsu_send_async_msg(dev, priv, COMMAND_RSU_GET_SPT_TABLE, 0,
+				 rsu_async_get_spt_table_callback);
+	if (ret) {
+		dev_err(dev, "Error, getting SPT table %i\n", ret);
+		stratix10_svc_free_channel(priv->chan);
 	}
 
 	return ret;

-- 
2.43.7

