From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:55:41 +0000
Subject: [PATCH] Bluetooth: hci_qca: clear qca_memdump when discarding dump
 packets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hci-qca-memdump-v1-1-239974fc4944@gmail.com>
X-B4-Tracking: v=1; b=H4sIALyV8moC/x3MQQqAIBBA0avErBtoLAS7SrQIHWsWWilFIN09a
 fkW/xfInIQzjE2BxLdk2WMFtQ3YbYkro7hqUJ3SRNThZgVPu2Dg4K5woCKrlRnYm95BrY7EXp7
 /OM3v+wF0cY9HYQAAAA==
To: joasantonio108@gmail.com, luiz.dentz@gmail.com, marcel@holtmann.org, 
 brgl@kernel.org
Cc: linux-bluetooth@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794282940; l=2103;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=ky0Z69/8Hiei/KREhnhz5BrjI36LiqN/BL+G9cWkhts=;
 b=Fpp9qgn9mgLlNK8HTfX9YFADJ3oNpTU9aMYUE6TkfR7/SmBCR29YJY1ZwfuE+IeXPLxNF7zeA
 xU6DViEJ2pNC2WD2lAApbQcTEuNXi2db+N5cKpP+9tn3kngR6z0bPlH
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qca_controller_memdump() frees qca_memdump when a memdump packet with a
non-zero sequence number arrives while QCA_MEMDUMP_COLLECTION is not
set, but leaves qca->qca_memdump pointing at the freed object.

The next run of the work reads the stale pointer into its local
variable, skips the allocation and uses the freed memory.  Another
packet with a non-zero sequence number frees it a second time, and a
packet with sequence number 0 writes ram_dump_size, current_seq_no and
received_dump into it.

The original code cleared the pointer here; the assignment was dropped
when the condition was changed to test QCA_MEMDUMP_COLLECTION.  All
other places that free the structure clear the pointer.

A controller that sends two memdump events without a leading sequence
number 0 can trigger a use-after-free or double free of a kmalloc
object.

Found by LLM-assisted source review.

Fixes: 06d3fdfcdf5c ("Bluetooth: hci_qca: Add qcom devcoredump support")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 drivers/bluetooth/hci_qca.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index e480d38109cf..9dd8aa0ca8b1 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -1127,6 +1127,7 @@ static void qca_controller_memdump(struct work_struct *work)
 		if (!test_bit(QCA_MEMDUMP_COLLECTION, &qca->flags)) {
 			bt_dev_err(hu->hdev, "QCA: Discarding other packets");
 			kfree(qca_memdump);
+			qca->qca_memdump = NULL;
 			kfree_skb(skb);
 			mutex_unlock(&qca->hci_memdump_lock);
 			return;

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-hci-qca-memdump-21c6294ef93d

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

