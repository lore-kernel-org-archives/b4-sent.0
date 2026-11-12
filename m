From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 12 Nov 2026 10:04:49 +0000
Subject: [PATCH net 2/2] nfc: st21nfca: Free the ATR_REQ skb after sending
 it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-nfc-v1-2-ab0ef166f382@gmail.com>
References: <20261112-nfc-v1-0-ab0ef166f382@gmail.com>
In-Reply-To: <20261112-nfc-v1-0-ab0ef166f382@gmail.com>
To: netdev@vger.kernel.org, david@ixit.cz
Cc: edumazet@kernel.org, kuba@kernel.org, horms@kernel.org, 
 oe-linux-nfc@lists.linux.dev, linux-kernel@vger.kernel.org, 
 pabeni@redhat.com, davem@davemloft.net
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794477891; l=2188;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=+RGyFbOPiqFDpQv7ZHyszj7XEOri6aHfSCc39zfhtRs=;
 b=v4Q5/lkOcsxVMVNcmaaspSv/zDgC3XTBcWhvnWhrbELGF9dTgrptheGZdcFIJhpfGv6haKGzY
 uI2rZzK9QrzD68wZ9yNInIGzjnqBilkb6ThDTTqi+GTfybqECLuKdLU
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

st21nfca_im_send_atr_req() allocates an skb for the ATR_REQ, passes
its data to the HCI layer and then forgets about it:

    return nfc_hci_send_cmd_async(hdev, ST21NFCA_RF_READER_F_GATE,
                            ST21NFCA_WR_XCHG_DATA, skb->data,
                            skb->len, info->async_cb, info);

nfc_hci_send_cmd_async() copies the payload into its own fragments, so
the skb is still ours to free. As it is, one skb leaks on every ATR_REQ
sent in initiator mode, whether or not the command was queued.

Free it right after the call, on success and on error, as
st21nfca_tx_work() does for the same call.

Found with a static analysis tool and checked by hand.

Fixes: 1892bf844ea0 ("NFC: st21nfca: Adding P2P support to st21nfca in Initiator & Target mode")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested only, I don't have ST21NFCA hardware.
---
 drivers/nfc/st21nfca/dep.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/nfc/st21nfca/dep.c b/drivers/nfc/st21nfca/dep.c
index a5fab4fd5129..4b9054eb0208 100644
--- a/drivers/nfc/st21nfca/dep.c
+++ b/drivers/nfc/st21nfca/dep.c
@@ -496,6 +496,7 @@ int st21nfca_im_send_atr_req(struct nfc_hci_dev *hdev, u8 *gb, size_t gb_len)
 	struct st21nfca_atr_req *atr_req;
 	struct nfc_target *target;
 	uint size;
+	int r;
 
 	info->dep_info.to = ST21NFCA_DEFAULT_TIMEOUT;
 	size = ST21NFCA_ATR_REQ_MIN_SIZE + gb_len;
@@ -547,9 +548,11 @@ int st21nfca_im_send_atr_req(struct nfc_hci_dev *hdev, u8 *gb, size_t gb_len)
 	info->dep_info.bsi = atr_req->bsi;
 	info->dep_info.lri = ST21NFCA_PP2LRI(atr_req->ppi);
 
-	return nfc_hci_send_cmd_async(hdev, ST21NFCA_RF_READER_F_GATE,
-				ST21NFCA_WR_XCHG_DATA, skb->data,
-				skb->len, info->async_cb, info);
+	r = nfc_hci_send_cmd_async(hdev, ST21NFCA_RF_READER_F_GATE,
+				   ST21NFCA_WR_XCHG_DATA, skb->data,
+				   skb->len, info->async_cb, info);
+	kfree_skb(skb);
+	return r;
 }
 EXPORT_SYMBOL(st21nfca_im_send_atr_req);
 

-- 
2.34.1

