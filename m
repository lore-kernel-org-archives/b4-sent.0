From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: heikki.krogerus@linux.intel.com, gregkh@linuxfoundation.org
Cc: hdegoede@redhat.com, sven@kernel.org, j@jannau.net, 
 Thinh.Nguyen@synopsys.com, asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 1/2] usb: dwc3: apple: unregister role switch outside
 appledwc->lock
Date: Thu, 26 Nov 2026 00:53:19 +0000
Message-Id: <20261126005318.71705-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126005318.71705-1-iasnezhkov@gmail.com>
References: <20261126005318.71705-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654398; l=1659;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=Xp06A3FHG/XK7qHNfZ3rlNyEPxz/IhGg4iOv80ET3F0=;
 b=AMfuWfdiddw8Ndl0XmAmmSC5iJnrSaq7gxYQF6yEDW46sW5YeVP9hlYrUZMsVNGqKKrB6EQDi
 +XqDVUXnce9A2w2E/84X7eWHemTdvEIA6kPlEHeszqjjxSSqbLAtSVO
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dwc3_apple_remove() holds appledwc->lock across
usb_role_switch_unregister(), while both dwc3_usb_role_switch_set() and
dwc3_usb_role_switch_get() acquire appledwc->lock.

Calling usb_role_switch_unregister() under appledwc->lock creates an
ABBA lock-order inversion against both sysfs attribute teardown
(device_unregister() -> kernfs_drain() waiting on an active role_show /
role_store callback) and synchronizing usb_role_switch_unregister()
against in-flight callbacks under sw->lock.

appledwc->role_sw is assigned once during probe and never modified
afterwards. Unregister the role switch before acquiring appledwc->lock
for hardware teardown.

Found and drafted with an AI coding assistant.

Fixes: 0ec946d32ef7 ("usb: dwc3: Add Apple Silicon DWC3 glue layer driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/usb/dwc3/dwc3-apple.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/dwc3/dwc3-apple.c b/drivers/usb/dwc3/dwc3-apple.c
index 1f474a8..035aeeb 100644
--- a/drivers/usb/dwc3/dwc3-apple.c
+++ b/drivers/usb/dwc3/dwc3-apple.c
@@ -487,10 +487,10 @@ static void dwc3_apple_remove(struct platform_device *pdev)
 	struct dwc3 *dwc = platform_get_drvdata(pdev);
 	struct dwc3_apple *appledwc = to_dwc3_apple(dwc);
 
-	guard(mutex)(&appledwc->lock);
-
 	usb_role_switch_unregister(appledwc->role_sw);
 
+	guard(mutex)(&appledwc->lock);
+
 	/*
 	 * If we're still in DWC3_APPLE_PROBE_PENDING we never got any cable connected event and
 	 * dwc3_core_probe was never called and there's hence no need to call dwc3_core_remove.
-- 
2.54.0 (Apple Git-157)


