From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Jan 2026 03:07:18 +0800
Subject: [PATCH v3 1/6] drivers: core: device: set new parent when old
 parent is NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-clk-reparent-v3-1-0d43d4b362ac@outlook.com>
References: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
In-Reply-To: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768849639; l=969;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=OkZuox6Z1IbENHdSA3AsovLwcHU5OVol0g+5GscgV+U=;
 b=0dzAguuUjbQMz7yawY5OA4wG6fUnDbvwJAUEfhAhT35dlYvGQZNAOGRe6dGPNRXWpVWhPswpI
 n/79eTFy/8zAI92dM36ScNrKTIqrvgIZ4XHW1I6BJcuWY83ftFBc6Pc
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current logic does not update the new parent in device_reparent() if
old parent is NULL. The behavior is not desired. Fix it by setting the
parent in this case.

Fixes: cfecbaf4e768 ("dm: core: add support for device re-parenting")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/core/device.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/core/device.c b/drivers/core/device.c
index 779f371b9d5b..0ae09f5a4e33 100644
--- a/drivers/core/device.c
+++ b/drivers/core/device.c
@@ -285,6 +285,14 @@ int device_reparent(struct udevice *dev, struct udevice *new_parent)
 	assert(dev);
 	assert(new_parent);
 
+	if (!dev->parent) {
+		assert(list_empty(&dev->sibling_node));
+
+		list_add_tail(&dev->sibling_node, &new_parent->child_head);
+		dev->parent = new_parent;
+		return 0;
+	}
+
 	device_foreach_child_safe(pos, n, dev->parent) {
 		if (pos->driver != dev->driver)
 			continue;

-- 
2.43.0

