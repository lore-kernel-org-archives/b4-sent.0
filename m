From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:22:56 +0000
Subject: [PATCH RESEND v2 2/2] nfc: st21nfca: prevent double completion of
 SE APDU request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-st21nfca-v2-v2-2-cf9102b314cb@gmail.com>
References: <20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com>
In-Reply-To: <20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com>
To: joasantonio108@gmail.com, david@ixit.cz, krzk@kernel.org
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794280974; l=2168;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=vFtcDmj/HhhskQoZyc9H4wJhx0PE7EpKs3FCfz2WE98=;
 b=rIUPhYTo2Yupd9x65BjIKJkqYAv/BbFe27BYJ5yIfo518AhBAtOVvFU0haXFeFjxMrvmFSICD
 k6/wF5ymG0YCcR5F7nxwpnNDJm1SmdWGyI8+f2OPFJHddEZaMfTQ/Qr
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the spinlock added in the previous commit to prevent completing an
SE APDU request more than once.  Without this, the timeout work handler
(st21nfca_se_wt_work) and the EVT_TRANSMIT_DATA event handler can race
and both invoke the callback, leading to a use-after-free or double-free
of the callback context.

Check bwi_active under the lock in both completion paths and bail out if
the request was already completed.  Also reject a new SE APDU request in
st21nfca_hci_se_io() while one is already in progress by returning
-EBUSY.

Found by LLM-assisted manual code review.

Fixes: 2130fb97fecf ("NFC: st21nfca: Adding support for secure element")
Cc: Simon Horman <horms@kernel.org>
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/nfc/st21nfca/se.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/nfc/st21nfca/se.c b/drivers/nfc/st21nfca/se.c
index 03a30f797ff8..3be77420e956 100644
--- a/drivers/nfc/st21nfca/se.c
+++ b/drivers/nfc/st21nfca/se.c
@@ -228,6 +228,10 @@ int st21nfca_hci_se_io(struct nfc_hci_dev *hdev, u32 se_idx,
 	switch (se_idx) {
 	case ST21NFCA_ESE_HOST_ID:
 		spin_lock(&info->se_info.se_lock);
+		if (info->se_info.bwi_active) {
+			spin_unlock(&info->se_info.se_lock);
+			return -EBUSY;
+		}
 		info->se_info.cb = cb;
 		info->se_info.cb_context = cb_context;
 		info->se_info.bwi_active = true;
@@ -269,6 +273,10 @@ static void st21nfca_se_wt_work(struct work_struct *work)
 						se_info.timeout_work);
 
 	spin_lock(&info->se_info.se_lock);
+	if (!info->se_info.bwi_active) {
+		spin_unlock(&info->se_info.se_lock);
+		return;
+	}
 	info->se_info.bwi_active = false;
 	cb = info->se_info.cb;
 	cb_context = info->se_info.cb_context;
@@ -395,6 +403,10 @@ int st21nfca_apdu_reader_event_received(struct nfc_hci_dev *hdev,
 		cancel_work_sync(&info->se_info.timeout_work);
 
 		spin_lock(&info->se_info.se_lock);
+		if (!info->se_info.bwi_active) {
+			spin_unlock(&info->se_info.se_lock);
+			break;
+		}
 		info->se_info.bwi_active = false;
 		cb = info->se_info.cb;
 		cb_context = info->se_info.cb_context;

-- 
2.43.0

