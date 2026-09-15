From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH v2 0/4] drm/virtio: fix GEM object leaks on error paths
Date: Tue, 15 Sep 2026 15:39:09 +0800
Message-Id: <20260915-fixes-v2-0-a0d799e4db66@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB32qGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDS0NT3bTMitRiXYtkM0tD81RLAzMzUyWg2oKiVLAEUGl0bG0tAJP91iF
 XAAAA
X-Change-ID: 20260915-fixes-8c6917e90665
To: David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>, 
 Dmitry Osipenko <dmitry.osipenko@collabora.com>, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>, "Michael S. Tsirkin" <mst@redhat.com>, 
 Dave Airlie <airlied@gmail.com>
Cc: dri-devel@lists.freedesktop.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1536;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=X2czHbrSs18WUTeT1j+/DpL6IMrShozvKKb9NfGC9O0=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBXfHN90179brFw37+qpt7Fmt+eoMjV+P7nk3s4JO
 nJyRscL4uo7SlkYxLgYZMUUWY4XXPpm4btFd4vPlmSYOaxMIEMYuDgFYCIJAQx/hdckFe99sNTx
 R8R8lSk5FV8WXbeZXcHwuKmgaN2O9coHnzIy3M0z/2R5xODBp9l/+FmXXbHK4nXaU5tveGFSX76
 ir+xpTgBXL07U
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1 fixed one drm_gem_object_release() misuse in virtio_gpu_gem_create().
Dmitry asked for the other occurrences the Sashiko bot pointed at [1], so
v2 turns it into a series.

Patches 1-3 replace drm_gem_object_release() with drm_gem_object_put() on
the GEM creation error paths. Patch 1 is unchanged from v1.

Patch 4 adds the missing drm_gem_object_release() before kfree(vram) in
virtio_gpu_vram_create().

Only compile-tested (x86_64, CONFIG_DRM_VIRTIO_GPU=m).

[1] https://lore.kernel.org/all/55240372-c265-4b38-be94-f29a58ddbb22@collabora.com/

Changes in v2:
- Add patches 2-4 covering the other occurrences reported by the bot
  (Dmitry Osipenko)
- Link to v1: https://lore.kernel.org/r/20260815-virtgpu-gem-create-leak-v1-1-a4e9fb18caa3@outlook.com

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (4):
      drm/virtio: fix object leak when drm_gem_handle_create() fails
      drm/virtio: fix object leak in virtio_gpu_resource_create_ioctl()
      drm/virtio: fix object leaks in virtio_gpu_resource_create_blob_ioctl()
      drm/virtio: release the GEM object on virtio_gpu_vram_create() errors

 drivers/gpu/drm/virtio/virtgpu_gem.c   |  2 +-
 drivers/gpu/drm/virtio/virtgpu_ioctl.c |  6 +++---
 drivers/gpu/drm/virtio/virtgpu_vram.c  | 17 +++++++++--------
 3 files changed, 13 insertions(+), 12 deletions(-)
---
base-commit: 587858367581b9c55c3690f4e63382ad622719d4
change-id: 20260915-fixes-8c6917e90665

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

