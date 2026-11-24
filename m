From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 24 Nov 2026 14:09:56 -0800
Subject: [PATCH net-next v12 08/15] net: ethernet: oa_tc6: Drop frames if
 footer has FD bit set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-s2500-mac-phy-support-v12-8-3575855d99f9@onsemi.com>
References: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
In-Reply-To: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=4215;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=XqxMwrK8ddh74xl2LU015nOeiMaCu6QPfhk3MBif/Ns=;
 b=BMw+MULnLVlNG8N1eKelv7uv1qbc/U6urneAy8SHipuSfQ0C2E/kHw4aVopHIG895UJgo14Ia
 EeIxhmILrJ4AtbwRK7yLny1EIEwD9/2n14AGJRKavazTdo4sZMm0wbL
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop a receive frame when the data footer of its last chunk has
the Frame Drop (FD) bit set, as required by the OPEN Alliance
specification. The dropped frame is counted in rx_errors.

Here is one scenario when FD bit will be set. With RX cut-through
enabled, the MAC-PHY can start forwarding a frame before it knows
the frame is bad, and uses FD to tell the host to discard it.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v12
  - Moved the OA_TC6_DATA_FOOTER_FRAME_DROP bit definition to this
    patch as this is the patch where it is used.
  - Dropped frames are counted in rx_errors.
changes in v11
  - Act on FD bit on the footer in the received data chunk.
  - New patch in v11
---
 Documentation/networking/oa-tc6-framework.rst |  5 +++++
 drivers/net/ethernet/oa_tc6/oa_tc6_main.c     | 24 ++++++++++++++++++++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h  |  1 +
 3 files changed, 30 insertions(+)

diff --git a/Documentation/networking/oa-tc6-framework.rst b/Documentation/networking/oa-tc6-framework.rst
index 2df8455bf3ba..390529419133 100644
--- a/Documentation/networking/oa-tc6-framework.rst
+++ b/Documentation/networking/oa-tc6-framework.rst
@@ -324,6 +324,11 @@ FD (Bit 15) - Frame Drop. When set, this bit indicates that the MAC has
               of a received Ethernet frame (EV = 1) and shall be zero at
               all other times.
 
+              The framework accounts for frames it discards in response
+              to FD in ``rx_errors`` rather than ``rx_dropped``.
+              A partial frame already discarded during receive recovery
+              is not counted again when its FD footer arrives.
+
 EV (Bit 14) - End Valid flag. The MAC-PHY sets this bit when the end of a
               received Ethernet frame is present in this receive data
               chunk payload.
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
index 22aaecd814ec..c69ed576b41d 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
@@ -1173,6 +1173,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 				       footer);
 	bool start_valid = FIELD_GET(OA_TC6_DATA_FOOTER_START_VALID, footer);
 	bool end_valid = FIELD_GET(OA_TC6_DATA_FOOTER_END_VALID, footer);
+	bool frame_drop = FIELD_GET(OA_TC6_DATA_FOOTER_FRAME_DROP, footer);
 	u16 size;
 
 	/* Restart the new rx frame after receiving rx buffer overflow error */
@@ -1182,6 +1183,29 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 	if (tc6->wait_until_start_valid)
 		return 0;
 
+	/* Drop the frame, if footer sets FD bit. Checking FD bit
+	 * becomes important, when cut-through operation is enabled.
+	 */
+	if (end_valid && frame_drop) {
+		/* Any buffered frame precedes this complete frame. */
+		if (start_valid && start_byte_offset < end_byte_offset) {
+			tc6->netdev->stats.rx_errors++;
+			oa_tc6_cleanup_ongoing_rx_skb(tc6);
+			return 0;
+		}
+
+		/* Recovery may have already discarded the buffered frame. */
+		if (tc6->rx_skb) {
+			tc6->netdev->stats.rx_errors++;
+			dev_kfree_skb_any(tc6->rx_skb);
+			tc6->rx_skb = NULL;
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
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index e93440447516..014b48e7e27d 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -50,6 +50,7 @@
 #define OA_TC6_DATA_FOOTER_DATA_VALID		BIT(21)
 #define OA_TC6_DATA_FOOTER_START_VALID		BIT(20)
 #define OA_TC6_DATA_FOOTER_START_WORD_OFFSET	GENMASK(19, 16)
+#define OA_TC6_DATA_FOOTER_FRAME_DROP		BIT(15)
 #define OA_TC6_DATA_FOOTER_END_VALID		BIT(14)
 #define OA_TC6_DATA_FOOTER_RTSA_VALID		BIT(7)
 #define OA_TC6_DATA_FOOTER_RTSP_VALID		BIT(6)

-- 
2.43.0

