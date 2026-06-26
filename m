From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 26 Jun 2026 08:35:19 -0700
Subject: [PATCH net v2 2/2] net: ethernet: oa_tc6: Improvement in buffer
 overflow handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260626-fix-race-condition-and-crash-v2-2-b6c5c10e604f@onsemi.com>
References: <20260626-fix-race-condition-and-crash-v2-0-b6c5c10e604f@onsemi.com>
In-Reply-To: <20260626-fix-race-condition-and-crash-v2-0-b6c5c10e604f@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrew Lunn <andrew@lunn.ch>, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782488122; l=6189;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=vzS9RJeOBdUQy3PCfwKdvl0EddpgK2jpfjFglDZ/fH0=;
 b=grrPHh/Fp0ZPlhRIWryDtaZsMAGzEhOeGzs7+WmBRbVtFGX6j1Xx6NhJeNRQ9zDG1sAvgSh/f
 E8qaV7txLhjB9m1jUK2jUjP8UKGq4aGka+k9dQFPH2cpd3+NFuVH86I
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When oversubscribed traffic causes lot of buffer overflow errors,
probably due to loss of data chunks, driver fails to find a
data chunk with end_valid bit set, before it runs out of sk buffer
space. As a result, assert is seen during skb_put.

Now check is made if tail + len > end, driver abandons the current
data and starts look for a data chunk with start_valid bit,
that is a new frame.

Fixes: d70a0d8f2f2d ("net: ethernet: oa_tc6: implement receive path to receive rx ethernet frames")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v2
  - Check rx_skb pointer before new allocation and NULL before use.
---
 drivers/net/ethernet/oa_tc6.c | 69 +++++++++++++++++++++++++++++++------------
 1 file changed, 50 insertions(+), 19 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 3fd4851ee66d..c59daa032e70 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -692,6 +692,12 @@ static void oa_tc6_free_pending_skbs(struct oa_tc6 *tc6)
 	oa_tc6_cleanup_waiting_tx_skb(tc6);
 }
 
+static void oa_tc6_look_for_new_frame(struct oa_tc6 *tc6)
+{
+	tc6->rx_buf_overflow = true;
+	oa_tc6_cleanup_ongoing_rx_skb(tc6);
+}
+
 /* If the failure is at SPI interface level, masking and clearing
  * the interrupt of the device won't work. Since SPI interrupt is
  * disabled, it should stop the repeated interrupts.
@@ -729,8 +735,7 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 	}
 
 	if (FIELD_GET(STATUS0_RX_BUFFER_OVERFLOW_ERROR, value)) {
-		tc6->rx_buf_overflow = true;
-		oa_tc6_cleanup_ongoing_rx_skb(tc6);
+		oa_tc6_look_for_new_frame(tc6);
 		net_err_ratelimited("%s: Receive buffer overflow error\n",
 				    tc6->netdev->name);
 		return -EAGAIN;
@@ -811,13 +816,35 @@ static void oa_tc6_submit_rx_skb(struct oa_tc6 *tc6)
 	tc6->rx_skb = NULL;
 }
 
-static void oa_tc6_update_rx_skb(struct oa_tc6 *tc6, u8 *payload, u8 length)
+/* On oversubscribed traffic condition, particularly with overwhelming rx
+ * buffer overflow errors, there could be data chunk loss. If tail + length
+ * goes beyond end pointer, that is an indication that the data chunk with
+ * end_valid bit is lost. Time to look for a data chunk with start_valid bit.
+ *
+ * If rx_skb is NULL, it is time to start looking for data chunk with
+ * start_bit.
+ */
+static int oa_tc6_update_rx_skb(struct oa_tc6 *tc6, u8 *payload, u8 length)
 {
+	if (!tc6->rx_skb ||
+	    (tc6->rx_skb->tail + length) > tc6->rx_skb->end) {
+		oa_tc6_look_for_new_frame(tc6);
+		return -EAGAIN;
+	}
+
 	memcpy(skb_put(tc6->rx_skb, length), payload, length);
+	return 0;
 }
 
+/* On overwhelming rx buffer overflow errors, due to data chunk loss, it is
+ * possible that we get two data chunks with start_valid bit set, without
+ * end_valid bit set in between. In this case, rx_skb would have a valid
+ * buffer pointer. We should release, if a valid pointer is found before
+ * allocating a new one.
+ */
 static int oa_tc6_allocate_rx_skb(struct oa_tc6 *tc6)
 {
+	oa_tc6_cleanup_ongoing_rx_skb(tc6);
 	tc6->rx_skb = netdev_alloc_skb_ip_align(tc6->netdev, tc6->netdev->mtu +
 						ETH_HLEN + ETH_FCS_LEN);
 	if (!tc6->rx_skb) {
@@ -837,7 +864,9 @@ static int oa_tc6_prcs_complete_rx_frame(struct oa_tc6 *tc6, u8 *payload,
 	if (ret)
 		return ret;
 
-	oa_tc6_update_rx_skb(tc6, payload, size);
+	ret = oa_tc6_update_rx_skb(tc6, payload, size);
+	if (ret)
+		return ret;
 
 	oa_tc6_submit_rx_skb(tc6);
 
@@ -852,22 +881,24 @@ static int oa_tc6_prcs_rx_frame_start(struct oa_tc6 *tc6, u8 *payload, u16 size)
 	if (ret)
 		return ret;
 
-	oa_tc6_update_rx_skb(tc6, payload, size);
-
-	return 0;
+	return oa_tc6_update_rx_skb(tc6, payload, size);
 }
 
-static void oa_tc6_prcs_rx_frame_end(struct oa_tc6 *tc6, u8 *payload, u16 size)
+static int oa_tc6_prcs_rx_frame_end(struct oa_tc6 *tc6, u8 *payload, u16 size)
 {
-	oa_tc6_update_rx_skb(tc6, payload, size);
+	int ret;
 
-	oa_tc6_submit_rx_skb(tc6);
+	ret = oa_tc6_update_rx_skb(tc6, payload, size);
+	if (!ret)
+		oa_tc6_submit_rx_skb(tc6);
+	return ret;
 }
 
-static void oa_tc6_prcs_ongoing_rx_frame(struct oa_tc6 *tc6, u8 *payload,
-					 u32 footer)
+static int oa_tc6_prcs_ongoing_rx_frame(struct oa_tc6 *tc6, u8 *payload,
+					u32 footer)
 {
-	oa_tc6_update_rx_skb(tc6, payload, OA_TC6_CHUNK_PAYLOAD_SIZE);
+	return oa_tc6_update_rx_skb(tc6, payload,
+				    OA_TC6_CHUNK_PAYLOAD_SIZE);
 }
 
 static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
@@ -880,6 +911,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	bool start_valid = FIELD_GET(OA_TC6_DATA_FOOTER_START_VALID, footer);
 	bool end_valid = FIELD_GET(OA_TC6_DATA_FOOTER_END_VALID, footer);
 	u16 size;
+	int ret;
 
 	/* Restart the new rx frame after receiving rx buffer overflow error */
 	if (start_valid && tc6->rx_buf_overflow)
@@ -907,8 +939,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	/* Process the chunk with only rx frame end */
 	if (end_valid && !start_valid) {
 		size = end_byte_offset + 1;
-		oa_tc6_prcs_rx_frame_end(tc6, data, size);
-		return 0;
+		return oa_tc6_prcs_rx_frame_end(tc6, data, size);
 	}
 
 	/* Process the chunk with previous rx frame end and next rx frame
@@ -921,7 +952,9 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		 */
 		if (tc6->rx_skb) {
 			size = end_byte_offset + 1;
-			oa_tc6_prcs_rx_frame_end(tc6, data, size);
+			ret = oa_tc6_prcs_rx_frame_end(tc6, data, size);
+			if (ret)
+				return ret;
 		}
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
@@ -930,9 +963,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	}
 
 	/* Process the chunk with ongoing rx frame data */
-	oa_tc6_prcs_ongoing_rx_frame(tc6, data, footer);
-
-	return 0;
+	return oa_tc6_prcs_ongoing_rx_frame(tc6, data, footer);
 }
 
 static u32 oa_tc6_get_rx_chunk_footer(struct oa_tc6 *tc6, u16 footer_offset)

-- 
2.43.0

