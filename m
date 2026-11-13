From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:27 -0800
Subject: [PATCH net-next v11 08/14] net: ethernet: oa_tc6: Drop frames if
 footer has FD bit set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-8-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=2179;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=dkkj9Yvy8E8XVR9o8A4wOOf+5qrIVE9onT+oIT/7Bdw=;
 b=QdWV9vCthImkHEbA7LbkU3pP2WAhkBfeV0eQmeWxBTZvloGcgSCVfEima3UVrizhjxcswM4vv
 WoQdCIRBdnzCCUkJTIS/C4AS2SaBW/BW6RYqipi8IMQZV1/5H9o1ktJ
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop a receive frame when the data footer of its last chunk has
the Frame Drop (FD) bit set. Dropping the frame with FD bit set
is in OPEN Alliance specification.

Here is one scenario when FD bit will be set. With RX cut-through
enabled, the MAC-PHY can start forwarding a frame before it knows
the frame is bad, and uses FD to tell the host to discard it.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Act on FD bit on the footer in the received data chunk.
  - New patch in v11
---
 drivers/net/ethernet/oa_tc6/oa_tc6_main.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
index 2b31370da2d2..5d01ef5a13ad 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
@@ -1150,6 +1150,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 				       footer);
 	bool start_valid = FIELD_GET(OA_TC6_DATA_FOOTER_START_VALID, footer);
 	bool end_valid = FIELD_GET(OA_TC6_DATA_FOOTER_END_VALID, footer);
+	bool frame_drop = FIELD_GET(OA_TC6_DATA_FOOTER_FRAME_DROP, footer);
 	u16 size;
 
 	/* Restart the new rx frame after receiving rx buffer overflow error */
@@ -1159,6 +1160,25 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	if (tc6->wait_until_start_valid)
 		return 0;
 
+	/* Drop the frame, if footer sets FD bit. Checking FD bit
+	 * becomes important, when cut-through operation is enabled.
+	 */
+	if (end_valid && frame_drop) {
+		oa_tc6_cleanup_ongoing_rx_skb(tc6);
+
+		/* Full frame in this chunk. Nothing to free. Move on to
+		 * next chunk.
+		 */
+		if (start_valid && start_byte_offset < end_byte_offset) {
+			tc6->netdev->stats.rx_dropped++;
+			return 0;
+		}
+
+		/* The chunk carries only the end of the dropped frame. */
+		if (!start_valid)
+			return 0;
+	}
+
 	/* Process the chunk with complete rx frame */
 	if (start_valid && end_valid && start_byte_offset < end_byte_offset) {
 		size = end_byte_offset + 1 - start_byte_offset;

-- 
2.43.0

