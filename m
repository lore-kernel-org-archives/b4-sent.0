From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 22:50:54 +0530
Subject: [PATCH] usb: gadget: uvc: fix use-after-free in
 uvcg_extension_drop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-uvc-extension-drop-uaf-v1-1-4a5db42150af@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBSE4VeRs+6BJBQRX0W6yGXSHhdREiOC+
 O6N7fKDmf+kgiwoNHYnZexSZEkN+tGR/9j0BktoJqNMrwb15Lp7xrEh3UsOeVm52simdxFWO2+
 CpnZeM6Icv/D0+rtUN8Nvd42u6wtluT0LegAAAA==
X-Change-ID: 20260804-uvc-extension-drop-uaf-26bfea1bc2d1
To: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, 
 syzbot+f093afc4e90b1908abdc@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785864053; l=2708;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=W838bVUurWYZNY+1DKGGhm3wxWgzNATfRFLxHYdrL2Q=;
 b=npVcnkwvwoGZCllYtfiIdi9cdpbYyXEu2OMuXY5R/E7Dl623esTnw85rUBuHEEfgfx2RjL3nG
 kjYcx01yznDBmJ0clppXjdwtzOGwJqN6/YbE9jX3vOQufs6MweBcml2
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

uvcg_extension_drop() releases the configfs item reference with
config_item_put() and then removes the extension unit from the list and
frees its dynamic descriptor fields. When the put is the last reference,
config_item_cleanup() runs uvcg_extension_release(), which kfree()s the
struct uvcg_extension, so the subsequent list_del() and kfree() calls
dereference freed memory.

The configfs mkdir error path calls drop_item() on an item whose only
reference is the one held by the configfs hierarchy, so the put inside
drop_item() frees the unit synchronously and list_del() reads freed
memory (KASAN: slab-use-after-free Read in uvcg_extension_drop).

Do all the list and field cleanup while the item is still alive, and
release the reference as the last step.

Reported-by: syzbot+f093afc4e90b1908abdc@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=f093afc4e90b1908abdc
Fixes: 0525210c9840 ("usb: gadget: uvc: Allow definition of XUs in configfs")
Assisted-by: deepseek:v4-pro
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
uvcg_extension_drop() releases the configfs item reference with
config_item_put() and then removes the extension unit from the list and
frees its dynamic descriptor fields. When that put is the last
reference, config_item_cleanup() runs uvcg_extension_release(), which
kfree()s the struct uvcg_extension, so the subsequent list_del()
dereferences freed memory.

The configfs mkdir error path calls drop_item() on an item whose only
reference is the one held by the configfs hierarchy, so the put inside
drop_item() frees the unit synchronously and list_del() then reads freed
memory (KASAN: slab-use-after-free Read in uvcg_extension_drop).

Fix it by doing all the list and field cleanup while the item is still
alive, and releasing the reference as the last step.
---
 drivers/usb/gadget/function/uvc_configfs.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/gadget/function/uvc_configfs.c b/drivers/usb/gadget/function/uvc_configfs.c
index 70a1415ea40..65bad40ec6e 100644
--- a/drivers/usb/gadget/function/uvc_configfs.c
+++ b/drivers/usb/gadget/function/uvc_configfs.c
@@ -1256,11 +1256,12 @@ static void uvcg_extension_drop(struct config_group *group, struct config_item *
 
 	mutex_lock(&opts->lock);
 
-	config_item_put(item);
 	list_del(&xu->list);
 	kfree(xu->desc.baSourceID);
 	kfree(xu->desc.bmControls);
 
+	config_item_put(item);
+
 	mutex_unlock(&opts->lock);
 }
 

---
base-commit: 848acc8ffe1b7cd5f1bf427b93069becfebc2c9d
change-id: 20260804-uvc-extension-drop-uaf-26bfea1bc2d1

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

