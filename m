From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Thu, 14 May 2026 23:18:13 +0530
Subject: [PATCH] Bluetooth: btmtk: Fix FUNC_CTRL parsing for devices with
 zero-length payloads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-bluetooh-fix-mt7922-v1-1-499c878af1e5@zohomail.in>
X-B4-Tracking: v=1; b=H4sIANwKBmoC/yXMQQqDMBCF4avIrB3QwSrpVYoLx050RE1JohTEu
 zfW5cfj/QcE8SoBntkBXnYN6taEMs+gH7t1ENR3MlBBdfEoK+R5k+jciFa/uMTGEKEhZhZriQx
 Den68pPVffbW3w8aT9PFKwXn+AIppPYt3AAAA
X-Change-ID: 20260514-bluetooh-fix-mt7922-92bbbeff229b
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Tristan Madani <tristan@talencesecurity.com>
Cc: Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 stable@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778780918; l=3281;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=bcjmkVn6V3NtLKEjGgmZqORTUn19c/SPpadc1fesit4=;
 b=/01nuKC6TNTxIJytg/c6BI11qqo/OIDmX6XK3217Rpx6jibl/qWUCcWwasbS3GKv892fZ2oGI
 SPlPJOfwOb7Bb7mBGJhTkzaJRnWAUswPzEcElVilQ2/qgwkjMgJeW7S
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 634a4408c061 ("Bluetooth: btmtk: validate WMT event SKB length
before struct access") added strict SKB length checks to prevent OOB
memory reads when parsing WMT events.

However, when enabling the protocol (flag = 0), the MT7922 returns a WMT
event with a zero-length payload (skb->len == 7), omitting the 2-byte
status field entirely.

The strict sizeof() check unconditionally enforced the presence of the
status field for all BTMTK_WMT_FUNC_CTRL events. This caused the driver
to reject these payload-less responses with -EINVAL, failing Bluetooth
initialization ("Failed to send wmt func ctrl (-22)").

Fix this by making skb_pull_data() conditional: if the status payload is
present, parse it as before; if omitted, default to BTMTK_WMT_ON_UNDONE.
This restores the pre-regression initialization behavior while
maintaining the memory safety bounds of the previous patch.

Fixes: 634a4408c061 ("Bluetooth: btmtk: validate WMT event SKB length before struct access")
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221511
Cc: stable@vger.kernel.org
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Tested on a laptop with a single MediaTek MT7922 (USB ID 0489:e0e0)
Bluetooth controller. Before this patch, Bluetooth initialization failed
with "Failed to send wmt func ctrl (-22)" on every boot. After applying
this patch, initialization succeeds reliably.

This regression is also reported by other users on the kernel bug
tracker [1].

Note: btmtksdio.c and btmtkuart.c have similar FUNC_CTRL parsing code
but were not modified by the original commit 634a4408c061, so they are
not affected by this regression and do not require changes.

[1] https://bugzilla.kernel.org/show_bug.cgi?id=221511
---
 drivers/bluetooth/btmtk.c | 24 ++++++++++++------------
 1 file changed, 12 insertions(+), 12 deletions(-)

diff --git a/drivers/bluetooth/btmtk.c b/drivers/bluetooth/btmtk.c
index f70c1b0f8990..026e5a76b086 100644
--- a/drivers/bluetooth/btmtk.c
+++ b/drivers/bluetooth/btmtk.c
@@ -717,19 +717,19 @@ static int btmtk_usb_hci_wmt_sync(struct hci_dev *hdev,
 			status = BTMTK_WMT_PATCH_DONE;
 		break;
 	case BTMTK_WMT_FUNC_CTRL:
-		if (!skb_pull_data(data->evt_skb,
-				   sizeof(wmt_evt_funcc->status))) {
-			err = -EINVAL;
-			goto err_free_skb;
-		}
-
-		wmt_evt_funcc = (struct btmtk_hci_wmt_evt_funcc *)wmt_evt;
-		if (be16_to_cpu(wmt_evt_funcc->status) == 0x404)
-			status = BTMTK_WMT_ON_DONE;
-		else if (be16_to_cpu(wmt_evt_funcc->status) == 0x420)
-			status = BTMTK_WMT_ON_PROGRESS;
-		else
+		if (skb_pull_data(data->evt_skb,
+				  sizeof(wmt_evt_funcc->status))) {
+			wmt_evt_funcc =
+				(struct btmtk_hci_wmt_evt_funcc *)wmt_evt;
+			if (be16_to_cpu(wmt_evt_funcc->status) == 0x404)
+				status = BTMTK_WMT_ON_DONE;
+			else if (be16_to_cpu(wmt_evt_funcc->status) == 0x420)
+				status = BTMTK_WMT_ON_PROGRESS;
+			else
+				status = BTMTK_WMT_ON_UNDONE;
+		} else {
 			status = BTMTK_WMT_ON_UNDONE;
+		}
 		break;
 	case BTMTK_WMT_PATCH_DWNLD:
 		if (wmt_evt->whdr.flag == 2)

---
base-commit: 5d6919055dec134de3c40167a490f33c74c12581
change-id: 20260514-bluetooh-fix-mt7922-92bbbeff229b

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

