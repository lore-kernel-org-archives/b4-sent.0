From: Nick Faro <yux50000@hotmail.com>
Date: Thu, 27 Aug 2026 19:44:16 +0200
Subject: [PATCH 6/6] media: cx231xx: size alternate-setting arrays by
 element count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-cx231xx-disconnect-lifetime-v1-6-7bbf946bbd36@hotmail.com>
References: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
In-Reply-To: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nick Faro <yux50000@hotmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787852712; l=3377;
 i=yux50000@hotmail.com; s=20260827; h=from:subject:message-id;
 bh=kLY4AOB7qHaFhPJKspXqxDDTNgxhM5uHaXa6/IBCVAU=;
 b=JLFKzpuefLQauppuvB7mF+R3+uw3MRQUz7Xbnfb2Ej0U8gzNTvZ0cL7/U6Hbdn4oGAjnpOjDH
 P7lmJqHh+ceDicrviTHBxEQZym2ZYhfRLJg5IeyIDDP+/f5dLhRepxU
X-Developer-Key: i=yux50000@hotmail.com; a=ed25519;
 pk=FMSCCFHmUW8ylFpPOeaegUBqrRhzdMS2snqX/kNbLtM=
X-Endpoint-Received: by B4 Relay for yux50000@hotmail.com/20260827 with auth_id=979
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The arguments to kmalloc_array() are the number of elements followed by
the size of each element. The driver instead passes 32 and the number of
alternate settings, apparently confusing the width of the stored value
with its size in bytes.

Allocate one correctly sized element for each alternate setting in the
video, VBI, sliced-caption, transport-stream and audio arrays.

Fixes: e0d3bafd0258 ("V4L/DVB (10954): Add cx231xx USB driver")
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Nick Faro <yux50000@hotmail.com>
---
 drivers/media/usb/cx231xx/cx231xx-audio.c |  4 +++-
 drivers/media/usb/cx231xx/cx231xx-cards.c | 16 ++++++++++++----
 2 files changed, 15 insertions(+), 5 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-audio.c b/drivers/media/usb/cx231xx/cx231xx-audio.c
index a10b887edf51..eaddad793900 100644
--- a/drivers/media/usb/cx231xx/cx231xx-audio.c
+++ b/drivers/media/usb/cx231xx/cx231xx-audio.c
@@ -656,7 +656,9 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 	dev_info(dev->dev,
 		"audio EndPoint Addr 0x%x, Alternate settings: %i\n",
 		adev->end_point_addr, adev->num_alt);
-	adev->alt_max_pkt_size = kmalloc_array(32, adev->num_alt, GFP_KERNEL);
+	adev->alt_max_pkt_size = kmalloc_array(adev->num_alt,
+					       sizeof(*adev->alt_max_pkt_size),
+					       GFP_KERNEL);
 	if (!adev->alt_max_pkt_size) {
 		err = -ENOMEM;
 		goto err_free_card;
diff --git a/drivers/media/usb/cx231xx/cx231xx-cards.c b/drivers/media/usb/cx231xx/cx231xx-cards.c
index 8e23de4cddf8..3c4bbf724d63 100644
--- a/drivers/media/usb/cx231xx/cx231xx-cards.c
+++ b/drivers/media/usb/cx231xx/cx231xx-cards.c
@@ -1606,7 +1606,9 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 		 dev->video_mode.num_alt);
 
 	dev->video_mode.alt_max_pkt_size =
-		kmalloc_array(32, dev->video_mode.num_alt, GFP_KERNEL);
+		kmalloc_array(dev->video_mode.num_alt,
+			      sizeof(*dev->video_mode.alt_max_pkt_size),
+			      GFP_KERNEL);
 	if (dev->video_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1648,7 +1650,9 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 
 	/* compute alternate max packet sizes for vbi */
 	dev->vbi_mode.alt_max_pkt_size =
-		kmalloc_array(32, dev->vbi_mode.num_alt, GFP_KERNEL);
+		kmalloc_array(dev->vbi_mode.num_alt,
+			      sizeof(*dev->vbi_mode.alt_max_pkt_size),
+			      GFP_KERNEL);
 	if (dev->vbi_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1691,7 +1695,9 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 		 dev->sliced_cc_mode.end_point_addr,
 		 dev->sliced_cc_mode.num_alt);
 	dev->sliced_cc_mode.alt_max_pkt_size =
-		kmalloc_array(32, dev->sliced_cc_mode.num_alt, GFP_KERNEL);
+		kmalloc_array(dev->sliced_cc_mode.num_alt,
+			      sizeof(*dev->sliced_cc_mode.alt_max_pkt_size),
+			      GFP_KERNEL);
 	if (dev->sliced_cc_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1887,7 +1893,9 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 			 dev->ts1_mode.num_alt);
 
 		dev->ts1_mode.alt_max_pkt_size =
-			kmalloc_array(32, dev->ts1_mode.num_alt, GFP_KERNEL);
+			kmalloc_array(dev->ts1_mode.num_alt,
+				      sizeof(*dev->ts1_mode.alt_max_pkt_size),
+				      GFP_KERNEL);
 		if (dev->ts1_mode.alt_max_pkt_size == NULL) {
 			retval = -ENOMEM;
 			goto err_video_alt;

-- 
2.43.0

