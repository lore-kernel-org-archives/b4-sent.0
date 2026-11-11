From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Wed, 11 Nov 2026 16:22:26 +0000
Subject: [PATCH net v2] net: usb: smsc75xx: reject frames without a full
 header and FCS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-smsc75xx-rx-fcs-v2-1-216a5f26842a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEGW9GoC/3WNvQ7CMBCDX6W6maBeKCUw8R6oQ0ku7Un0R7kqC
 qr67kTZGTx8tmzvIBSYBB7VDoEiCy9zBn2qwI79PJBilxl0rVtErJVMYm/XlFRIylvJ6u+tcR6
 dJcitNZDnVBZfMNMGXTZHlm0J3/ISsUR/ByMqVA3VjXl7q42/PIep58/ZLhN0x3H8AOCp+x+zA
 AAA
To: steve.glendinning@shawell.net, andrew+netdev@lunn.ch, 
 davem@davemloft.net, edumazet@kernel.org, kuba@kernel.org, 
 pabeni@redhat.com, joasantonio108@gmail.com
Cc: netdev@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794414145; l=3049;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=UakfyXge5Z7dCorT5L2tCidbQJeCZJFs6IXcWJSAcH0=;
 b=X3LdGQ0gmxyYqtbCxoFYV/DavCK6B5PoaonNbH+/qj6xL6UcK7taMtAk6ZVCvgO6LnrJkQk1K
 DShzMr0btrABu3f+q47WR8v7Vh5Qo+iUn+I5TZWfi4bCr6YBhITayeo
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

A frame that holds an FCS but less than an Ethernet header is not
valid either.  usbnet drops it when it is the last frame in the URB,
but the other frames go straight to usbnet_skb_return(), where
eth_type_trans() reads an Ethernet header that was never copied into
the new skb.

Reject frames that are too short to hold an Ethernet header and an
FCS, which covers both cases with one check.

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
Changes in v2:
- Also reject frames too short for an Ethernet header, combined with
  the FCS check into a single test (review feedback on v1).
- Subject changed accordingly; it was "net: usb: smsc75xx: reject
  frames shorter than the FCS".
- Link to v1: https://lore.kernel.org/r/20261110-smsc75xx-rx-fcs-v1-1-4e048bfc28f3@gmail.com
---
 drivers/net/usb/smsc75xx.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/net/usb/smsc75xx.c b/drivers/net/usb/smsc75xx.c
index 6f72a3f15907..893de273adef 100644
--- a/drivers/net/usb/smsc75xx.c
+++ b/drivers/net/usb/smsc75xx.c
@@ -2217,6 +2217,13 @@ static int smsc75xx_rx_fixup(struct usbnet *dev, struct sk_buff *skb)
 				return 0;
 			}
 
+			if (unlikely(size < ETH_HLEN + ETH_FCS_LEN)) {
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

