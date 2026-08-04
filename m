From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 10:18:21 +0530
Subject: [PATCH] media: hackrf: fix use-after-free in hackrf_alloc_urbs()
 error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-hackrf-alloc-urbs-double-free-v1-1-a2abe8e515a6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAwA0F8ZORvoNnXqr4iHJktdtaySWBHG/
 t2qx3d5C5hoFINTs4DKK1rMc0W7aYAnP18F41gNnev27uC2OHm+a0CfUmYsSoZjLpQEg4ogMw1
 tvzsO3BPU46ES4vv3ny9/W6Gb8PObwrp+AGoZBSyBAAAA
X-Change-ID: 20260804-hackrf-alloc-urbs-double-free-ccb713597c3b
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+832ce9fa3face1b7d44d@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785818900; l=2781;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=JT0InAxsUZIh/vmY+n+CTvUVrKVu7SQ4wLCM7VeGKo4=;
 b=XiY+d/wENrzLn92spP5BswBntPYL2VQzW3SVgLkRMo8FkyT63swTQxoE58ModoJkXyoDqNoxw
 y1nTm0zTwKcDnV3krVSUaN4NcuWbBSP9vOcCKnUEfJAIipokhBIXDW4
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hackrf_alloc_urbs() frees the URBs it allocated so far when one
allocation fails, but leaves the entries in dev->urb_list[] and
dev->urbs_initialized untouched. The caller, hackrf_start_streaming(),
then calls hackrf_free_urbs() on the error path, which walks
dev->urbs_initialized entries and calls usb_free_urb() a second time on
the already-freed URBs, causing a use-after-free (slab-use-after-free
Write in usb_free_urb()).

Drop the redundant cleanup loop inside hackrf_alloc_urbs() and let
hackrf_free_urbs(), which the caller already invokes on error, own the
cleanup of the successfully allocated URBs.

Reported-by: syzbot+832ce9fa3face1b7d44d@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=832ce9fa3face1b7d44d
Fixes: 969ec1f6bd92 ("[media] hackrf: HackRF SDR driver")
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
syzbot reports a slab-use-after-free Write in usb_free_urb(), triggered
by an allocation failure (failslab) while opening the streaming queue of
the HackRF SDR driver.

hackrf_alloc_urbs() frees the URBs it allocated so far when one
allocation fails, but leaves the entries in dev->urb_list[] and
dev->urbs_initialized untouched. The caller, hackrf_start_streaming(),
then calls hackrf_free_urbs() on the error path, which walks
dev->urbs_initialized entries and calls usb_free_urb() a second time on
the already-freed URBs, causing a use-after-free.

Drop the redundant cleanup loop inside hackrf_alloc_urbs() and let
hackrf_free_urbs(), which the caller already invokes on error, own the
cleanup of the successfully allocated URBs.
---
 drivers/media/usb/hackrf/hackrf.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/media/usb/hackrf/hackrf.c b/drivers/media/usb/hackrf/hackrf.c
index a15829a60e8..70fd95f3e97 100644
--- a/drivers/media/usb/hackrf/hackrf.c
+++ b/drivers/media/usb/hackrf/hackrf.c
@@ -665,7 +665,7 @@ static int hackrf_free_urbs(struct hackrf_dev *dev)
 
 static int hackrf_alloc_urbs(struct hackrf_dev *dev, bool rcv)
 {
-	int i, j;
+	int i;
 	unsigned int pipe;
 	usb_complete_t complete;
 
@@ -681,11 +681,8 @@ static int hackrf_alloc_urbs(struct hackrf_dev *dev, bool rcv)
 	for (i = 0; i < MAX_BULK_BUFS; i++) {
 		dev_dbg(dev->dev, "alloc urb=%d\n", i);
 		dev->urb_list[i] = usb_alloc_urb(0, GFP_KERNEL);
-		if (!dev->urb_list[i]) {
-			for (j = 0; j < i; j++)
-				usb_free_urb(dev->urb_list[j]);
+		if (!dev->urb_list[i])
 			return -ENOMEM;
-		}
 		usb_fill_bulk_urb(dev->urb_list[i],
 				dev->udev,
 				pipe,

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260804-hackrf-alloc-urbs-double-free-ccb713597c3b

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

