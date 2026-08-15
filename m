From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 15 Aug 2026 14:16:29 +0800
Subject: [PATCH] drm/virtio: fix object leak when drm_gem_handle_create()
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-virtgpu-gem-create-leak-v1-1-a4e9fb18caa3@outlook.com>
X-B4-Tracking: v=1; b=H4sIADwEgGoC/x3MywqDMBBG4VeRWXcgiSjBVyldhORvOnipTFQE8
 d0buvwW51xUoIJCQ3OR4pAi36XCPhqKn7BksKRqcsb1xtuOD9EtrztnzBwVYQNPCCP73pmutTG
 1yVOtV8Vbzv/5+brvH6YzuTppAAAA
X-Change-ID: 20260815-virtgpu-gem-create-leak-8620531cd3d8
To: David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>, 
 Dmitry Osipenko <dmitry.osipenko@collabora.com>, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>, Dave Airlie <airlied@gmail.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>
Cc: dri-devel@lists.freedesktop.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1922;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=+H0YnFkWSIHfk+tlYOEarUiRI6w/1HSszt61Rigu8cs=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrAYW+5uftEubcjyFuTgt3/zke+oxsVxm+uVlDR+Ov
 ntW9q28+EhHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATOQpEyPDrUf3jI7cUH64
 fFbIp5JoqZAteyWnsL588s7K8dfODL1N5gx/+Na1zvoZ8zu24c3ia81MGx8VnU913n714DxV74R
 lktKVvABoRU6s
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_gpu_gem_create() owns the reference taken by
virtio_gpu_object_create(). On the drm_gem_handle_create() error path it
calls drm_gem_object_release() instead of dropping that reference.

drm_gem_object_release() is the inverse of drm_gem_object_init() and does
not touch the reference count or call obj->funcs->free(), so it is only
correct as the last step of a destructor, as in
virtio_gpu_cleanup_object(). Using it here leaves the bo at refcount 1
with no remaining reference, so virtio_gpu_free_object() never runs and
the shmem pages, sg table and virtio_gpu_object are leaked. Since
virtio_gpu_object_create() has already set bo->created,
VIRTIO_GPU_CMD_RESOURCE_UNREF is not queued either, leaking the host-side
resource and the resource id.

drm_gem_handle_create_tail() drops the handle reference on all of its
internal error paths, so the caller only has to drop its own. Use
drm_gem_object_put(), matching the success path below.

Fixes: dc5698e80cf7 ("Add virtio gpu driver.")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/gpu/drm/virtio/virtgpu_gem.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/virtio/virtgpu_gem.c b/drivers/gpu/drm/virtio/virtgpu_gem.c
index 66c3f6f74e9c..d2f0b8a3f172 100644
--- a/drivers/gpu/drm/virtio/virtgpu_gem.c
+++ b/drivers/gpu/drm/virtio/virtgpu_gem.c
@@ -45,7 +45,7 @@ static int virtio_gpu_gem_create(struct drm_file *file,
 
 	ret = drm_gem_handle_create(file, &obj->base.base, &handle);
 	if (ret) {
-		drm_gem_object_release(&obj->base.base);
+		drm_gem_object_put(&obj->base.base);
 		return ret;
 	}
 

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260815-virtgpu-gem-create-leak-8620531cd3d8

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

