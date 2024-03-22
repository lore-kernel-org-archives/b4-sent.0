From: Janne Grunau <j@jannau.net>
Date: Fri, 22 Mar 2024 08:47:06 +0100
Subject: [PATCH v3 3/6] usb: xhci: Abort transfers with unallocated rings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240322-asahi-keyboards-v3-3-3106dd4c4e19@jannau.net>
References: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
In-Reply-To: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1147; i=j@jannau.net;
 h=from:subject:message-id; bh=4WL/oK9QHrPZzv/LO0Lx0LR9aR1vioRk0nnmNOFZrzg=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtS/5i0/Z//c82PbI5FnJ5J0P+bvktTYXRH4uW3yj+SbX
 M43/fxPdpSyMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZjIrg0M/z39lHgOfdm0qued
 RyLfntM9h1kljY4miacsc9+wW/XsTzmGf9blPif0Wf95ztTvnz75MudElQal6c7J4uVrT78U2rh
 GghMA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Discovered while trying to use the second interface in the USB keyboard
driver necessary on Apple USB keyboards.

Reviewed-by: Marek Vasut <marex@denx.de>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/usb/host/xhci-ring.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/host/xhci-ring.c b/drivers/usb/host/xhci-ring.c
index b60661fe05..910c5f3352 100644
--- a/drivers/usb/host/xhci-ring.c
+++ b/drivers/usb/host/xhci-ring.c
@@ -685,6 +685,9 @@ int xhci_bulk_tx(struct usb_device *udev, unsigned long pipe,
 		reset_ep(udev, ep_index);
 
 	ring = virt_dev->eps[ep_index].ring;
+	if (!ring)
+		return -EINVAL;
+
 	/*
 	 * How much data is (potentially) left before the 64KB boundary?
 	 * XHCI Spec puts restriction( TABLE 49 and 6.4.1 section of XHCI Spec)
@@ -871,6 +874,8 @@ int xhci_ctrl_tx(struct usb_device *udev, unsigned long pipe,
 	ep_index = usb_pipe_ep_index(pipe);
 
 	ep_ring = virt_dev->eps[ep_index].ring;
+	if (!ep_ring)
+		return -EINVAL;
 
 	/*
 	 * Check to see if the max packet size for the default control

-- 
2.44.0

