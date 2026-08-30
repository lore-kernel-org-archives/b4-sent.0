From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:27 +0200
Subject: [PATCH 09/19] thunderbolt: Add ring_interrupt_active to tb_nhi_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-9-44bc9348683c@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2793; i=sven@kernel.org;
 h=from:subject:message-id; bh=1cPwquxnKSbuoBJPbanbJjkiYHF/+0xe5BCBfQyNjww=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCeFL7j7fKCksv/POF1Un1f3SbnIRLtvnmzyUaEgye
 WC8ZXZcRykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiqk0M/wsXub5d2LPFX8T0
 9ZPCe6/DHhztLGNevdnQaan6B8Z3Dz4x/C948nxbwIFPfhcSuQ/J7rJ1Wxr//F7q3a+6N33dN22
 PX8cHAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Apple NHI enables and disables ring interrupts differently. Add an
optional tb_nhi_ops hook to override ring_interrupt_active which falls
back to the standard USB4 method when it is not set.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/nhi.c | 12 ++++++++++--
 drivers/thunderbolt/nhi.h |  4 ++++
 2 files changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/thunderbolt/nhi.c b/drivers/thunderbolt/nhi.c
index 6a97dcd57deb..fc54ff7edfb9 100644
--- a/drivers/thunderbolt/nhi.c
+++ b/drivers/thunderbolt/nhi.c
@@ -149,6 +149,14 @@ static void ring_interrupt_active(struct tb_ring *ring, bool active)
 		nhi_mask_interrupt(ring->nhi, mask, index);
 }
 
+static void nhi_ring_interrupt_active(struct tb_ring *ring, bool active)
+{
+	if (ring->nhi->ops->ring_interrupt_active)
+		ring->nhi->ops->ring_interrupt_active(ring, active);
+	else
+		ring_interrupt_active(ring, active);
+}
+
 /*
  * nhi_disable_interrupts() - disable interrupts for all rings
  *
@@ -724,7 +732,7 @@ void tb_ring_start(struct tb_ring *ring)
 	}
 
 	if (!(ring->flags & RING_FLAG_NO_INTERRUPT))
-		ring_interrupt_active(ring, true);
+		nhi_ring_interrupt_active(ring, true);
 	ring->running = true;
 err:
 	spin_unlock(&ring->lock);
@@ -785,7 +793,7 @@ void tb_ring_stop(struct tb_ring *ring)
 		goto err;
 	}
 	if (!(ring->flags & RING_FLAG_NO_INTERRUPT))
-		ring_interrupt_active(ring, false);
+		nhi_ring_interrupt_active(ring, false);
 
 	ring_iowrite32options(ring, 0, 0);
 	ring_iowrite64desc(ring, 0, 0);
diff --git a/drivers/thunderbolt/nhi.h b/drivers/thunderbolt/nhi.h
index f72d6b274501..4884c3f5a2b2 100644
--- a/drivers/thunderbolt/nhi.h
+++ b/drivers/thunderbolt/nhi.h
@@ -52,6 +52,9 @@ extern const struct dev_pm_ops nhi_pm_ops;
  * @post_nvm_auth: hook to run after Thunderbolt 3 NVM authentication
  * @request_ring_irq: NHI specific interrupt retrieval hook
  * @release_ring_irq: NHI specific interrupt release hook
+ * @ring_interrupt_active: NHI specific hook to activate/deactivate the
+ *			   interrupt of a single ring. If not set the
+ *			   standard USB4 NHI registers are used.
  * @is_present: Whether the device is currently present on the parent bus
  * @init_interrupts: NHI specific interrupt initialization hook
  * @reset_interface: Resets the host interface
@@ -67,6 +70,7 @@ struct tb_nhi_ops {
 	void (*post_nvm_auth)(struct tb_nhi *nhi);
 	int (*request_ring_irq)(struct tb_ring *ring, bool no_suspend);
 	void (*release_ring_irq)(struct tb_ring *ring);
+	void (*ring_interrupt_active)(struct tb_ring *ring, bool active);
 	bool (*is_present)(struct tb_nhi *nhi);
 	int (*init_interrupts)(struct tb_nhi *nhi);
 	void (*reset_interface)(struct tb_nhi *nhi);

-- 
2.55.0

