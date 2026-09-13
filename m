From: kimwooseok <5mghybrid@khu.ac.kr>
Date: Sun, 13 Sep 2026 16:33:22 +0900
Subject: [PATCH rtw-next v2 4/4] wifi: rtl8xxxu: test RX ownership and
 recovery across failures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-codex-rtw-rx-v2-v2-4-f09c964e0b96@khu.ac.kr>
References: <20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr>
In-Reply-To: <20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr>
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-kernel@vger.kernel.org, 
 kimwooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789284810; l=25836;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=Erw0UBHjIqZun9gdOYJ4NKEMuM8dxfGVdztYUIogd9w=;
 b=lumH2COzbqkjDC5YDPgFc9uf6dTEgDdMkIMw+LQKTDSXMvyl124PHbilXU2WXZoTMvKJL5SFX
 A7qgosoV6KNDpZHEsDWq42Xm9IJYEzdvGeA6FmrnSgyyvcaeknpodGI
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 11 KUnit cases for the RX allocation, submission, completion and
retry paths. Cover each retryable completion followed by ENOMEM/EAGAIN,
batch sizes 1, 8, 9 and 32, skb allocation failure, startup failure
positions, cancellation and shutdown.

Run the actual RX helpers and worker with task-scoped stubs for
allocation and USB submission. Observer references check that the driver
releases its URB and skb references. A delayed-work case checks that
one retry request schedules the submission worker.

Assisted-by: GPT-6 Astra
Signed-off-by: kimwooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/wireless/realtek/rtl8xxxu/.kunitconfig |  16 +
 drivers/net/wireless/realtek/rtl8xxxu/Kconfig      |  11 +
 drivers/net/wireless/realtek/rtl8xxxu/Makefile     |   3 +
 drivers/net/wireless/realtek/rtl8xxxu/core.c       |  66 ++-
 drivers/net/wireless/realtek/rtl8xxxu/rx-test.c    | 461 +++++++++++++++++++++
 drivers/net/wireless/realtek/rtl8xxxu/rx-test.h    |  27 ++
 6 files changed, 569 insertions(+), 15 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/.kunitconfig b/drivers/net/wireless/realtek/rtl8xxxu/.kunitconfig
new file mode 100644
index 0000000000000..decf383c3d51e
--- /dev/null
+++ b/drivers/net/wireless/realtek/rtl8xxxu/.kunitconfig
@@ -0,0 +1,16 @@
+CONFIG_MODULES=y
+CONFIG_KUNIT=y
+CONFIG_KUNIT_ALL_TESTS=n
+CONFIG_NET=y
+CONFIG_NETDEVICES=y
+CONFIG_WIRELESS=y
+CONFIG_CFG80211=y
+CONFIG_MAC80211=y
+CONFIG_WLAN=y
+CONFIG_WLAN_VENDOR_REALTEK=y
+CONFIG_USB_SUPPORT=y
+CONFIG_USB=y
+CONFIG_NEW_LEDS=y
+CONFIG_LEDS_CLASS=y
+CONFIG_RTL8XXXU=y
+CONFIG_RTL8XXXU_KUNIT_TEST=y
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/Kconfig b/drivers/net/wireless/realtek/rtl8xxxu/Kconfig
index 14d0343368ac0..e2c16d62293a4 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/Kconfig
+++ b/drivers/net/wireless/realtek/rtl8xxxu/Kconfig
@@ -35,3 +35,14 @@ config RTL8XXXU_UNTESTED
 	  author or reported to be working by third parties.
 
 	  Please report your results!
+
+config RTL8XXXU_KUNIT_TEST
+	tristate "KUnit tests for rtl8xxxu RX recovery" if !KUNIT_ALL_TESTS
+	depends on KUNIT && RTL8XXXU
+	default KUNIT_ALL_TESTS
+	help
+	  Exercise RX buffer ownership, startup and recovery with the real
+	  driver functions and controlled allocation and USB submission results.
+	  These tests do not require a USB adapter.
+
+	  If unsure, say N.
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/Makefile b/drivers/net/wireless/realtek/rtl8xxxu/Makefile
index 580a2fa675ee2..a592a81197857 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/Makefile
+++ b/drivers/net/wireless/realtek/rtl8xxxu/Makefile
@@ -4,3 +4,6 @@ obj-$(CONFIG_RTL8XXXU)	+= rtl8xxxu.o
 rtl8xxxu-y	:= core.o 8192e.o 8723b.o \
 		   8723a.o 8192c.o 8188f.o \
 		   8188e.o 8710b.o 8192f.o
+
+obj-$(CONFIG_RTL8XXXU_KUNIT_TEST) += rtl8xxxu-rx-test.o
+rtl8xxxu-rx-test-y := rx-test.o
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 883c9a56f52a4..323411e7f5e3b 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -17,6 +17,8 @@
 #include <linux/iopoll.h>
 #include "regs.h"
 #include "rtl8xxxu.h"
+#include "rx-test.h"
+#include <kunit/static_stub.h>
 
 #define DRIVER_NAME "rtl8xxxu"
 
@@ -60,8 +62,7 @@ MODULE_PARM_DESC(dma_agg_pages, "Set DMA aggregation pages (range 1-127, 0 to di
 #define RTL8XXXU_TX_URB_HIGH_WATER	32
 
 static void rtl8xxxu_stop(struct ieee80211_hw *hw, bool suspend);
-static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
-				  struct rtl8xxxu_rx_urb *rx_urb);
+
 
 static struct ieee80211_rate rtl8xxxu_rates[] = {
 	{ .bitrate = 10, .hw_value = DESC_RATE_1M, .flags = 0 },
@@ -5817,7 +5818,36 @@ void jaguar2_rx_parse_phystats(struct rtl8xxxu_priv *priv,
 	}
 }
 
-static void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv)
+VISIBLE_IF_KUNIT struct rtl8xxxu_rx_urb *rtl8xxxu_alloc_rx_urb(void)
+{
+	KUNIT_STATIC_STUB_REDIRECT(rtl8xxxu_alloc_rx_urb);
+	return kmalloc_obj(struct rtl8xxxu_rx_urb);
+}
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_alloc_rx_urb);
+
+VISIBLE_IF_KUNIT struct sk_buff *rtl8xxxu_alloc_rx_skb(unsigned int size)
+{
+	KUNIT_STATIC_STUB_REDIRECT(rtl8xxxu_alloc_rx_skb, size);
+	return __netdev_alloc_skb(NULL, size, GFP_KERNEL);
+}
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_alloc_rx_skb);
+
+VISIBLE_IF_KUNIT int rtl8xxxu_rx_usb_submit(struct urb *urb, gfp_t flags)
+{
+	KUNIT_STATIC_STUB_REDIRECT(rtl8xxxu_rx_usb_submit, urb, flags);
+	return usb_submit_urb(urb, flags);
+}
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_rx_usb_submit);
+
+VISIBLE_IF_KUNIT void rtl8xxxu_schedule_rx_retry(struct rtl8xxxu_priv *priv)
+{
+	KUNIT_STATIC_STUB_REDIRECT(rtl8xxxu_schedule_rx_retry, priv);
+	queue_delayed_work(system_wq, &priv->rx_urb_retry_wq,
+			   msecs_to_jiffies(RTL8XXXU_RX_URB_RETRY_DELAY_MS));
+}
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_schedule_rx_retry);
+
+VISIBLE_IF_KUNIT void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv)
 {
 	struct rtl8xxxu_rx_urb *rx_urb, *tmp;
 	unsigned long flags;
@@ -5838,15 +5868,16 @@ static void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv)
 
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_free_rx_resources);
 
-static int rtl8xxxu_alloc_rx_urbs(struct rtl8xxxu_priv *priv)
+VISIBLE_IF_KUNIT int rtl8xxxu_alloc_rx_urbs(struct rtl8xxxu_priv *priv)
 {
 	struct rtl8xxxu_rx_urb *rx_urb;
 	int i;
 
 	/* No RX work is active until the complete pool has been allocated. */
 	for (i = 0; i < RTL8XXXU_RX_URBS; i++) {
-		rx_urb = kmalloc_obj(struct rtl8xxxu_rx_urb);
+		rx_urb = rtl8xxxu_alloc_rx_urb();
 		if (!rx_urb)
 			return -ENOMEM;
 
@@ -5859,6 +5890,7 @@ static int rtl8xxxu_alloc_rx_urbs(struct rtl8xxxu_priv *priv)
 
 	return 0;
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_alloc_rx_urbs);
 
 static void rtl8xxxu_queue_rx_urb(struct rtl8xxxu_priv *priv,
 				  struct rtl8xxxu_rx_urb *rx_urb)
@@ -5887,7 +5919,7 @@ static void rtl8xxxu_queue_rx_urb(struct rtl8xxxu_priv *priv,
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
 
-static void rtl8xxxu_rx_urb_retry_work(struct work_struct *work)
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_urb_retry_work(struct work_struct *work)
 {
 	struct rtl8xxxu_priv *priv = container_of(to_delayed_work(work),
 						struct rtl8xxxu_priv,
@@ -5907,6 +5939,7 @@ static void rtl8xxxu_rx_urb_retry_work(struct work_struct *work)
 
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_rx_urb_retry_work);
 
 static void rtl8xxxu_queue_rx_urb_retry(struct rtl8xxxu_priv *priv,
 					struct rtl8xxxu_rx_urb *rx_urb)
@@ -5919,8 +5952,7 @@ static void rtl8xxxu_queue_rx_urb_retry(struct rtl8xxxu_priv *priv,
 		list_add_tail(&rx_urb->list, &priv->rx_urb_retry_list);
 		priv->rx_urb_retry_count++;
 		/* Keep normal completions from bypassing the error backoff. */
-		queue_delayed_work(system_wq, &priv->rx_urb_retry_wq,
-				   msecs_to_jiffies(RTL8XXXU_RX_URB_RETRY_DELAY_MS));
+		rtl8xxxu_schedule_rx_retry(priv);
 	} else {
 		usb_free_urb(&rx_urb->urb);
 	}
@@ -5928,7 +5960,7 @@ static void rtl8xxxu_queue_rx_urb_retry(struct rtl8xxxu_priv *priv,
 	spin_unlock_irqrestore(&priv->rx_urb_lock, flags);
 }
 
-static void rtl8xxxu_rx_urb_work(struct work_struct *work)
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_urb_work(struct work_struct *work)
 {
 	struct rtl8xxxu_priv *priv;
 	struct rtl8xxxu_rx_urb *rx_urb, *tmp;
@@ -5968,8 +6000,9 @@ static void rtl8xxxu_rx_urb_work(struct work_struct *work)
 		}
 	}
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_rx_urb_work);
 
-static int rtl8xxxu_start_rx(struct rtl8xxxu_priv *priv)
+VISIBLE_IF_KUNIT int rtl8xxxu_start_rx(struct rtl8xxxu_priv *priv)
 {
 	struct rtl8xxxu_rx_urb *rx_urb, *tmp;
 	unsigned long flags;
@@ -6006,6 +6039,7 @@ static int rtl8xxxu_start_rx(struct rtl8xxxu_priv *priv)
 	}
 	return ret;
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_start_rx);
 
 /*
  * The RTL8723BU/RTL8192EU vendor driver use coexistence table type
@@ -6646,7 +6680,7 @@ int rtl8xxxu_parse_rxdesc24(struct rtl8xxxu_priv *priv, struct sk_buff *skb)
 	return RX_TYPE_DATA_PKT;
 }
 
-static void rtl8xxxu_rx_complete(struct urb *urb)
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_complete(struct urb *urb)
 {
 	struct rtl8xxxu_rx_urb *rx_urb =
 		container_of(urb, struct rtl8xxxu_rx_urb, urb);
@@ -6686,9 +6720,10 @@ static void rtl8xxxu_rx_complete(struct urb *urb)
 	usb_free_urb(urb);
 	dev_kfree_skb(skb);
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_rx_complete);
 
-static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
-				  struct rtl8xxxu_rx_urb *rx_urb)
+VISIBLE_IF_KUNIT int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
+					    struct rtl8xxxu_rx_urb *rx_urb)
 {
 	struct rtl8xxxu_fileops *fops = priv->fops;
 	struct sk_buff *skb;
@@ -6704,7 +6739,7 @@ static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
 		skb_size = IEEE80211_MAX_FRAME_LEN + rx_desc_sz;
 	}
 
-	skb = __netdev_alloc_skb(NULL, skb_size, GFP_KERNEL);
+	skb = rtl8xxxu_alloc_rx_skb(skb_size);
 	if (!skb)
 		return -ENOMEM;
 
@@ -6712,7 +6747,7 @@ static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
 	usb_fill_bulk_urb(&rx_urb->urb, priv->udev, priv->pipe_in, skb->data,
 			  skb_size, rtl8xxxu_rx_complete, skb);
 	usb_anchor_urb(&rx_urb->urb, &priv->rx_anchor);
-	ret = usb_submit_urb(&rx_urb->urb, GFP_ATOMIC);
+	ret = rtl8xxxu_rx_usb_submit(&rx_urb->urb, GFP_ATOMIC);
 	if (ret) {
 		usb_unanchor_urb(&rx_urb->urb);
 		dev_kfree_skb(skb);
@@ -6720,6 +6755,7 @@ static int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
 	}
 	return ret;
 }
+EXPORT_SYMBOL_IF_KUNIT(rtl8xxxu_submit_rx_urb);
 
 static void rtl8xxxu_int_complete(struct urb *urb)
 {
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rx-test.c b/drivers/net/wireless/realtek/rtl8xxxu/rx-test.c
new file mode 100644
index 0000000000000..aedddcb049cdf
--- /dev/null
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rx-test.c
@@ -0,0 +1,461 @@
+// SPDX-License-Identifier: GPL-2.0-only
+#include <kunit/static_stub.h>
+#include <kunit/test.h>
+#include <linux/usb.h>
+
+#include "rtl8xxxu.h"
+#include "rx-test.h"
+
+#define RX_TEST_URBS 32
+#define RX_TEST_SKBS 512
+
+struct rx_test {
+	struct rtl8xxxu_priv priv;
+	struct ieee80211_hw hw;
+	struct rtl8xxxu_fileops fops;
+	struct usb_device udev;
+	struct rtl8xxxu_rx_urb *urbs[RX_TEST_URBS];
+	struct sk_buff *skbs[RX_TEST_SKBS];
+	unsigned int allocated;
+	unsigned int buffers;
+	unsigned int alloc_calls;
+	unsigned int alloc_fail_at;
+	unsigned int submit_calls;
+	unsigned int submit_fail_at;
+	int submit_error;
+	bool fail_skb;
+	bool retry_pending;
+	unsigned int retry_arms;
+	atomic_t normal_runs;
+};
+
+static struct rx_test *rx_current(void)
+{
+	return kunit_get_current_test()->priv;
+}
+
+static struct rtl8xxxu_rx_urb *rx_alloc_object(void)
+{
+	struct rx_test *ctx = rx_current();
+	struct rtl8xxxu_rx_urb *rx;
+
+	ctx->alloc_calls++;
+	if (ctx->alloc_calls == ctx->alloc_fail_at)
+		return NULL;
+	rx = kmalloc_obj(struct rtl8xxxu_rx_urb);
+	if (rx)
+		ctx->urbs[ctx->allocated++] = rx;
+	return rx;
+}
+
+static struct sk_buff *rx_alloc_buffer(unsigned int size)
+{
+	struct rx_test *ctx = rx_current();
+	struct sk_buff *skb;
+
+	if (ctx->fail_skb)
+		return NULL;
+	skb = alloc_skb(size, GFP_KERNEL);
+	if (skb) {
+		/* Retain an observer reference to detect a lost driver reference. */
+		skb_get(skb);
+		ctx->skbs[ctx->buffers++] = skb;
+	}
+	return skb;
+}
+
+static int rx_submit(struct urb *urb, gfp_t flags)
+{
+	struct rx_test *ctx = rx_current();
+
+	ctx->submit_calls++;
+	if (!ctx->submit_fail_at ||
+	    ctx->submit_calls == ctx->submit_fail_at)
+		return ctx->submit_error;
+	return 0;
+}
+
+static void rx_schedule_retry(struct rtl8xxxu_priv *priv)
+{
+	struct rx_test *ctx = rx_current();
+
+	/* Model the single pending delayed-work ticket, not a submission. */
+	if (!ctx->retry_pending) {
+		ctx->retry_pending = true;
+		ctx->retry_arms++;
+	}
+}
+
+static void rx_observe_work(struct work_struct *work)
+{
+	struct rtl8xxxu_priv *priv;
+	struct rx_test *ctx;
+
+	priv = container_of(work, struct rtl8xxxu_priv, rx_urb_wq);
+	ctx = container_of(priv, struct rx_test, priv);
+	atomic_inc(&ctx->normal_runs);
+}
+
+static struct rx_test *rx_init(struct kunit *test, bool fake_timer)
+{
+	struct rx_test *ctx;
+
+	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
+	if (!ctx)
+		return NULL;
+	test->priv = ctx;
+	ctx->hw.priv = &ctx->priv;
+	ctx->priv.hw = &ctx->hw;
+	ctx->priv.udev = &ctx->udev;
+	ctx->priv.fops = &ctx->fops;
+	ctx->fops.rx_desc_size = sizeof(struct rtl8xxxu_rxdesc16);
+	spin_lock_init(&ctx->priv.rx_urb_lock);
+	INIT_LIST_HEAD(&ctx->priv.rx_urb_pending_list);
+	INIT_LIST_HEAD(&ctx->priv.rx_urb_retry_list);
+	init_usb_anchor(&ctx->priv.rx_anchor);
+	INIT_WORK(&ctx->priv.rx_urb_wq, rx_observe_work);
+	INIT_DELAYED_WORK(&ctx->priv.rx_urb_retry_wq,
+			  rtl8xxxu_rx_urb_retry_work);
+	atomic_set(&ctx->normal_runs, 0);
+
+	kunit_activate_static_stub(test, rtl8xxxu_alloc_rx_urb, rx_alloc_object);
+	kunit_activate_static_stub(test, rtl8xxxu_alloc_rx_skb, rx_alloc_buffer);
+	kunit_activate_static_stub(test, rtl8xxxu_rx_usb_submit, rx_submit);
+	if (fake_timer)
+		kunit_activate_static_stub(test, rtl8xxxu_schedule_rx_retry,
+					   rx_schedule_retry);
+	return ctx;
+}
+
+static void rx_get_observers(struct rx_test *ctx)
+{
+	unsigned int i;
+
+	for (i = 0; i < ctx->allocated; i++)
+		usb_get_urb(&ctx->urbs[i]->urb);
+}
+
+static int rx_pool(struct rx_test *ctx, unsigned int count)
+{
+	struct rtl8xxxu_rx_urb *rx;
+	unsigned int i;
+	int ret;
+
+	ret = rtl8xxxu_alloc_rx_urbs(&ctx->priv);
+	rx_get_observers(ctx);
+	if (ret)
+		return ret;
+
+	/* A reduced pool also tests recovery without the normal watermark. */
+	for (i = count; i < ctx->allocated; i++) {
+		rx = ctx->urbs[i];
+		list_del_init(&rx->list);
+		ctx->priv.rx_urb_pending_count--;
+		usb_free_urb(&rx->urb);
+	}
+	return 0;
+}
+
+static void rx_giveback(struct rx_test *ctx, unsigned int i, int status)
+{
+	struct urb *urb = &ctx->urbs[i]->urb;
+
+	/* The fake USB boundary does not emulate HCD giveback. */
+	usb_unanchor_urb(urb);
+	urb->status = status;
+	urb->actual_length = 0;
+	rtl8xxxu_rx_complete(urb);
+}
+
+static void rx_finish(struct kunit *test, struct rx_test *ctx)
+{
+	struct urb *urb;
+	unsigned int i;
+
+	ctx->priv.shutdown = true;
+	cancel_delayed_work_sync(&ctx->priv.rx_urb_retry_wq);
+	cancel_work_sync(&ctx->priv.rx_urb_wq);
+	for (i = 0; i < ctx->allocated; i++) {
+		urb = &ctx->urbs[i]->urb;
+		if (urb->anchor)
+			rx_giveback(ctx, i, -ENOENT);
+	}
+	rtl8xxxu_free_rx_resources(&ctx->priv);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 0);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+	KUNIT_EXPECT_TRUE(test, usb_anchor_empty(&ctx->priv.rx_anchor));
+	for (i = 0; i < ctx->allocated; i++) {
+		urb = &ctx->urbs[i]->urb;
+		KUNIT_EXPECT_EQ(test, refcount_read(&urb->kref.refcount), 1);
+		usb_free_urb(urb);
+	}
+	for (i = 0; i < ctx->buffers; i++) {
+		KUNIT_EXPECT_EQ(test, refcount_read(&ctx->skbs[i]->users), 1);
+		kfree_skb(ctx->skbs[i]);
+	}
+}
+
+static void rx_retry_step(struct kunit *test, struct rx_test *ctx)
+{
+	KUNIT_ASSERT_TRUE(test, ctx->retry_pending);
+	ctx->retry_pending = false;
+	rtl8xxxu_rx_urb_retry_work(&ctx->priv.rx_urb_retry_wq.work);
+	flush_work(&ctx->priv.rx_urb_wq);
+	/* Execute the actual worker in the test task so boundary stubs apply. */
+	rtl8xxxu_rx_urb_work(&ctx->priv.rx_urb_wq);
+}
+
+static void rx_completion_submit_chain(struct kunit *test)
+{
+	static const int errors[] = {
+		-EPROTO, -EILSEQ, -ETIME, -EOVERFLOW, -ECOMM, -ENOSR,
+	};
+	static const int submissions[] = { -ENOMEM, -EAGAIN };
+	struct rx_test *ctx;
+	unsigned int e, f, i;
+	int runs;
+
+	for (e = 0; e < ARRAY_SIZE(errors); e++) {
+		for (f = 0; f < ARRAY_SIZE(submissions); f++) {
+			ctx = rx_init(test, true);
+			KUNIT_ASSERT_NOT_NULL(test, ctx);
+			KUNIT_ASSERT_EQ(test, rx_pool(ctx, RX_TEST_URBS), 0);
+			KUNIT_ASSERT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), 0);
+			for (i = 0; i < RX_TEST_URBS; i++)
+				rx_giveback(ctx, i, errors[e]);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 32);
+			ctx->submit_error = submissions[f];
+			rx_retry_step(test, ctx);
+			runs = atomic_read(&ctx->normal_runs);
+			flush_work(&ctx->priv.rx_urb_wq);
+			KUNIT_EXPECT_EQ(test, atomic_read(&ctx->normal_runs), runs);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 0);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 32);
+			KUNIT_EXPECT_TRUE(test, ctx->retry_pending);
+			for (i = 0; i < ctx->buffers; i++)
+				KUNIT_EXPECT_EQ(test,
+						refcount_read(&ctx->skbs[i]->users), 1);
+			ctx->submit_error = 0;
+			rx_retry_step(test, ctx);
+			KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+			KUNIT_EXPECT_FALSE(test, usb_anchor_empty(&ctx->priv.rx_anchor));
+			rx_finish(test, ctx);
+		}
+	}
+}
+
+static void rx_worker_batch_sizes(struct kunit *test)
+{
+	static const unsigned int sizes[] = { 1, 8, 9, 32 };
+	struct rx_test *ctx;
+	unsigned int n, pass;
+	int runs;
+
+	for (n = 0; n < ARRAY_SIZE(sizes); n++) {
+		ctx = rx_init(test, true);
+		KUNIT_ASSERT_NOT_NULL(test, ctx);
+		KUNIT_ASSERT_EQ(test, rx_pool(ctx, sizes[n]), 0);
+		ctx->submit_error = -EAGAIN;
+		rtl8xxxu_rx_urb_work(&ctx->priv.rx_urb_wq);
+		for (pass = 0; pass < 3; pass++) {
+			runs = atomic_read(&ctx->normal_runs);
+			flush_work(&ctx->priv.rx_urb_wq);
+			KUNIT_EXPECT_EQ(test, atomic_read(&ctx->normal_runs), runs);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, sizes[n]);
+			KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 0);
+			rx_retry_step(test, ctx);
+		}
+		ctx->submit_error = 0;
+		rx_retry_step(test, ctx);
+		KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+		rx_finish(test, ctx);
+	}
+}
+
+static void rx_skb_allocation_failure(struct kunit *test)
+{
+	struct rx_test *ctx;
+
+	ctx = rx_init(test, true);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	KUNIT_ASSERT_EQ(test, rx_pool(ctx, 8), 0);
+	ctx->fail_skb = true;
+	rtl8xxxu_rx_urb_work(&ctx->priv.rx_urb_wq);
+	KUNIT_EXPECT_EQ(test, ctx->submit_calls, 0);
+	KUNIT_EXPECT_EQ(test, ctx->buffers, 0);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 8);
+	ctx->fail_skb = false;
+	rx_retry_step(test, ctx);
+	KUNIT_EXPECT_EQ(test, ctx->submit_calls, 8);
+	rx_finish(test, ctx);
+}
+
+static void rx_start_allocation_failure(struct kunit *test)
+{
+	static const unsigned int positions[] = { 1, 8, 32 };
+	struct rx_test *ctx;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(positions); i++) {
+		ctx = rx_init(test, true);
+		KUNIT_ASSERT_NOT_NULL(test, ctx);
+		ctx->alloc_fail_at = positions[i];
+		KUNIT_EXPECT_EQ(test, rtl8xxxu_alloc_rx_urbs(&ctx->priv), -ENOMEM);
+		rx_get_observers(ctx);
+		KUNIT_EXPECT_EQ(test, ctx->allocated, positions[i] - 1);
+		KUNIT_EXPECT_EQ(test, ctx->submit_calls, 0);
+		KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+		rx_finish(test, ctx);
+	}
+}
+
+static void rx_start_temporary_failure(struct kunit *test)
+{
+	static const int errors[] = { -ENOMEM, -EAGAIN };
+	struct rx_test *ctx;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(errors); i++) {
+		ctx = rx_init(test, true);
+		KUNIT_ASSERT_NOT_NULL(test, ctx);
+		KUNIT_ASSERT_EQ(test, rx_pool(ctx, 32), 0);
+		ctx->submit_error = errors[i];
+		KUNIT_EXPECT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), 0);
+		KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 32);
+		KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 0);
+		KUNIT_EXPECT_TRUE(test, ctx->retry_pending);
+		ctx->submit_error = 0;
+		rx_retry_step(test, ctx);
+		rx_finish(test, ctx);
+	}
+}
+
+static void rx_start_fatal_failure(struct kunit *test)
+{
+	static const unsigned int positions[] = { 1, 8, 32 };
+	struct rx_test *ctx;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(positions); i++) {
+		ctx = rx_init(test, true);
+		KUNIT_ASSERT_NOT_NULL(test, ctx);
+		KUNIT_ASSERT_EQ(test, rx_pool(ctx, 32), 0);
+		ctx->submit_fail_at = positions[i];
+		ctx->submit_error = -ENODEV;
+		KUNIT_EXPECT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), -ENODEV);
+		KUNIT_EXPECT_EQ(test, ctx->submit_calls, positions[i]);
+		KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 0);
+		KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+		rx_finish(test, ctx);
+	}
+}
+
+static void rx_terminal_completion(struct kunit *test)
+{
+	static const int errors[] = {
+		-ENOENT, -ECONNRESET, -ENODEV, -ESHUTDOWN, -EPIPE,
+	};
+	struct rx_test *ctx;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(errors); i++) {
+		ctx = rx_init(test, true);
+		KUNIT_ASSERT_NOT_NULL(test, ctx);
+		KUNIT_ASSERT_EQ(test, rx_pool(ctx, 1), 0);
+		KUNIT_ASSERT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), 0);
+		rx_giveback(ctx, 0, errors[i]);
+		KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+		KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+		rx_finish(test, ctx);
+	}
+}
+
+static void rx_shutdown_completion(struct kunit *test)
+{
+	struct rx_test *ctx;
+
+	ctx = rx_init(test, true);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	KUNIT_ASSERT_EQ(test, rx_pool(ctx, 1), 0);
+	KUNIT_ASSERT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), 0);
+	ctx->priv.shutdown = true;
+	rx_giveback(ctx, 0, -EPROTO);
+	KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+	rx_finish(test, ctx);
+}
+
+static void rx_shutdown_pending_retry(struct kunit *test)
+{
+	struct rx_test *ctx;
+
+	ctx = rx_init(test, true);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	KUNIT_ASSERT_EQ(test, rx_pool(ctx, 8), 0);
+	ctx->submit_error = -ENOMEM;
+	rtl8xxxu_rx_urb_work(&ctx->priv.rx_urb_wq);
+	ctx->priv.shutdown = true;
+	rtl8xxxu_rx_urb_retry_work(&ctx->priv.rx_urb_retry_wq.work);
+	flush_work(&ctx->priv.rx_urb_wq);
+	KUNIT_EXPECT_EQ(test, atomic_read(&ctx->normal_runs), 0);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 8);
+	rx_finish(test, ctx);
+}
+
+static void rx_shutdown_submission_failure(struct kunit *test)
+{
+	struct rx_test *ctx;
+
+	ctx = rx_init(test, true);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	KUNIT_ASSERT_EQ(test, rx_pool(ctx, 8), 0);
+	ctx->priv.shutdown = true;
+	ctx->submit_error = -ENOMEM;
+	rtl8xxxu_rx_urb_work(&ctx->priv.rx_urb_wq);
+	KUNIT_EXPECT_FALSE(test, ctx->retry_pending);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+	rx_finish(test, ctx);
+}
+
+static void rx_real_delayed_bridge(struct kunit *test)
+{
+	struct rx_test *ctx;
+
+	ctx = rx_init(test, false);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	KUNIT_ASSERT_EQ(test, rx_pool(ctx, 1), 0);
+	KUNIT_ASSERT_EQ(test, rtl8xxxu_start_rx(&ctx->priv), 0);
+	rx_giveback(ctx, 0, -EPROTO);
+	flush_delayed_work(&ctx->priv.rx_urb_retry_wq);
+	flush_work(&ctx->priv.rx_urb_wq);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_retry_count, 0);
+	KUNIT_EXPECT_EQ(test, ctx->priv.rx_urb_pending_count, 1);
+	KUNIT_EXPECT_EQ(test, atomic_read(&ctx->normal_runs), 1);
+	rx_finish(test, ctx);
+}
+
+static struct kunit_case rx_cases[] = {
+	KUNIT_CASE(rx_completion_submit_chain),
+	KUNIT_CASE(rx_worker_batch_sizes),
+	KUNIT_CASE(rx_skb_allocation_failure),
+	KUNIT_CASE(rx_start_allocation_failure),
+	KUNIT_CASE(rx_start_temporary_failure),
+	KUNIT_CASE(rx_start_fatal_failure),
+	KUNIT_CASE(rx_terminal_completion),
+	KUNIT_CASE(rx_shutdown_completion),
+	KUNIT_CASE(rx_shutdown_pending_retry),
+	KUNIT_CASE(rx_shutdown_submission_failure),
+	KUNIT_CASE(rx_real_delayed_bridge),
+	{}
+};
+
+static struct kunit_suite rx_suite = {
+	.name = "rtl8xxxu-rx",
+	.test_cases = rx_cases,
+};
+
+kunit_test_suite(rx_suite);
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+MODULE_DESCRIPTION("rtl8xxxu RX recovery KUnit tests");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rx-test.h b/drivers/net/wireless/realtek/rtl8xxxu/rx-test.h
new file mode 100644
index 0000000000000..295befdfe8144
--- /dev/null
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rx-test.h
@@ -0,0 +1,27 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef RTL8XXXU_RX_TEST_H
+#define RTL8XXXU_RX_TEST_H
+
+#include <kunit/visibility.h>
+#include <linux/gfp_types.h>
+
+struct rtl8xxxu_priv;
+struct rtl8xxxu_rx_urb;
+struct sk_buff;
+struct urb;
+struct work_struct;
+
+VISIBLE_IF_KUNIT struct rtl8xxxu_rx_urb *rtl8xxxu_alloc_rx_urb(void);
+VISIBLE_IF_KUNIT struct sk_buff *rtl8xxxu_alloc_rx_skb(unsigned int size);
+VISIBLE_IF_KUNIT int rtl8xxxu_rx_usb_submit(struct urb *urb, gfp_t flags);
+VISIBLE_IF_KUNIT void rtl8xxxu_schedule_rx_retry(struct rtl8xxxu_priv *priv);
+VISIBLE_IF_KUNIT int rtl8xxxu_alloc_rx_urbs(struct rtl8xxxu_priv *priv);
+VISIBLE_IF_KUNIT int rtl8xxxu_start_rx(struct rtl8xxxu_priv *priv);
+VISIBLE_IF_KUNIT int rtl8xxxu_submit_rx_urb(struct rtl8xxxu_priv *priv,
+					    struct rtl8xxxu_rx_urb *rx_urb);
+VISIBLE_IF_KUNIT void rtl8xxxu_free_rx_resources(struct rtl8xxxu_priv *priv);
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_complete(struct urb *urb);
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_urb_work(struct work_struct *work);
+VISIBLE_IF_KUNIT void rtl8xxxu_rx_urb_retry_work(struct work_struct *work);
+
+#endif

-- 
2.48.1

