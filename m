From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 15 Sep 2026 15:39:12 +0800
Subject: [PATCH v2 3/4] drm/virtio: fix object leaks in
 virtio_gpu_resource_create_blob_ioctl()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-fixes-v2-3-a0d799e4db66@outlook.com>
References: <20260915-fixes-v2-0-a0d799e4db66@outlook.com>
In-Reply-To: <20260915-fixes-v2-0-a0d799e4db66@outlook.com>
To: David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>, 
 Dmitry Osipenko <dmitry.osipenko@collabora.com>, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>, "Michael S. Tsirkin" <mst@redhat.com>, 
 Dave Airlie <airlied@gmail.com>
Cc: dri-devel@lists.freedesktop.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1365;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=gmVVZGqljoLUgVlULUlI1tOIf4EBWb5LQtGm6rkt9fE=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBXfnPhTbs/5prpKPvbE5ptnF9Rk6sdnvZlnn9f1d
 72ntLBV9dqOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmEhdHMP/UIW9ipqJV5Km
 /Wd8dGJ5As/5Yxmf/e07u8p8pZM3TFk1g+F/+hy9zXW5bH8spjY/9Crh+vl3g+NVdb1pOWzif47
 n/rrICwBu3U3v
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_gpu_resource_create_blob_ioctl() calls drm_gem_object_release() on
both the virtio_gpu_resource_assign_uuid() and drm_gem_handle_create()
error paths instead of dropping the reference it owns, so
obj->funcs->free() never runs and the virtio_gpu_object, the resource id
and the host-side resource are leaked.

Use drm_gem_object_put() instead.

Fixes: 897b4d1acaf5 ("drm/virtio: implement blob resources: resource create blob ioctl")
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/virtio/virtgpu_ioctl.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/virtio/virtgpu_ioctl.c b/drivers/gpu/drm/virtio/virtgpu_ioctl.c
index d16f07abb266..fcdb07a37972 100644
--- a/drivers/gpu/drm/virtio/virtgpu_ioctl.c
+++ b/drivers/gpu/drm/virtio/virtgpu_ioctl.c
@@ -557,14 +557,14 @@ static int virtio_gpu_resource_create_blob_ioctl(struct drm_device *dev,
 	if (params.blob_flags & VIRTGPU_BLOB_FLAG_USE_CROSS_DEVICE) {
 		ret = virtio_gpu_resource_assign_uuid(vgdev, bo);
 		if (ret) {
-			drm_gem_object_release(obj);
+			drm_gem_object_put(obj);
 			return ret;
 		}
 	}
 
 	ret = drm_gem_handle_create(file, obj, &handle);
 	if (ret) {
-		drm_gem_object_release(obj);
+		drm_gem_object_put(obj);
 		return ret;
 	}
 

-- 
2.51.2

