From: Stefan Hansson <newbyte@postmarketos.org>
Date: Tue, 04 Aug 2026 10:55:41 +0200
Subject: [PATCH v2] wifi: rsi: Fix types to appease CFI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-rsi-cfi-fix-v2-1-59679a520240@postmarketos.org>
X-B4-Tracking: v=1; b=H4sIAAypcWoC/22NwQ6CMBBEf8Xs2Zp2FYKe/A/DAcoCq5GS3Uo0h
 H+34NXjm8y8mUFJmBQuuxmEJlYOQwLc78D31dCR4SYxoMXcFhaNKBvfsmn5bdDaIqvz87FBhLQ
 YhVK82W7lj/VV38nHVbE2etYY5LPdTW7t/TdPzjiTFega9HV2IrqOQeOzkgfFoIcgHZTLsnwB+
 PzwML8AAAA=
X-Change-ID: 20260802-rsi-cfi-fix-20085b693d22
To: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht
Cc: Stefan Hansson <newbyte@postmarketos.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785833758; l=5665;
 i=newbyte@postmarketos.org; s=20260802; h=from:subject:message-id;
 bh=BB2op5+p7icC+54RZOKKgba+7WNOZz8dHsaqqYyKAvc=;
 b=ThwlqJJN1yoe+CcfBWuSg1qewHU3rshzTmTRG6YrHMTCThXu+4doDF1T6xeiW1wFudVbbaMYN
 1nVorWYRGjjC5veppy7VSJwhAXsDo9LYvi+BC4+lu1phkid1DpFJ4oL
X-Developer-Key: i=newbyte@postmarketos.org; a=ed25519;
 pk=CMd9mCPy2ujgZ4/0VRH1OVotAimnFmPg2/JMEEgsOUk=
X-Endpoint-Received: by B4 Relay for newbyte@postmarketos.org/20260802 with auth_id=910
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoids errors like:

    CFI failure at kthread+0x124/0x1cc (target: rsi_coex_scheduler_thread+0x0/0x1b4 [redpine_91x]; expected type: 0x89fb613d)

As seen in the aforementioned error this was tested using the downstream
redpine_91x driver found in the Librem 5's downstream source tree.
However, it appears that this driver is a modified version of the rsi
driver found in mainline Linux and as such I decided to port the changes
here too.

Signed-off-by: Stefan Hansson <newbyte@postmarketos.org>
---
Changes in v2:
- Fix kernel-doc warnings.
- Link to v1: https://patch.msgid.link/20260802-rsi-cfi-fix-v1-1-5821d2cb54ee@postmarketos.org
---
 drivers/net/wireless/rsi/rsi_91x_coex.c     | 3 ++-
 drivers/net/wireless/rsi/rsi_91x_main.c     | 7 ++++---
 drivers/net/wireless/rsi/rsi_91x_sdio_ops.c | 3 ++-
 drivers/net/wireless/rsi/rsi_91x_usb_ops.c  | 7 ++++---
 drivers/net/wireless/rsi/rsi_common.h       | 2 +-
 drivers/net/wireless/rsi/rsi_sdio.h         | 2 +-
 drivers/net/wireless/rsi/rsi_usb.h          | 2 +-
 7 files changed, 15 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/rsi/rsi_91x_coex.c b/drivers/net/wireless/rsi/rsi_91x_coex.c
index ee603a5173fb..023c539fc384 100644
--- a/drivers/net/wireless/rsi/rsi_91x_coex.c
+++ b/drivers/net/wireless/rsi/rsi_91x_coex.c
@@ -50,8 +50,9 @@ static void rsi_coex_sched_tx_pkts(struct rsi_coex_ctrl_block *coex_cb)
 	} while (coex_q != RSI_COEX_Q_INVALID);
 }
 
-static void rsi_coex_scheduler_thread(struct rsi_common *common)
+static int rsi_coex_scheduler_thread(void *data)
 {
+	struct rsi_common *common = data;
 	struct rsi_coex_ctrl_block *coex_cb = common->coex_cb;
 	u32 timeout = EVENT_WAIT_FOREVER;
 
diff --git a/drivers/net/wireless/rsi/rsi_91x_main.c b/drivers/net/wireless/rsi/rsi_91x_main.c
index 662e42d1e5e8..2ce514766620 100644
--- a/drivers/net/wireless/rsi/rsi_91x_main.c
+++ b/drivers/net/wireless/rsi/rsi_91x_main.c
@@ -246,12 +246,13 @@ EXPORT_SYMBOL_GPL(rsi_read_pkt);
 /**
  * rsi_tx_scheduler_thread() - This function is a kernel thread to send the
  *			       packets to the device.
- * @common: Pointer to the driver private structure.
+ * @data: Pointer to the driver private structure.
  *
- * Return: None.
+ * Return: 0.
  */
-static void rsi_tx_scheduler_thread(struct rsi_common *common)
+static int rsi_tx_scheduler_thread(void *data)
 {
+	struct rsi_common *common = data;
 	struct rsi_hw *adapter = common->priv;
 	u32 timeout = EVENT_WAIT_FOREVER;
 
diff --git a/drivers/net/wireless/rsi/rsi_91x_sdio_ops.c b/drivers/net/wireless/rsi/rsi_91x_sdio_ops.c
index 597b238e2294..18a28aa97446 100644
--- a/drivers/net/wireless/rsi/rsi_91x_sdio_ops.c
+++ b/drivers/net/wireless/rsi/rsi_91x_sdio_ops.c
@@ -62,8 +62,9 @@ int rsi_sdio_master_access_msword(struct rsi_hw *adapter, u16 ms_word)
 
 static void rsi_rx_handler(struct rsi_hw *adapter);
 
-void rsi_sdio_rx_thread(struct rsi_common *common)
+int rsi_sdio_rx_thread(void *data)
 {
+	struct rsi_common *common = data;
 	struct rsi_hw *adapter = common->priv;
 	struct rsi_91x_sdiodev *sdev = adapter->rsi_dev;
 
diff --git a/drivers/net/wireless/rsi/rsi_91x_usb_ops.c b/drivers/net/wireless/rsi/rsi_91x_usb_ops.c
index 25c2b232394a..e899631b9aed 100644
--- a/drivers/net/wireless/rsi/rsi_91x_usb_ops.c
+++ b/drivers/net/wireless/rsi/rsi_91x_usb_ops.c
@@ -21,12 +21,13 @@
 /**
  * rsi_usb_rx_thread() - This is a kernel thread to receive the packets from
  *			 the USB device.
- * @common: Pointer to the driver private structure.
+ * @data: Pointer to the driver private structure.
  *
- * Return: None.
+ * Return: 0.
  */
-void rsi_usb_rx_thread(struct rsi_common *common)
+int rsi_usb_rx_thread(void *data)
 {
+	struct rsi_common *common = data;
 	struct rsi_hw *adapter = common->priv;
 	struct rsi_91x_usbdev *dev = adapter->rsi_dev;
 	int status;
diff --git a/drivers/net/wireless/rsi/rsi_common.h b/drivers/net/wireless/rsi/rsi_common.h
index 3cdf9ded876d..2a33a81f71a3 100644
--- a/drivers/net/wireless/rsi/rsi_common.h
+++ b/drivers/net/wireless/rsi/rsi_common.h
@@ -58,7 +58,7 @@ static inline void rsi_reset_event(struct rsi_event *event)
 
 static inline int rsi_create_kthread(struct rsi_common *common,
 				     struct rsi_thread *thread,
-				     void *func_ptr,
+				     int (*func_ptr)(void *data),
 				     u8 *name)
 {
 	init_completion(&thread->completion);
diff --git a/drivers/net/wireless/rsi/rsi_sdio.h b/drivers/net/wireless/rsi/rsi_sdio.h
index 7c91b126b350..eb2b7f36a7e4 100644
--- a/drivers/net/wireless/rsi/rsi_sdio.h
+++ b/drivers/net/wireless/rsi/rsi_sdio.h
@@ -134,5 +134,5 @@ int rsi_sdio_master_access_msword(struct rsi_hw *adapter, u16 ms_word);
 void rsi_sdio_ack_intr(struct rsi_hw *adapter, u8 int_bit);
 int rsi_sdio_determine_event_timeout(struct rsi_hw *adapter);
 int rsi_sdio_check_buffer_status(struct rsi_hw *adapter, u8 q_num);
-void rsi_sdio_rx_thread(struct rsi_common *common);
+int rsi_sdio_rx_thread(void *data);
 #endif
diff --git a/drivers/net/wireless/rsi/rsi_usb.h b/drivers/net/wireless/rsi/rsi_usb.h
index 961851748bc4..78067eaffe8b 100644
--- a/drivers/net/wireless/rsi/rsi_usb.h
+++ b/drivers/net/wireless/rsi/rsi_usb.h
@@ -81,5 +81,5 @@ static inline int rsi_usb_event_timeout(struct rsi_hw *adapter)
 	return EVENT_WAIT_FOREVER;
 }
 
-void rsi_usb_rx_thread(struct rsi_common *common);
+int rsi_usb_rx_thread(void *data);
 #endif

---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260802-rsi-cfi-fix-20085b693d22

Best regards,
--  
Stefan Hansson <newbyte@postmarketos.org>

