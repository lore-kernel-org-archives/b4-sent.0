From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 18:40:48 -0500
Subject: [PATCH] media: cx231xx: reject geometry changes while the VBI
 queue is busy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-2d1d9abc-v1-1-64d91be4c2c8@proton.me>
X-B4-Tracking: v=1; b=H4sIAICNMGoC/x3MQQqAIBBA0avErBtQKcOuEi3UmWo2FgoRSHdPW
 r7F/xUKZ+ECc1ch8y1FztSg+w7i4dPOKNQMRhmrrB4xDEhSLjSkyfkQcXIh2G30NDgHLbsyb/L
 8y2V93w+3RRjbYgAAAA==
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781566848; l=5155;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=BiygEoe8YJssSGqpdUOkvK4ARdwu4WWt7h57wNi/cIQ=;
 b=l8VtmqaYfWm/tb5Z48q/lYym8sE31BFs/dVwkyWk+1ncq0UDPd5w2/oBtXzdGJv+z1Viwkbu8
 wGJmrrVQHJTBeR0MrIpOl7rvSARUXJ0mvxRXjRjiC0yz618EOiIoWYX
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vidioc_s_fmt_vid_cap() and vidioc_s_std() change the device-wide
dev->width / dev->norm but only refuse the change when the *video* queue
(dev->vidq) is busy. The VBI queue (dev->vbiq) shares that same geometry:
cx231xx_init_vbi_isoc() latches dma_q->lines_per_field from dev->norm,
the VBI videobuf2 plane is sized from dev->width / dev->norm in
vbi_queue_setup() and vbi_buf_prepare(), and cx231xx_do_vbi_copy() then
recomputes the destination offset from the *live* dev->width and the
latched lines_per_field on every URB completion:

	offset = lines_completed * (dev->width << 1) + ...;
	if (dma_q->current_field == 2)
		offset += dev->width * 2 * dma_q->lines_per_field;
	memcpy(plane + offset, p_buffer, lencopy);

Because the VBI node shares video_ioctl_ops with the video node, an
application can size a small VBI plane (REQBUFS/QBUF with a small width,
or with the NTSC standard), then enlarge dev->width (or switch dev->norm
to PAL) through the video node while the VBI stream is running -- the
change is allowed because only dev->vidq is checked -- and let the device
deliver a field-2 VBI payload. cx231xx_do_vbi_copy() now computes the
offset with the larger geometry and memcpy()s past the end of the smaller
plane that was already allocated, a heap out-of-bounds write whose offset
is attacker-chosen and whose contents come from the device. The
per-field guard in cx231xx_copy_vbi_line() does not help: it bounds the
copy against the latched lines_per_field, not the plane's real capacity,
and vb2 does not re-run buf_prepare() for an already prepared buffer.

Refuse the format/standard change when the VBI queue is busy as well, so
the geometry cannot change underneath an allocated VBI buffer.

Fixes: 7c617138b825 ("media: cx231xx: convert to the vb2 framework")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproducer (one cx231xx device; both /dev/videoN and /dev/vbiN are bound
to the same struct cx231xx):

  1. ioctl(video_fd, VIDIOC_S_FMT, &fmt);   /* fmt.fmt.pix.width = 48  */
  2. ioctl(vbi_fd,   VIDIOC_REQBUFS, &rb);   /* allocs the VBI plane at
                                                width=48 -> ~2.3 KB     */
  3. ioctl(vbi_fd,   VIDIOC_QBUF, &buf);     /* buf->prepared = 1       */
  4. ioctl(video_fd, VIDIOC_S_FMT, &fmt);    /* fmt.fmt.pix.width = 720;
                                                vidq idle -> accepted   */
  5. ioctl(vbi_fd,   VIDIOC_STREAMON, ...);  /* lines_per_field latched */
  6. device delivers a SAV_VBI_FIELD2 line -> cx231xx_do_vbi_copy()
     writes at offset 720*2*12 = 17280 into the ~2.3 KB plane.
  (Equivalent norm trigger: S_STD NTSC -> VBI REQBUFS -> S_STD PAL on the
   video fd -> VBI STREAMON, lines_per_field latched at 18.)

Verification (faithful in-kernel reproduction of the cx231xx_do_vbi_copy
arithmetic against a separately allocated plane; x86_64, KASAN, booted
kasan.fault=report kasan_multi_shot):

  A (unpatched, diverged geometry): plane sized for width=716, copy uses
     the live width=720 at field-2 line 11:
       BUG: KASAN: slab-out-of-bounds in cx_vbi_init
       Write of size 1440 at addr ffff888115478160
       __asan_memcpy / shadow 00 .. fe fe   (192 B into the redzone)
     A norm variant (plane sized NTSC lines_per_field=12, copy latched
     PAL lines_per_field=18) reproduces the same slab-out-of-bounds write.
  B (this patch's bound applied -- clamp the copy against the plane size):
     no KASAN report, clean.
  C (control, consistent geometry): no KASAN report, clean.
  A userspace AddressSanitizer model of the same arithmetic reports a
  heap-buffer-overflow WRITE of up to ~16 KB (width=48 -> width=720) under
  both -m32 and -m64; B and C clean.

(cx231xx_s_video_encoding()/cx231xx_initialize_codec() in cx231xx-417.c)
without a queue-busy check; maintainers may want to audit that sibling for
the same shared-geometry hazard. It was not exercised here.

Note: dev->norm is also written by the cx231xx-417 MPEG encoder path
---
 drivers/media/usb/cx231xx/cx231xx-video.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-video.c b/drivers/media/usb/cx231xx/cx231xx-video.c
index 2cd4e333bc4b..70aa99fead27 100644
--- a/drivers/media/usb/cx231xx/cx231xx-video.c
+++ b/drivers/media/usb/cx231xx/cx231xx-video.c
@@ -898,7 +898,7 @@ static int vidioc_s_fmt_vid_cap(struct file *file, void *priv,
 	if (rc)
 		return rc;
 
-	if (vb2_is_busy(&dev->vidq)) {
+	if (vb2_is_busy(&dev->vidq) || vb2_is_busy(&dev->vbiq)) {
 		dev_err(dev->dev, "%s: queue busy\n", __func__);
 		return -EBUSY;
 	}
@@ -933,7 +933,7 @@ static int vidioc_s_std(struct file *file, void *priv, v4l2_std_id norm)
 	if (dev->norm == norm)
 		return 0;
 
-	if (vb2_is_busy(&dev->vidq))
+	if (vb2_is_busy(&dev->vidq) || vb2_is_busy(&dev->vbiq))
 		return -EBUSY;
 
 	dev->norm = norm;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260615-b4-disp-2d1d9abc-79bb6f5ad499

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

