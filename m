From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Thu, 12 Nov 2026 13:39:30 +0000
Subject: [PATCH net v3 2/2] nfc: st21nfca: prevent double completion of SE
 APDU request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-st21nfca-v2-v3-2-c81702269e01@gmail.com>
References: <20261112-st21nfca-v2-v3-0-c81702269e01@gmail.com>
In-Reply-To: <20261112-st21nfca-v2-v3-0-c81702269e01@gmail.com>
To: david@ixit.cz, krzk@kernel.org, joasantonio108@gmail.com
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794490768; l=3240;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=vqHaopVgmvBm60zL9N9NShO0nqLNUceOzRe4TpLFHXE=;
 b=aOASxBBDF+J49IECQQPB6r/37593fsh0gpF67cWJQhtGpM6W4vvqwtg8wq87QCpiYLbNpLlNg
 5cascdw5MWQA70BDjszptYvxSBe6BEZ3ItpftG8pYyChuSp1Um1mz1t
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the spinlock added in the previous commit to prevent completing an
SE APDU request more than once.  Without this, the timeout work handler
(st21nfca_se_wt_work) and the EVT_TRANSMIT_DATA event handler can both
invoke the callback for the same request.  The callback frees its
context, so the second call is a use-after-free followed by a double
free.

Check bwi_active under the lock in both completion paths and only
complete a request that is still pending.  A response that arrives
after the timeout still gets its EVT_SE_END_OF_APDU_TRANSFER, as
before, but no callback.

Also reject a new SE APDU request in st21nfca_hci_se_io() with -EBUSY
while one is in progress, instead of overwriting the callback and
context of the pending request.  The callback is not called in that
case, so free the context like the -ENODEV path does; nfc_se_io() does
not free it once the driver has been called.

Found by LLM-assisted manual code review.

Fixes: 2130fb97fecf ("NFC: st21nfca: Adding support for secure element")
Cc: Simon Horman <horms@kernel.org>
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/nfc/st21nfca/se.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/nfc/st21nfca/se.c b/drivers/nfc/st21nfca/se.c
index 03a30f797ff8..63a88a61d310 100644
--- a/drivers/nfc/st21nfca/se.c
+++ b/drivers/nfc/st21nfca/se.c
@@ -228,6 +228,12 @@ int st21nfca_hci_se_io(struct nfc_hci_dev *hdev, u32 se_idx,
 	switch (se_idx) {
 	case ST21NFCA_ESE_HOST_ID:
 		spin_lock(&info->se_info.se_lock);
+		if (info->se_info.bwi_active) {
+			spin_unlock(&info->se_info.se_lock);
+			/* The callback is not called, see the comment below */
+			kfree(cb_context);
+			return -EBUSY;
+		}
 		info->se_info.cb = cb;
 		info->se_info.cb_context = cb_context;
 		info->se_info.bwi_active = true;
@@ -269,6 +275,10 @@ static void st21nfca_se_wt_work(struct work_struct *work)
 						se_info.timeout_work);
 
 	spin_lock(&info->se_info.se_lock);
+	if (!info->se_info.bwi_active) {
+		spin_unlock(&info->se_info.se_lock);
+		return;
+	}
 	info->se_info.bwi_active = false;
 	cb = info->se_info.cb;
 	cb_context = info->se_info.cb_context;
@@ -383,6 +393,7 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 					u8 event, struct sk_buff *skb)
 {
 	int r = 0;
+	bool active;
 	se_io_cb_t cb;
 	void *cb_context;
 	struct st21nfca_hci_info *info = nfc_hci_get_clientdata(hdev);
@@ -395,6 +406,7 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 		cancel_work_sync(&info->se_info.timeout_work);
 
 		spin_lock(&info->se_info.se_lock);
+		active = info->se_info.bwi_active;
 		info->se_info.bwi_active = false;
 		cb = info->se_info.cb;
 		cb_context = info->se_info.cb_context;
@@ -405,7 +417,9 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 		if (r < 0)
 			goto exit;
 
-		cb(cb_context, skb->data, skb->len, 0);
+		/* The request may have been completed by the timeout already */
+		if (active)
+			cb(cb_context, skb->data, skb->len, 0);
 		break;
 	case ST21NFCA_EVT_WTX_REQUEST:
 		mod_timer(&info->se_info.bwi_timer, jiffies +

-- 
2.43.0

