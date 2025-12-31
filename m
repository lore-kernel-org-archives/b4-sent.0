From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Jan 2026 03:52:47 +0800
Subject: [PATCH v2 1/5] drivers: core: device: set new parent when old
 parent is NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-clk-reparent-v2-1-3eb42b78c7f1@outlook.com>
References: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
In-Reply-To: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210769; l=855;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=XznkdepdWTVh+68VXRGyyBWqop//US/HHAe8lwYVuMM=;
 b=R2eFXeJFU4R3n1BMJZs/m97jSSTKFD6b+J0aTsOtjJVl3Jvezy+3JRvwo5JOhnxu4InxuuI5L
 GFh8l1rurxwAwdbmi0skhR7yExbx2xmnKLwSfNfCM+PZygoJsRLKSGA
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
 drivers/core/device.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/core/device.c b/drivers/core/device.c
index 779f371b9d5b..497c32befde7 100644
--- a/drivers/core/device.c
+++ b/drivers/core/device.c
@@ -285,6 +285,11 @@ int device_reparent(struct udevice *dev, struct udevice *new_parent)
 	assert(dev);
 	assert(new_parent);
 
+	if (!dev->parent) {
+		dev->parent = new_parent;
+		return 0;
+	}
+
 	device_foreach_child_safe(pos, n, dev->parent) {
 		if (pos->driver != dev->driver)
 			continue;

-- 
2.43.0

