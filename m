From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:22:55 +0000
Subject: [PATCH RESEND v2 1/2] nfc: st21nfca: add spinlock to serialize SE
 APDU request state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-st21nfca-v2-v2-1-cf9102b314cb@gmail.com>
References: <20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com>
In-Reply-To: <20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com>
To: joasantonio108@gmail.com, david@ixit.cz, krzk@kernel.org
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794280974; l=4914;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=ySTOHlr1/hkeoLYuHUkCy4vhtVB1vXmf0ml4VRRLgTY=;
 b=m6yqmwUnZBBpH8i7JLb5RG0iGIhprXBmZLgGN8Vz8eonunfH1GdpvEE1YWpvg4mf0peWiVDCu
 DjbuqqsUQYSCOBAWiAhhkMcRqDfUQhz7VbBJHTFxw5uLf/p3jvCFAOK
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bwi_active flag, callback pointer (cb), and callback context
(cb_context) in st21nfca_se_info are accessed concurrently from
multiple contexts without synchronization:

 - st21nfca_hci_se_io() sets them from the netlink/ioctl path
 - st21nfca_se_wt_work() reads/clears them from the timeout workqueue
 - st21nfca_apdu_reader_event_received() reads/clears them from the
   HCI rx path

Add a spinlock (se_lock) to serialize access to these fields.  The
callback pointer and context are copied under the lock and invoked
after releasing it, since both the callback and nfc_hci_send_event()
may sleep.

Also move the bwi_active = true assignment before mod_timer() so that
the flag is always set before the timeout handler could observe it.

Found by LLM-assisted manual code review.

Fixes: 2130fb97fecf ("NFC: st21nfca: Adding support for secure element")
Cc: Simon Horman <horms@kernel.org>
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/nfc/st21nfca/se.c       | 24 ++++++++++++++++++++----
 drivers/nfc/st21nfca/st21nfca.h |  2 ++
 2 files changed, 22 insertions(+), 4 deletions(-)

diff --git a/drivers/nfc/st21nfca/se.c b/drivers/nfc/st21nfca/se.c
index 7154bc1d644a..03a30f797ff8 100644
--- a/drivers/nfc/st21nfca/se.c
+++ b/drivers/nfc/st21nfca/se.c
@@ -227,11 +227,13 @@ int st21nfca_hci_se_io(struct nfc_hci_dev *hdev, u32 se_idx,
 
 	switch (se_idx) {
 	case ST21NFCA_ESE_HOST_ID:
+		spin_lock(&info->se_info.se_lock);
 		info->se_info.cb = cb;
 		info->se_info.cb_context = cb_context;
+		info->se_info.bwi_active = true;
+		spin_unlock(&info->se_info.se_lock);
 		mod_timer(&info->se_info.bwi_timer, jiffies +
 			  msecs_to_jiffies(info->se_info.wt_timeout));
-		info->se_info.bwi_active = true;
 		return nfc_hci_send_event(hdev, ST21NFCA_APDU_READER_GATE,
 					ST21NFCA_EVT_TRANSMIT_DATA,
 					apdu, apdu_length);
@@ -260,11 +262,17 @@ static void st21nfca_se_wt_work(struct work_struct *work)
 	 */
 	/* hardware reset managed through VCC_UICC_OUT power supply */
 	u8 param = 0x01;
+	se_io_cb_t cb;
+	void *cb_context;
 	struct st21nfca_hci_info *info = container_of(work,
 						struct st21nfca_hci_info,
 						se_info.timeout_work);
 
+	spin_lock(&info->se_info.se_lock);
 	info->se_info.bwi_active = false;
+	cb = info->se_info.cb;
+	cb_context = info->se_info.cb_context;
+	spin_unlock(&info->se_info.se_lock);
 
 	if (!info->se_info.xch_error) {
 		info->se_info.xch_error = true;
@@ -275,7 +283,7 @@ static void st21nfca_se_wt_work(struct work_struct *work)
 		nfc_hci_send_event(info->hdev, ST21NFCA_DEVICE_MGNT_GATE,
 				ST21NFCA_EVT_SE_HARD_RESET, &param, 1);
 	}
-	info->se_info.cb(info->se_info.cb_context, NULL, 0, -ETIME);
+	cb(cb_context, NULL, 0, -ETIME);
 }
 
 static void st21nfca_se_wt_timeout(struct timer_list *t)
@@ -375,6 +383,8 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 					u8 event, struct sk_buff *skb)
 {
 	int r = 0;
+	se_io_cb_t cb;
+	void *cb_context;
 	struct st21nfca_hci_info *info = nfc_hci_get_clientdata(hdev);
 
 	pr_debug("apdu reader gate event: %x\n", event);
@@ -383,14 +393,19 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 	case ST21NFCA_EVT_TRANSMIT_DATA:
 		timer_delete_sync(&info->se_info.bwi_timer);
 		cancel_work_sync(&info->se_info.timeout_work);
+
+		spin_lock(&info->se_info.se_lock);
 		info->se_info.bwi_active = false;
+		cb = info->se_info.cb;
+		cb_context = info->se_info.cb_context;
+		spin_unlock(&info->se_info.se_lock);
+
 		r = nfc_hci_send_event(hdev, ST21NFCA_DEVICE_MGNT_GATE,
 				ST21NFCA_EVT_SE_END_OF_APDU_TRANSFER, NULL, 0);
 		if (r < 0)
 			goto exit;
 
-		info->se_info.cb(info->se_info.cb_context,
-			skb->data, skb->len, 0);
+		cb(cb_context, skb->data, skb->len, 0);
 		break;
 	case ST21NFCA_EVT_WTX_REQUEST:
 		mod_timer(&info->se_info.bwi_timer, jiffies +
@@ -416,6 +431,7 @@ void st21nfca_se_init(struct nfc_hci_dev *hdev)
 	/* initialize timers */
 	timer_setup(&info->se_info.bwi_timer, st21nfca_se_wt_timeout, 0);
 	info->se_info.bwi_active = false;
+	spin_lock_init(&info->se_info.se_lock);
 
 	timer_setup(&info->se_info.se_active_timer,
 		    st21nfca_se_activation_timeout, 0);
diff --git a/drivers/nfc/st21nfca/st21nfca.h b/drivers/nfc/st21nfca/st21nfca.h
index ae6771cc9894..abcef1ee48f2 100644
--- a/drivers/nfc/st21nfca/st21nfca.h
+++ b/drivers/nfc/st21nfca/st21nfca.h
@@ -6,6 +6,7 @@
 #ifndef __LOCAL_ST21NFCA_H_
 #define __LOCAL_ST21NFCA_H_
 
+#include <linux/spinlock.h>
 #include <net/nfc/hci.h>
 #include <linux/skbuff.h>
 #include <linux/workqueue.h>
@@ -131,6 +132,7 @@ struct st21nfca_se_info {
 	struct timer_list bwi_timer;
 	int wt_timeout; /* in msecs */
 	bool bwi_active;
+	spinlock_t se_lock;
 
 	struct timer_list se_active_timer;
 	bool se_active;

-- 
2.43.0

