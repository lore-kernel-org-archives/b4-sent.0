From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 21 Jun 2025 18:54:18 +0800
Subject: [PATCH RFC 1/3] drivers: core: device: set new parent when old
 parent is NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250621-clk-reparent-v1-1-48a7f2f31c59@outlook.com>
References: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
In-Reply-To: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750503259; l=839;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rhy+xV0NM53o9DGwPd5dEg228yNd5agLsWCZl6AQrlQ=;
 b=JguQ/lYhzykbkwtJhNhk0SybJMgcu07+xWoxHAKji4qpklmRgVu0MMJhnEp54PpQisJ9k47+D
 bVNY1Yo4lRCA+X5PYjGsiI+vlMBzrkWluLnVT4mvhtTGOoOStkkSTYg
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The old logic does not set the new parent in device_reparent() when old
parent is NULL. It's not desired. Fix it by setting the parent in this
case.

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

