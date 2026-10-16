From: Sergey Armodin <dolph-in@yandex.ru>
Date: Fri, 16 Oct 2026 21:21:31 +0700
Subject: [PATCH] drm/amdgpu: reset VI ASIC on MacBookPro14,3 with Radeon
 Pro 560
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261016-amdgpu-pro560-quirk-v1-1-3e5d3fe5ff29@yandex.ru>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJp5ESvYpxge0AgxHq1BoSw
 t2psnyL/1dIrMIJrtUKyl9JMk8FdKrAD+3UM0ooBmusI0MO21foY8aoc+0MvrPoE5tQU+jIW3e
 +QCmjcifL/3q7H075MbL//FawbTv/umMMdwAAAA==
X-Change-ID: 20261016-amdgpu-pro560-quirk-7d51df1c2649
To: amd-gfx@lists.freedesktop.org
Cc: Sergey Armodin <dolph-in@yandex.ru>, 
 =?utf-8?q?Francisco_Beltr=C3=A1n_Millal=C3=A9n?= <fbeltranmillalen@gmail.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Alex Deucher <alexander.deucher@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792160491; l=2939;
 i=dolph-in@yandex.ru; s=20261016; h=from:subject:message-id;
 bh=b/4Sa1kJnEP0nzwhtI/lrU8C3VwvseWg4I5tjfSF6S0=;
 b=s7FoqV2n3ug2q870bLxKdP533iO39HM0D9UWSUMw33b4WpDKYwQifJvmgeJFtRgxQJs3yTvt/
 80qh79j2e3jCja9hXnzZHh8uIZcLq2SmjwUG26kfYq/Zsg+MhH9ASHV
X-Developer-Key: i=dolph-in@yandex.ru; a=ed25519;
 pk=/5fxDh8OvR0Ye0oOUwYm3G0Ly9E3XSQq8qmh+T+is1g=
X-Endpoint-Received: by B4 Relay for dolph-in@yandex.ru/20261016 with auth_id=1212
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MacBookPro14,3 also ships with a Radeon Pro 560 (Polaris11,
1002:67ef, subsystem 106b:0179, revision c0), which has the same problem
as the Radeon Pro 555 added in commit a22e5e4f2ebb ("drm/amdgpu: reset
VI ASIC on MacBookPro14,3"): the firmware leaves the framebuffer at MC
address 0 at boot (MC_VM_FB_LOCATION = 0x00ff0000, 4 GiB of VRAM), while
a re-POST through the VBIOS ASIC_Init table places it at 0xF4_0000_0000
(0xf4fff400), so a GPU reset, or the S3 resume described there, moves it
under the driver.

Add this variant to the VI reset quirk table.

Tested on a MacBookPro14,3 with this Radeon Pro 560 on 7.2.5 with
commit a5be7ad8f5f0 ("drm/amdgpu: reset VI ASIC on MacBookPro15,1") and
the 555 commit backported (the kernel also carries distribution patches
and machine-local workarounds for its BCM43602 Wi-Fi and T1).

Without this entry the framebuffer is at 0x0000000000000000 on every
boot, and a GPU reset forced through amdgpu_gpu_recover fails: after the
re-POST MC_VM_FB_LOCATION reads 0xf4fff400 while the driver still puts
the GART table at 0x0000000001B00000, the IOMMU reports DMA read faults
from the GPU, and the SMU firmware load fails ("SMU load firmware
failed", then "GPU reset end with ret = -22"), leaving the internal
panel black.

With it, amdgpu logs a PCI CONFIG reset on load and the framebuffer is
at 0x000000F400000000 after both cold and warm boot.  The same forced
GPU reset completes ("GPU reset(1) succeeded!") without SMU errors or
IOMMU faults, followed by two "ring gfx timeout, but soft recovered"
messages, and the GPU came back from 14 S3 cycles (4 lid close,
3 systemctl suspend, 7 rtcwake) with no amdgpu errors; the internal
panel was back after each lid-close resume.

Cc: Francisco Beltrán Millalén <fbeltranmillalen@gmail.com>
Cc: stable@vger.kernel.org # 6.12.x
Assisted-by: LLM
Signed-off-by: Sergey Armodin <dolph-in@yandex.ru>
---
The kernel logs of both forced-reset runs (with and without this entry)
and of the S3 cycles are available if they help.
---
 drivers/gpu/drm/amd/amdgpu/vi.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/amd/amdgpu/vi.c b/drivers/gpu/drm/amd/amdgpu/vi.c
index a0435fd..ac26641 100644
--- a/drivers/gpu/drm/amd/amdgpu/vi.c
+++ b/drivers/gpu/drm/amd/amdgpu/vi.c
@@ -1398,6 +1398,7 @@ static const struct vi_reset_quirk vi_reset_quirks[] = {
 	{ 0x67ef, PCI_VENDOR_ID_APPLE, 0x0190, 0xe3 }, /* Radeon Pro 555X */
 	{ 0x67ef, PCI_VENDOR_ID_APPLE, 0x018f, 0xc2 }, /* Radeon Pro 560X */
 	{ 0x67ef, PCI_VENDOR_ID_APPLE, 0x017a, 0xc7 }, /* Radeon Pro 555 */
+	{ 0x67ef, PCI_VENDOR_ID_APPLE, 0x0179, 0xc0 }, /* Radeon Pro 560 */
 };
 
 static bool vi_need_reset_on_init(struct amdgpu_device *adev)

---
base-commit: f307e9d20cc7bd6dd54a3fd8c2af767dd7ef2931
change-id: 20261016-amdgpu-pro560-quirk-7d51df1c2649

Best regards,
--  
Sergey Armodin <dolph-in@yandex.ru>

