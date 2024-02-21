From: Janne Grunau <j@jannau.net>
Date: Wed, 21 Feb 2024 08:25:03 +0100
Subject: [PATCH 3/6] usb: xhci: Abort transfers with unallocated rings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-asahi-keyboards-v1-3-814b2e741790@jannau.net>
References: <20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net>
In-Reply-To: <20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1053; i=j@jannau.net;
 h=from:subject:message-id; bh=EzgLII75vJWMRf8tU350iE+qgV69Ozl8ArZ4I2u1mHc=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtSrS6Mu2N81yt4jqSdY+TbFLk6HsflZifz5wsReDm79P
 N38h/odpSwMYlwMsmKKLEnaLzsYVtcoxtQ+CIOZw8oEMoSBi1MAJmI1k+EXM2ela8XO9qRDs72c
 87LV2T4YzPaoSX+99vHTlTMKJwmHMfwzu7BcKjzZN4NR5GDV/qR/b0xe2p2artIxedLpndkV7Wp
 cAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Discovered while trying to use the second interface in the USB keyboard
driver necessary on Apple USB keyboards.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/usb/host/xhci-ring.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/host/xhci-ring.c b/drivers/usb/host/xhci-ring.c
index b60661fe05..4446f5f098 100644
--- a/drivers/usb/host/xhci-ring.c
+++ b/drivers/usb/host/xhci-ring.c
@@ -685,6 +685,9 @@ int xhci_bulk_tx(struct usb_device *udev, unsigned long pipe,
 		reset_ep(udev, ep_index);
 
 	ring = virt_dev->eps[ep_index].ring;
+	if (!ring)
+		return -1;
+
 	/*
 	 * How much data is (potentially) left before the 64KB boundary?
 	 * XHCI Spec puts restriction( TABLE 49 and 6.4.1 section of XHCI Spec)
@@ -871,6 +874,8 @@ int xhci_ctrl_tx(struct usb_device *udev, unsigned long pipe,
 	ep_index = usb_pipe_ep_index(pipe);
 
 	ep_ring = virt_dev->eps[ep_index].ring;
+	if (!ep_ring)
+		return -1;
 
 	/*
 	 * Check to see if the max packet size for the default control

-- 
2.43.2

