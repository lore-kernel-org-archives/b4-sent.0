From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 09:03:21 +0000
Subject: [PATCH net] net: usb: smsc75xx: reject frames shorter than the FCS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smsc75xx-rx-fcs-v1-1-4e048bfc28f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIANjd8moC/x2MuwqAMAwAf6VkNmAKPn9FHKRNNYNVGpGC+O8Wh
 xtuuHtAOQkrjOaBxLeoHLEIVQbctsSVUXxxsLVtiahG3dV1Tc6YMganhWVoex/IO4ZSnYmD5P8
 4QeQL5vf9AAyj1IhmAAAA
To: joasantonio108@gmail.com, steve.glendinning@shawell.net, 
 andrew+netdev@lunn.ch, davem@davemloft.net, edumazet@kernel.org, 
 kuba@kernel.org, pabeni@redhat.com
Cc: netdev@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794301400; l=2363;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=G1cAL4e/Pmr3AzCsbxnGrjhhPlyOjfRjUMp1/pULOYE=;
 b=p47NHnLvmlqjWX1hzQxuofh7VEdXnFhY3NCjZj6MpBzk3zeO8NcmasCQR8/uUCoyO2fKF92W7
 aHXxY9fV06dAOPQfEnMx8MrmlR/DWsrO407E5TgGXibSp0E65RTRccb
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smsc75xx_rx_fixup() takes the frame length from the RX command word
supplied by the device and strips the FCS by using "size - 4" for the
allocation, skb_put() and memcpy() of each frame that is not the last
one in the URB.  The length is only checked against an upper bound and
against skb->len, so a device can report a length field of 2..5, which
gives a size of 0..3 after RXW_PADDING is subtracted.

size is a u32, so "size - 4" then wraps to 0xfffffffc..0xffffffff.
__netdev_alloc_skb() adds NET_SKB_PAD to the unsigned length, which
wraps back to a small value and the allocation succeeds.  skb_put()
adds the length to the 32-bit skb->tail and skb->len, which also wrap,
so the skb_over_panic() check does not fire.  The following memcpy()
then tries to copy almost 4 GiB from the URB buffer into that small
allocation and writes far beyond it.

A malicious or malfunctioning USB device can use this to corrupt
kernel memory or crash the machine.

Reject frames that are too short to hold an FCS, as lan78xx_rx() does.

Found by LLM-assisted source review.

Fixes: 1b3b2d9e772b ("net: usb: smsc75xx: stop lying about skb->truesize")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 drivers/net/usb/smsc75xx.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/net/usb/smsc75xx.c b/drivers/net/usb/smsc75xx.c
index 6f72a3f15907..e923fa6c1785 100644
--- a/drivers/net/usb/smsc75xx.c
+++ b/drivers/net/usb/smsc75xx.c
@@ -2217,6 +2217,13 @@ static int smsc75xx_rx_fixup(struct usbnet *dev, struct sk_buff *skb)
 				return 0;
 			}
 
+			if (unlikely(size < ETH_FCS_LEN)) {
+				netif_dbg(dev, rx_err, dev->net,
+					  "size err rx_cmd_a=0x%08x\n",
+					  rx_cmd_a);
+				return 0;
+			}
+
 			/* last frame in this batch */
 			if (skb->len == size) {
 				smsc75xx_rx_csum_offload(dev, skb, rx_cmd_a,

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-smsc75xx-rx-fcs-fca968df1dce

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

