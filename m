From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 14:07:31 +0000
Subject: [PATCH] fbdev: cobalt_lcdfb: Don't read info after
 framebuffer_release()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-cobalt-lcdfb-v1-1-214062966e2c@gmail.com>
X-B4-Tracking: v=1; b=H4sIACKx/WoC/yXMQQ5AMBBA0avIrDUxldC4iljoGIwI0iKSxt0Vy
 7f4P4BnJ+yhSgI4PsXLukRgmgCN7TKwki4adKYLRDSKVtvOu5qp663SJrdcErHBHGKyOe7l+nZ
 189sfdmLa3wfc9wPr0o8gcAAAAA==
X-Change-ID: 20261118-cobalt-lcdfb-283be7cce813
To: deller@gmx.de
Cc: dri-devel@lists.freedesktop.org, yoichi_yuasa@tripeaks.co.jp, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795010851; l=1575;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=er7rtpx/jSXL/nx1TsKPyrqeGvkHFZOhjOCGFfe5dcs=;
 b=fDeky12W0HSacB2idTO/VQw34vgDHz88wZN1XKObbv8DHVGPEgYDlyRl4h+ntdPtDy2om7L8f
 L1nwjqbkygJCOebbQvpOheCZriZQh4ZqHGwZ4OXpw4h7ZwdsJH4UdHJ
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When devm_platform_get_and_ioremap_resource() fails, cobalt_lcdfb_probe()
releases the framebuffer and then dereferences it for the return value:

	framebuffer_release(info);
	return PTR_ERR(info->screen_base);

framebuffer_release() frees info, so info->screen_base is read from freed
memory. Save the error code before releasing info.

Found with a static analysis tool and checked by hand.

Fixes: d2386d9e3eb4 ("fbdev: cobalt_lcdfb: Request memory region")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
The change only moves the error-code read before framebuffer_release().
Checked by inspection; I couldn't build it here (MIPS, and my MIPS cross
toolchain fails at an unrelated host step), and I don't have the
hardware.
---
 drivers/video/fbdev/cobalt_lcdfb.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/video/fbdev/cobalt_lcdfb.c b/drivers/video/fbdev/cobalt_lcdfb.c
index f7faa95fefd3..e90f45c91725 100644
--- a/drivers/video/fbdev/cobalt_lcdfb.c
+++ b/drivers/video/fbdev/cobalt_lcdfb.c
@@ -297,8 +297,9 @@ static int cobalt_lcdfb_probe(struct platform_device *dev)
 
 	info->screen_base = devm_platform_get_and_ioremap_resource(dev, 0, &res);
 	if (IS_ERR(info->screen_base)) {
+		retval = PTR_ERR(info->screen_base);
 		framebuffer_release(info);
-		return PTR_ERR(info->screen_base);
+		return retval;
 	}
 
 	info->screen_size = resource_size(res);



