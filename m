From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:37 +0200
Subject: [PATCH v2 14/22] thunderbolt: Add ring_interrupt_mask to
 tb_nhi_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-14-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Joshua Peisach <jpeisach@ubuntu.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2895; i=sven@kernel.org;
 h=from:subject:message-id; bh=HJ+d/OZeUWUlC39b4Bp/Qj2ekR0RdTWk6ov7g7kvJNs=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTYc7mz+onjuQkXho1qyMPy25X0QY17553XrW4NOmW
 70CO84v6ChlYRDjYpAVU2TZvt/e9MnDN4JLN116DzOHlQlkCAMXpwBMRKSBkaH7/IFlj6xPnTkq
 9pwn18Lc5k7o5uW+35YfzHt9btpbwbClDP+rI3I2f2J+0noriu2N1umZYt0911bwxjzx01GJ/eV
 6RpcHAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Masking ring interrupts works differently on the Apple NHI as well. Add
an optional tb_nhi_ops hook for it which falls back to the standard
USB4 NHI method when it is not set.

Signed-off-by: Sven Peter <sven@kernel.org>
Reviewed-by: Joshua Peisach <jpeisach@ubuntu.com>
---
 drivers/thunderbolt/nhi.c | 12 ++++++++++--
 drivers/thunderbolt/nhi.h |  4 ++++
 2 files changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/thunderbolt/nhi.c b/drivers/thunderbolt/nhi.c
index 1b1e4a12c744..4ef86e7c0285 100644
--- a/drivers/thunderbolt/nhi.c
+++ b/drivers/thunderbolt/nhi.c
@@ -427,6 +427,14 @@ static void __ring_interrupt_mask(struct tb_ring *ring, bool mask)
 	iowrite32(val, ring->nhi->iobase + reg);
 }
 
+static void nhi_ring_interrupt_mask(struct tb_ring *ring, bool mask)
+{
+	if (ring->nhi->ops->ring_interrupt_mask)
+		ring->nhi->ops->ring_interrupt_mask(ring, mask);
+	else
+		__ring_interrupt_mask(ring, mask);
+}
+
 /* Both @nhi->lock and @ring->lock should be held */
 static void __ring_interrupt(struct tb_ring *ring)
 {
@@ -434,7 +442,7 @@ static void __ring_interrupt(struct tb_ring *ring)
 		return;
 
 	if (ring->start_poll) {
-		__ring_interrupt_mask(ring, true);
+		nhi_ring_interrupt_mask(ring, true);
 		ring->start_poll(ring->poll_data);
 	} else {
 		schedule_work(&ring->work);
@@ -455,7 +463,7 @@ void tb_ring_poll_complete(struct tb_ring *ring)
 	spin_lock_irqsave(&ring->nhi->lock, flags);
 	spin_lock(&ring->lock);
 	if (ring->start_poll)
-		__ring_interrupt_mask(ring, false);
+		nhi_ring_interrupt_mask(ring, false);
 	spin_unlock(&ring->lock);
 	spin_unlock_irqrestore(&ring->nhi->lock, flags);
 }
diff --git a/drivers/thunderbolt/nhi.h b/drivers/thunderbolt/nhi.h
index 3a963b0b5b46..ca3eddf862e0 100644
--- a/drivers/thunderbolt/nhi.h
+++ b/drivers/thunderbolt/nhi.h
@@ -59,6 +59,9 @@ extern const struct dev_pm_ops nhi_pm_ops;
  * @ring_interrupt_active: NHI specific hook to activate/deactivate the
  *			   interrupt of a single ring. If not set the
  *			   standard USB4 NHI registers are used.
+ * @ring_interrupt_mask: NHI specific hook to mask/unmask the interrupt of a
+ *			 single ring. If not set the standard USB4 NHI
+ *			 registers are used.
  * @is_present: Whether the device is currently present on the parent bus
  * @init_interrupts: NHI specific interrupt initialization hook
  * @reset_interface: Resets the host interface
@@ -77,6 +80,7 @@ struct tb_nhi_ops {
 	void __iomem *(*ring_desc_base)(struct tb_ring *ring);
 	void __iomem *(*ring_options_base)(struct tb_ring *ring);
 	void (*ring_interrupt_active)(struct tb_ring *ring, bool active);
+	void (*ring_interrupt_mask)(struct tb_ring *ring, bool mask);
 	bool (*is_present)(struct tb_nhi *nhi);
 	int (*init_interrupts)(struct tb_nhi *nhi);
 	void (*reset_interface)(struct tb_nhi *nhi);

-- 
2.55.0

