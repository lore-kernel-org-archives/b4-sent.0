From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:56:43 +0000
Subject: [PATCH 2/2] can: kvaser_usb: reject devices reporting zero max
 outstanding tx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-kvaser-usb-validate-v1-2-f266b85aa908@gmail.com>
References: <20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com>
In-Reply-To: <20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283001; l=1920;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=CWXGNrvsTmGzERh91MhkIoNvIPE1iZLcRy1k5EnUGBw=;
 b=SPDeDXx/noF/b91sP8wtQ3fgDtpmBqDRVZprOpBYymgVpwiPSjGcyAfv1RzxJGiyaqozTTpcv
 VDkPMfR4eQLDUhRuS2IZio9mS4cfCm8xd8mU4qikfxA9++DceG7HYAB
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The number of tx contexts is taken from the max_outstanding_tx field of
the software info reply sent by the device.  The leaf driver uses the
value as is and the hydra driver only limits it to
KVASER_USB_MAX_TX_URBS, so a device can report zero.

dev->max_tx_urbs is then used as a divisor when a tx acknowledge is
received:

  kvaser_usb_leaf_tx_acknowledge()
	context = &priv->tx_contexts[tid % dev->max_tx_urbs];

  kvaser_usb_hydra_tx_acknowledge()
	context = &priv->tx_contexts[transid % dev->max_tx_urbs];

With max_tx_urbs == 0 a tx acknowledge sent by the device while the
interface is up is a division by zero in the URB completion handler on
architectures that trap on it.  On architectures that do not
trap, the index is not reduced at all and tx_contexts[], which was
allocated with zero elements, is accessed out of bounds.

A device that cannot accept any outstanding tx frame is not usable, so
fail the probe when it reports zero.

Found by LLM-assisted source review.

Fixes: 082d70b6142f ("can: kvaser_usb: Comply with firmware max tx URBs value")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c b/drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c
index d0a2a2a33c1c..a915e529290b 100644
--- a/drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c
+++ b/drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c
@@ -977,6 +977,12 @@ static int kvaser_usb_probe(struct usb_interface *intf,
 		goto free_devlink;
 	}
 
+	if (!dev->max_tx_urbs) {
+		dev_err(&intf->dev, "Invalid max outstanding tx (0)\n");
+		err = -ENODEV;
+		goto free_devlink;
+	}
+
 	if (ops->dev_get_software_details) {
 		err = ops->dev_get_software_details(dev);
 		if (err) {

-- 
2.43.0

