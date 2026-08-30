From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:32 +0200
Subject: [PATCH 14/19] thunderbolt: Add QUIRK_NO_USB3_BW_ALLOC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-14-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6302; i=sven@kernel.org;
 h=from:subject:message-id; bh=CLLkwaKc5+f6XimwNr2nFpZ5Q46wgtKFW0n8D5ES48U=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCZFXxd52NOy6O3+rhHf7b8Zn96es63pjJvfO+MAaT
 7k0N7cPHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJvJFi+J95pnbHDNugN8/z
 30z0mJf6+E5Sr1+o/B7HPk2XKWfeJ+5k+GfA1O9dtihRJvuAyu0tViwdE3nDN28+EMj4Y9ufg1u
 6tvICAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The host routers on Apple Silicon do not implement USB3 bandwidth
allocation registers: the CMR bit set in ADP_USB3_CS_2 by
usb4_usb3_port_cm_request() is never acknowledged and every USB3 tunnel
bringup fails there after the timeout:

  [   49.259325] thunderbolt-apple-nhi 501f00000.nhi: 1:16: available bandwidth for new USB3 tunnel 18000/18000 Mb/s
  [   49.265869] thunderbolt-apple-nhi 501f00000.nhi: 1:16: maximum required bandwidth for USB3 tunnel 9000 Mb/s
  [   49.267894] thunderbolt-apple-nhi 501f00000.nhi: 0:4 <-> 1:16 (USB3): activating
  [   49.269410] thunderbolt-apple-nhi 501f00000.nhi: 0:4 <-> 1:16 (USB3): allocating initial bandwidth 9000/9000 Mb/s
  [   50.771764] thunderbolt-apple-nhi 501f00000.nhi: 1:16: USB3 tunnel activation failed, aborting

Add a quirk to skip bandwidth allocation entirely but keep tracking
the initial allocation in software for the consumed bandwidth
calculation. For completeness, discovered tunnels book 90% of the
maximum link rate in software, matching tb_tunnel_alloc_usb3(), although
Apple Silicon cannot have any pre-existing tunnels.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/nhi.h    |  1 +
 drivers/thunderbolt/tb.c     |  8 ++++++
 drivers/thunderbolt/tb.h     |  3 +++
 drivers/thunderbolt/tunnel.c | 59 +++++++++++++++++++++++++++++---------------
 4 files changed, 51 insertions(+), 20 deletions(-)

diff --git a/drivers/thunderbolt/nhi.h b/drivers/thunderbolt/nhi.h
index c2d16ab6994e..afd9a11489a9 100644
--- a/drivers/thunderbolt/nhi.h
+++ b/drivers/thunderbolt/nhi.h
@@ -169,6 +169,7 @@ struct tb_nhi_ops {
 #define QUIRK_E2E					BIT(1)
 #define QUIRK_RESET_DMA_ON_TEARDOWN			BIT(2)
 #define QUIRK_NO_DMA_PORT				BIT(3)
+#define QUIRK_NO_USB3_BW_ALLOC				BIT(4)
 
 /*
  * Minimal number of vectors when we use MSI-X. Two for control channel
diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index c43cdd2c2e2e..7ab53a30fe30 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -3044,6 +3044,14 @@ static int tb_start(struct tb *tb, bool reset)
 	 */
 	tb->root_switch->no_dma_port = tb->nhi->quirks & QUIRK_NO_DMA_PORT;
 
+	/*
+	 * Apple Silicon host routers do not implement the USB3 bandwidth
+	 * allocation registers: the CMR/HCA handshake is never acked and
+	 * times out. Bandwidth for USB3 tunnels is only booked in software
+	 * on these machines.
+	 */
+	tb->root_switch->no_usb3_bw_alloc = tb->nhi->quirks & QUIRK_NO_USB3_BW_ALLOC;
+
 	ret = tb_switch_configure(tb->root_switch);
 	if (ret) {
 		tb_switch_put(tb->root_switch);
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index 0977cd690d7e..530b0e6c3a11 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -140,6 +140,8 @@ struct tb_switch_tmu {
  * @nvm: Pointer to the NVM if the switch has one (%NULL otherwise)
  * @no_nvm_upgrade: Prevent NVM upgrade of this switch
  * @no_dma_port: Prevent adding the DMA port of this switch
+ * @no_usb3_bw_alloc: Host router does not implement the USB3 bandwidth
+ *		      allocation registers (ADP_USB3_CS_1..4)
  * @safe_mode: The switch is in safe-mode
  * @boot: Whether the switch was already authorized on boot or not
  * @rpm: The switch supports runtime PM
@@ -196,6 +198,7 @@ struct tb_switch {
 	struct tb_nvm *nvm;
 	bool no_nvm_upgrade;
 	bool no_dma_port;
+	bool no_usb3_bw_alloc;
 	bool safe_mode;
 	bool boot;
 	bool rpm;
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 7e8284575dff..9178120a6b66 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -2268,24 +2268,40 @@ struct tb_tunnel *tb_tunnel_discover_usb3(struct tb *tb, struct tb_port *down,
 	if (!tb_route(down->sw)) {
 		int ret;
 
-		/*
-		 * Read the initial bandwidth allocation for the first
-		 * hop tunnel.
-		 */
-		ret = usb4_usb3_port_allocated_bandwidth(down,
-			&tunnel->allocated_up, &tunnel->allocated_down);
-		if (ret)
-			goto err_deactivate;
+		tunnel->consumed_bandwidth = tb_usb3_consumed_bandwidth;
+
+		if (down->sw->no_usb3_bw_alloc) {
+			/*
+			 * The host router does not implement the bandwidth
+			 * allocation registers and nothing can be read back
+			 * here. Book 90% of the maximum link rate in software
+			 * instead.
+			 */
+			ret = tb_usb3_max_link_rate(tunnel->dst_port, down);
+			if (ret < 0)
+				goto err_deactivate;
+
+			tunnel->allocated_up = ret * 90 / 100;
+			tunnel->allocated_down = tunnel->allocated_up;
+		} else {
+			/*
+			 * Read the initial bandwidth allocation for the first
+			 * hop tunnel.
+			 */
+			ret = usb4_usb3_port_allocated_bandwidth(down,
+				&tunnel->allocated_up, &tunnel->allocated_down);
+			if (ret)
+				goto err_deactivate;
+
+			tunnel->pre_activate = tb_usb3_pre_activate;
+			tunnel->release_unused_bandwidth =
+				tb_usb3_release_unused_bandwidth;
+			tunnel->reclaim_available_bandwidth =
+				tb_usb3_reclaim_available_bandwidth;
+		}
 
 		tb_tunnel_dbg(tunnel, "currently allocated bandwidth %d/%d Mb/s\n",
 			      tunnel->allocated_up, tunnel->allocated_down);
-
-		tunnel->pre_activate = tb_usb3_pre_activate;
-		tunnel->consumed_bandwidth = tb_usb3_consumed_bandwidth;
-		tunnel->release_unused_bandwidth =
-			tb_usb3_release_unused_bandwidth;
-		tunnel->reclaim_available_bandwidth =
-			tb_usb3_reclaim_available_bandwidth;
 	}
 
 	tb_tunnel_dbg(tunnel, "discovered\n");
@@ -2365,12 +2381,15 @@ struct tb_tunnel *tb_tunnel_alloc_usb3(struct tb *tb, struct tb_port *up,
 		tunnel->allocated_up = min(max_rate, max_up);
 		tunnel->allocated_down = min(max_rate, max_down);
 
-		tunnel->pre_activate = tb_usb3_pre_activate;
 		tunnel->consumed_bandwidth = tb_usb3_consumed_bandwidth;
-		tunnel->release_unused_bandwidth =
-			tb_usb3_release_unused_bandwidth;
-		tunnel->reclaim_available_bandwidth =
-			tb_usb3_reclaim_available_bandwidth;
+
+		if (!down->sw->no_usb3_bw_alloc) {
+			tunnel->pre_activate = tb_usb3_pre_activate;
+			tunnel->release_unused_bandwidth =
+				tb_usb3_release_unused_bandwidth;
+			tunnel->reclaim_available_bandwidth =
+				tb_usb3_reclaim_available_bandwidth;
+		}
 	}
 
 	return tunnel;

-- 
2.55.0

