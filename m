From: Joe Finzel <joe@sudmix.de>
Date: Wed, 21 Oct 2026 18:55:02 +0200
Subject: [PATCH] drm/nouveau/gsp: skip address-only I2C starts with MOT on
 GSP-RM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-nouveau-edid-segment-v1-1-101dd5aa3ecd@sudmix.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MOwqAMBBF0a3I1A4kEb9bEQsxT53CKIkGQdy7w
 fIU9z4U4AWBuuwhjyhBdpeg84ymdXQLWGwyGWUqrYxmt18R48WwYjlg2eBOLsq6UeWkW9SglB4
 es9z/th/e9wNCX9yIZgAAAA==
X-Change-ID: 20261021-nouveau-edid-segment-357805c19e7e
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Joe Finzel <joe@sudmix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792601713; l=3093;
 i=joe@sudmix.de; s=default; h=from:subject:message-id;
 bh=oM+HRdxOHZSWOEGviI42/1A3BImx/Py3uHcns0asV/U=;
 b=jMHvMxK6yddba4p7Pt0fqga8L7DwN8eEuQoeEyw0ST+chY2TqJwgejk6gvqPWkuOMF7j+dIhd
 kwv35tkNSMiDaPEHzJvz4Xx4CmSGsIwK430y+hVswUKYGkUoWQ8e2w7
X-Developer-Key: i=joe@sudmix.de; a=ed25519;
 pk=vaX11uVm57me/1N8otNmzMMnsE+f0U3/Hi9TCPbnvZM=
X-Endpoint-Received: by B4 Relay for joe@sudmix.de/default with auth_id=1151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DRM I2C-over-AUX helper starts each I2C message with an
address-only request with MOT set. r535_dp_aux_xfer() forwards it to
GSP-RM with MOT cleared, which issues a stop on the DDC bus.

E-DDC resets the segment pointer (I2C address 0x30) on a stop. The
segment write is thus lost when the next message (offset write at 0x50)
starts, and the sink returns segment 0 again: EDID blocks 2 and 3 read
back as blocks 0 and 1. On a Dell AW2723DF connected to an RTX 3070 Ti,
block 2 is its DisplayID extension with the only 2560x1440@240Hz
timing; the kernel saw a second copy of the base block instead, and the
highest mode offered was 2560x1440@144Hz. Windows reads the correct
block from the same monitor.

Forwarding the start with MOT set instead left the display without a
signal on the same system. NVIDIA's own DisplayPort library never sends
GSP-RM an address-only request with MOT: it writes the segment and the
offset as data requests with MOT and ends with a read without it. Do
the same and skip the start; the data requests carry the address and
MOT themselves, and the address-only stop that ends a transfer is still
sent as before.

Tested on an RTX 3070 Ti (GA104, GSP-RM 570.144) with the AW2723DF over
DisplayPort: the EDID read back now matches the one Windows reads byte
for byte, and 2560x1440@240Hz is among the probed modes.

Fixes: 9e9944449023 ("drm/nouveau/disp/r535: initial support")
Cc: stable@vger.kernel.org
Signed-off-by: Joe Finzel <joe@sudmix.de>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
index f5f22173fc2..13a27476875 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
@@ -1072,6 +1072,20 @@ r535_dp_aux_xfer(struct nvkm_outp *outp, u8 type, u32 addr, u8 *data, u8 *psize)
 	int ret;
 	int retries;
 
+	/*
+	 * The DRM I2C-over-AUX helper starts each I2C message with an
+	 * address-only request with MOT set. GSP-RM is only ever given complete
+	 * requests (NVIDIA's DisplayPort library sends none of these), and
+	 * forwarding it as below, with MOT cleared, issues a stop: the sink then
+	 * resets the E-DDC segment pointer written just before, and EDID blocks
+	 * 2 and 3 read back as blocks 0 and 1. The data requests that follow
+	 * carry the address and MOT themselves, so the start can be skipped.
+	 */
+	if (!size &&
+	    NVDEF_TEST(type, NV0073_CTRL, DP_AUXCH_CMD, TYPE, ==, I2C) &&
+	    NVDEF_TEST(type, NV0073_CTRL, DP_AUXCH_CMD, I2C_MOT, ==, TRUE))
+		return 0; /* ACK */
+
 	for (retries = 0; retries < 3; ++retries) {
 		ctrl = nvkm_gsp_rm_ctrl_get(&disp->rm.objcom, NV0073_CTRL_CMD_DP_AUXCH_CTRL, sizeof(*ctrl));
 		if (IS_ERR(ctrl))

---
base-commit: fb26cf4f1df40a462ea65552a3fbcc8cfafab523
change-id: 20261021-nouveau-edid-segment-357805c19e7e

Best regards,
-- 
Joe Finzel <joe@sudmix.de>

