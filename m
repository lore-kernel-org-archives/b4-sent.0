From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 20 Jul 2026 19:20:36 -0700
Subject: [PATCH net v4 2/3] net: ethernet: oa_tc6: Improvements to error
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-fix-race-condition-and-crash-v4-2-8273e2f38a1f@onsemi.com>
References: <20260720-fix-race-condition-and-crash-v4-0-8273e2f38a1f@onsemi.com>
In-Reply-To: <20260720-fix-race-condition-and-crash-v4-0-8273e2f38a1f@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784600442; l=9964;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=pJcLfH5O90O7Cb0UUGzAZb2XuohihqZvY8cxmSkb95I=;
 b=hrjej8TxikFOAPdAw7Q+Aqp+VZ/B04yzxdZ35SKHmQexUsaGzOgknMCc6WJRdrftOQtvGx/jT
 9RMVdaBQce5CdYs+Kj8o2SeRANEGHJAT/Zdnxs4Ibroq7oBXLQjJ+cR
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

SK buffer allocation error is considered as recoverable error.

Fixes: d70a0d8f2f2d ("net: ethernet: oa_tc6: implement receive path to receive rx ethernet frames")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v4
  - rx_buf_overflow flag cleared, when end of frame and start of
    frame are handled in the same data chunk.
  - Added more comments to answer some of the AI review questions.
changes in v3
  - Continue processing more chunks on error code -EAGAIN. Previously
    we were bailing out.
changes in v2
  - Check rx_skb pointer before new allocation and NULL before use.
---
 drivers/net/ethernet/oa_tc6.c | 131 ++++++++++++++++++++++++++++++++----------
 1 file changed, 100 insertions(+), 31 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 5b24cce4f9b5..9e6850ccfe6c 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -710,6 +710,12 @@ static void oa_tc6_free_pending_skbs(struct oa_tc6 *tc6)
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
@@ -753,8 +759,7 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 	}
 
 	if (FIELD_GET(STATUS0_RX_BUFFER_OVERFLOW_ERROR, value)) {
-		tc6->rx_buf_overflow = true;
-		oa_tc6_cleanup_ongoing_rx_skb(tc6);
+		oa_tc6_look_for_new_frame(tc6);
 		net_err_ratelimited("%s: Receive buffer overflow error\n",
 				    tc6->netdev->name);
 		return -EAGAIN;
@@ -780,6 +785,8 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 
 static int oa_tc6_process_rx_chunk_footer(struct oa_tc6 *tc6, u32 footer)
 {
+	int ret = 0;
+
 	/* Process rx chunk footer for the following,
 	 * 1. tx credits
 	 * 2. errors if any from MAC-PHY
@@ -790,9 +797,11 @@ static int oa_tc6_process_rx_chunk_footer(struct oa_tc6 *tc6, u32 footer)
 					     footer);
 
 	if (FIELD_GET(OA_TC6_DATA_FOOTER_EXTENDED_STS, footer)) {
-		int ret = oa_tc6_process_extended_status(tc6);
-
-		if (ret)
+		ret = oa_tc6_process_extended_status(tc6);
+		/* EAGAIN error is recoverable. Move on to check
+		 * HEADER and SYNC errors before returning.
+		 */
+		if (ret && ret != -EAGAIN)
 			return ret;
 	}
 
@@ -810,7 +819,7 @@ static int oa_tc6_process_rx_chunk_footer(struct oa_tc6 *tc6, u32 footer)
 		return -ENODEV;
 	}
 
-	return 0;
+	return ret;
 }
 
 static void oa_tc6_submit_rx_skb(struct oa_tc6 *tc6)
@@ -835,13 +844,35 @@ static void oa_tc6_submit_rx_skb(struct oa_tc6 *tc6)
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
@@ -861,7 +892,9 @@ static int oa_tc6_prcs_complete_rx_frame(struct oa_tc6 *tc6, u8 *payload,
 	if (ret)
 		return ret;
 
-	oa_tc6_update_rx_skb(tc6, payload, size);
+	ret = oa_tc6_update_rx_skb(tc6, payload, size);
+	if (ret)
+		return ret;
 
 	oa_tc6_submit_rx_skb(tc6);
 
@@ -876,22 +909,24 @@ static int oa_tc6_prcs_rx_frame_start(struct oa_tc6 *tc6, u8 *payload, u16 size)
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
@@ -931,8 +966,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	/* Process the chunk with only rx frame end */
 	if (end_valid && !start_valid) {
 		size = end_byte_offset + 1;
-		oa_tc6_prcs_rx_frame_end(tc6, data, size);
-		return 0;
+		return oa_tc6_prcs_rx_frame_end(tc6, data, size);
 	}
 
 	/* Process the chunk with previous rx frame end and next rx frame
@@ -946,6 +980,14 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		if (tc6->rx_skb) {
 			size = end_byte_offset + 1;
 			oa_tc6_prcs_rx_frame_end(tc6, data, size);
+
+			/* Purpose of rx_buf_overflow is make the
+			 * code to look for new frame. At this
+			 * stage, we have a new frame to process.
+			 * So, making it false, in case it is set
+			 * to true by oa_tc6_prcs_rx_frame_end.
+			 */
+			tc6->rx_buf_overflow = false;
 		}
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
@@ -954,9 +996,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	}
 
 	/* Process the chunk with ongoing rx frame data */
-	oa_tc6_prcs_ongoing_rx_frame(tc6, data, footer);
-
-	return 0;
+	return oa_tc6_prcs_ongoing_rx_frame(tc6, data, footer);
 }
 
 static u32 oa_tc6_get_rx_chunk_footer(struct oa_tc6 *tc6, u16 footer_offset)
@@ -972,8 +1012,9 @@ static u32 oa_tc6_get_rx_chunk_footer(struct oa_tc6 *tc6, u16 footer_offset)
 static int oa_tc6_process_spi_data_rx_buf(struct oa_tc6 *tc6, u16 length)
 {
 	u16 no_of_rx_chunks = length / OA_TC6_CHUNK_SIZE;
+	bool retry = false;
+	int ret = 0;
 	u32 footer;
-	int ret;
 
 	/* All the rx chunks in the receive SPI data buffer are examined here */
 	for (int i = 0; i < no_of_rx_chunks; i++) {
@@ -982,8 +1023,11 @@ static int oa_tc6_process_spi_data_rx_buf(struct oa_tc6 *tc6, u16 length)
 						    OA_TC6_CHUNK_PAYLOAD_SIZE);
 
 		ret = oa_tc6_process_rx_chunk_footer(tc6, footer);
-		if (ret)
-			return ret;
+		if (ret) {
+			if (ret != -EAGAIN)
+				return ret;
+			retry = true;
+		}
 
 		/* If there is a data valid chunks then process it for the
 		 * information needed to determine the validity and the location
@@ -995,12 +1039,35 @@ static int oa_tc6_process_spi_data_rx_buf(struct oa_tc6 *tc6, u16 length)
 
 			ret = oa_tc6_prcs_rx_chunk_payload(tc6, payload,
 							   footer);
-			if (ret)
-				return ret;
+			if (ret) {
+				if (ret != -ENOMEM && ret != -EAGAIN)
+					return ret;
+				retry = true;
+			}
 		}
 	}
 
-	return 0;
+	/* Not bailing out on recoverable error codes, -EAGAIN and
+	 * -ENOMEM. If subsequent loop iterations, if any, succeeds,
+	 * error code would be overwritten. retry flag helps to
+	 * make the caller to continue and retry. Since recovery
+	 * action for -ENOMEM and -EAGAIN are same, we are returning
+	 * one of the error codes, that is -EAGAIN.
+	 *
+	 * Successful recovery depends on how small the frames are,
+	 * how many chunks, among the received chunks triggered the
+	 * error, whether data is intact even with error conditions.
+	 * As a result, there is no single, best method to recover
+	 * most data when error conditions hit. We do our best by
+	 * processing all the chunks with good "footer header" and
+	 * "data valid" bit set.
+	 */
+	if (retry) {
+		ret = -EAGAIN;
+		oa_tc6_look_for_new_frame(tc6);
+	}
+
+	return ret;
 }
 
 static __be32 oa_tc6_prepare_data_header(bool data_valid, bool start_valid,
@@ -1162,10 +1229,12 @@ static int oa_tc6_try_spi_transfer(struct oa_tc6 *tc6)
 		}
 
 		ret = oa_tc6_process_spi_data_rx_buf(tc6, spi_len);
-		if (ret) {
-			if (ret == -EAGAIN)
-				continue;
 
+		/* Not continuing with the next iteration to give
+		 * waiting_tx_skb a chance to get drained, if
+		 * needed.
+		 */
+		if (ret && ret != -EAGAIN) {
 			oa_tc6_free_ongoing_skbs(tc6);
 			netdev_err(tc6->netdev, "Device error: %d\n", ret);
 			return ret;

-- 
2.43.0

