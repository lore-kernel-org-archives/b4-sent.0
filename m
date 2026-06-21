From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 21:43:34 -0500
Subject: [PATCH] drm/virtio: bound EDID block reads to the response buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-22bba7bf-v1-1-b95924cee742@proton.me>
X-B4-Tracking: v=1; b=H4sIANVPN2oC/x3MMQqAMAxA0atIZgMxSiteRRyMTTWLSgsiiHe3O
 L7h/weyJtMMQ/VA0suyHXtBU1ewbPO+KlooBiZ25JhQOgyWT2QWmb1E7HzoKdJCfStQsjNptPt
 fjtP7fhCInU5iAAAA
To: Dmitry Osipenko <dmitry.osipenko@collabora.com>, 
 David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>
Cc: linux-kernel@vger.kernel.org, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, dri-devel@lists.freedesktop.org, 
 virtualization@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782009813; l=1599;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=XxBP3LnfnnuW9zu82lhaoZrAWbBKUMrGJ5tj8DbRz74=;
 b=0R3EVoEafhlGW7lqeKCkN4SzQtVGL/H6D18PLmGpAR926B+ckGp8vn9XX0ehwqyK8ee9tC7Ox
 wuLEqpZmfwTAGGt6EJ8nS2DucwWBoHEeE/jssXW1gjNYz0bYrT1Czmr
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virtio_get_edid_block() validates the read offset only against the
device-supplied resp->size field, never against the fixed-size resp->edid
array. The EDID block index is driven by the device-supplied extension
count, so a malicious virtio-gpu backend can advertise a large size
together with a high block count and read far past the array into adjacent
kernel memory, which is then surfaced in the parsed EDID (an out-of-bounds
read / info leak).

Also reject any read whose end exceeds the size of the edid array.
Conforming EDID responses stay within the array and are unaffected.

Fixes: b4b01b4995fb ("drm/virtio: add edid support")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/gpu/drm/virtio/virtgpu_vq.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/virtio/virtgpu_vq.c b/drivers/gpu/drm/virtio/virtgpu_vq.c
index 67865810a2e7..c8b9475a7472 100644
--- a/drivers/gpu/drm/virtio/virtgpu_vq.c
+++ b/drivers/gpu/drm/virtio/virtgpu_vq.c
@@ -897,7 +897,8 @@ static int virtio_get_edid_block(void *data, u8 *buf,
 	struct virtio_gpu_resp_edid *resp = data;
 	size_t start = block * EDID_LENGTH;
 
-	if (start + len > le32_to_cpu(resp->size))
+	if (start + len > le32_to_cpu(resp->size) ||
+	    start + len > sizeof(resp->edid))
 		return -EINVAL;
 	memcpy(buf, resp->edid + start, len);
 	return 0;

---
base-commit: 1a3746ccbb0a97bed3c06ccde6b880013b1dddc1
change-id: 20260620-b4-disp-22bba7bf-47d80f0c083b

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

