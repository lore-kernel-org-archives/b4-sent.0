From: Anuj Bolewar <bolewara@gmail.com>
Date: Sun, 02 Aug 2026 22:05:17 +0530
Subject: [PATCH v2] drm/virtio: reclaim pending vbufs before tearing down
 vqs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-virtio-gpu-reclaim-vbufs-v2-1-5767fb860691@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0K6dkzbIBZX3sOwaOsUxgAlbWk0h
 LsLeAGXL3n//YVFDISR3YqFBcwUyY8byFPBbKfHFoGeGzPJZcUVl5ApJPLQTjMEtL2mAbKZXYR
 SicpapS/G1WybTwEdvY/0o/lxnM0Lbdp7u9FRTD58ju8sdu+PmyxAQF2XVyeUkRzlvR009WfrB
 9as6/oFiy4+ldIAAAA=
X-Change-ID: 20260802-virtio-gpu-reclaim-vbufs-4816cc8a5bf9
To: David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>, 
 Dmitry Osipenko <dmitry.osipenko@collabora.com>, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, syzkaller-bugs@googlegroups.com, 
 syzbot+06f9b2a53ba4a5a47644@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785688516; l=4832;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=ip9758ecvu5Lc+AGn+NJtR1MumyMs6TZADIy4kALth8=;
 b=gueT/54Hp0J8eQ2wmW1BmksUne+9bduUi5wu1Rl2EqJkTwAsbMMASolkPJ1godpqMFGsH9RbA
 x9WXXQxaMt5BBfNnS4RKf3cxHp/iZAOI7GPyoGlTnWPEximQE3zK2so
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_gpu_free_vbufs() destroys the vbufs kmem_cache after the virtqueues
have already been released. Commands that were queued but never completed
by the device leave their vbuffers stranded in the virtqueue, so the cache
still holds live objects when virtio_gpu_deinit() tears everything down.
This triggers a WARNING in virtio_gpu_free_vbufs:

    BUG virtio-gpu-vbufs (Not tainted): Objects remaining in cache
    on __kmem_cache_shutdown()

Drain any buffers still sitting in the control and cursor virtqueues in
virtio_gpu_deinit() after the device has been reset and before the
virtqueues are deleted, following the same pattern used by virtio_console's
remove_vqs(). Each reclaimed buffer is released with free_vbuf(), dropping
the reference on any GEM objects it holds. Pending RESOURCE_UNREF
commands are handled as well: their resp_cb_data still references a GEM
object, so it is cleaned up with virtio_gpu_cleanup_object() to avoid
leaking it on teardown.

Reported-by: syzbot+06f9b2a53ba4a5a47644@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=06f9b2a53ba4a5a47644
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
This series fixes a syzbot-triggered WARNING in virtio_gpu_free_vbufs
(cache object: virtio-gpu-vbufs) seen on device removal. Commands that
are queued but never complete leave vbuffers stranded in the control and
cursor virtqueues. virtio_gpu_deinit() reset the device and deleted the
virtqueues without draining them, so a later kmem_cache_destroy() in
virtio_gpu_release() ran with live objects still allocated.

Patch 1 drains the queues in virtio_gpu_deinit(): after the device reset
and before del_vqs(), virtio_gpu_reclaim_vbufs() detaches every unused
buffer from both virtqueues, releases their object arrays, and runs the
pending resource-unref cleanup so the referenced GEM objects are freed
rather than leaked. This mirrors the drain pattern used by
virtio_console's remove_vqs().

Link: https://syzkaller.appspot.com/bug?extid=06f9b2a53ba4a5a47644
---
Changes in v2:
- Also release the GEM object referenced by vbuf->resp_cb_data when
  reclaiming stranded buffers, so pending RESOURCE_UNREF commands do not
  leak their underlying objects on teardown.
- Link to v1: https://patch.msgid.link/20260802-virtio-gpu-reclaim-vbufs-v1-1-9947f18b20e2@gmail.com
---
 drivers/gpu/drm/virtio/virtgpu_drv.h |  1 +
 drivers/gpu/drm/virtio/virtgpu_kms.c |  1 +
 drivers/gpu/drm/virtio/virtgpu_vq.c  | 15 +++++++++++++++
 3 files changed, 17 insertions(+)

diff --git a/drivers/gpu/drm/virtio/virtgpu_drv.h b/drivers/gpu/drm/virtio/virtgpu_drv.h
index 7449907754a..3e491c80873 100644
--- a/drivers/gpu/drm/virtio/virtgpu_drv.h
+++ b/drivers/gpu/drm/virtio/virtgpu_drv.h
@@ -332,6 +332,7 @@ void virtio_gpu_array_put_free_work(struct work_struct *work);
 /* virtgpu_vq.c */
 int virtio_gpu_alloc_vbufs(struct virtio_gpu_device *vgdev);
 void virtio_gpu_free_vbufs(struct virtio_gpu_device *vgdev);
+void virtio_gpu_reclaim_vbufs(struct virtio_gpu_device *vgdev);
 void virtio_gpu_cmd_create_resource(struct virtio_gpu_device *vgdev,
 				    struct virtio_gpu_object *bo,
 				    struct virtio_gpu_object_params *params,
diff --git a/drivers/gpu/drm/virtio/virtgpu_kms.c b/drivers/gpu/drm/virtio/virtgpu_kms.c
index b4329f28e97..e5a6ae679f3 100644
--- a/drivers/gpu/drm/virtio/virtgpu_kms.c
+++ b/drivers/gpu/drm/virtio/virtgpu_kms.c
@@ -298,6 +298,7 @@ void virtio_gpu_deinit(struct drm_device *dev)
 	flush_work(&vgdev->cursorq.dequeue_work);
 	flush_work(&vgdev->config_changed_work);
 	virtio_reset_device(vgdev->vdev);
+	virtio_gpu_reclaim_vbufs(vgdev);
 	vgdev->vdev->config->del_vqs(vgdev->vdev);
 }
 
diff --git a/drivers/gpu/drm/virtio/virtgpu_vq.c b/drivers/gpu/drm/virtio/virtgpu_vq.c
index e5e1af8b8e8..ab6106f4bdf 100644
--- a/drivers/gpu/drm/virtio/virtgpu_vq.c
+++ b/drivers/gpu/drm/virtio/virtgpu_vq.c
@@ -208,6 +208,21 @@ static void free_vbuf(struct virtio_gpu_device *vgdev,
 	kmem_cache_free(vgdev->vbufs, vbuf);
 }
 
+void virtio_gpu_reclaim_vbufs(struct virtio_gpu_device *vgdev)
+{
+	struct virtio_gpu_vbuffer *vbuf;
+
+	while ((vbuf = virtqueue_detach_unused_buf(vgdev->ctrlq.vq))) {
+		if (vbuf->objs)
+			virtio_gpu_array_put_free(vbuf->objs);
+		if (vbuf->resp_cb_data)
+			virtio_gpu_cleanup_object(vbuf->resp_cb_data);
+		free_vbuf(vgdev, vbuf);
+	}
+	while ((vbuf = virtqueue_detach_unused_buf(vgdev->cursorq.vq)))
+		free_vbuf(vgdev, vbuf);
+}
+
 static void reclaim_vbufs(struct virtqueue *vq, struct list_head *reclaim_list)
 {
 	struct virtio_gpu_vbuffer *vbuf;

---
base-commit: 2d2338c93da79b3bfe4b6099a931d9468d539952
change-id: 20260802-virtio-gpu-reclaim-vbufs-4816cc8a5bf9

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

