From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sun, 26 Apr 2026 19:38:41 +0530
Subject: [PATCH] ACPI: video: force native backlight on HP OMEN 16 (8A44)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260426-omen-16-backlight-fix-v1-1-62364f268ea6@zohomail.in>
X-B4-Tracking: v=1; b=H4sIAGgc7mkC/yXM0Q5DQBCF4VeRuTYJS1Gv0rjYWYPRdjW7iES8u
 y2X30nOv4NnJ+yhjnZwvIqXyQakcQRm0LZnlDYYVKKKJFcPnL5sMS2QtHl/pB9m7GTDMuuoIpN
 rRU8I35/jMF/dV3PbLzSymf8xOI4TdT+L03kAAAA=
X-Change-ID: 20260425-omen-16-backlight-fix-73fb8bc4a2b9
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777212528; l=3008;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=Ks75/0yCMSiPZ5NGPSiLdDntV/e7UFJBadOo45wysJA=;
 b=ImzlN1NF/yjSEwdic/vHSQlDyh2HDbuxm3ilC7wHeE26rJSBVCMfn4V3XByKns2e2Sekc/Yrj
 AA+AbNfO0kDAJPvHDEDPFsh+D+binV7lvoEReIkEwJGdwwIhdYKWZAB
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP OMEN 16 Gaming Laptop (board name 8A44) has a mux-less hybrid
GPU configuration with AMD Rembrandt (Radeon 680M) and NVIDIA GA104
(RTX 3070 Ti). The internal eDP panel is wired to the AMD iGPU.

When Nouveau loads without GSP firmware, the ACPI video backlight
device (acpi_video0) gets registered alongside the native AMD
backlight (amdgpu_bl2). In this state, writes to amdgpu_bl2 update
the software brightness value but fail to change the physical panel
brightness.

Force native backlight to prevent acpi_video0 from registering.
Confirmed that booting with acpi_backlight=native resolves the issue.

Cc: stable@vger.kernel.org
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
This patch adds a DMI quirk to force native backlight control on the
HP OMEN 16 Gaming Laptop (board name 8A44), which has a mux-less
hybrid GPU configuration with AMD Rembrandt (680M iGPU) and NVIDIA
GA104 (RTX 3070 Ti).
On this laptop the internal eDP panel is wired to the AMD iGPU. The
amdgpu driver registers amdgpu_bl2 as the native backlight device.
When the Nouveau driver is loaded without GSP firmware (as is the
case on v6.17 where GSP is not the default for Ampere GPUs), writes
to amdgpu_bl2 fail silently — the brightness sysfs value updates
but the physical panel brightness does not change.
Testing:
- Tested on HP OMEN 16 with AMD Ryzen 9 6900HX + NVIDIA RTX 3070 Ti.
- On v6.17, without this quirk, brightness control is broken.
- On v6.17, booting with acpi_backlight=native restores correct
  brightness control. This patch applies that workaround
  automatically via DMI match.
- On v6.18+, the issue does not reproduce because commit
  e0ed674acbac ("drm/nouveau: Remove DRM_NOUVEAU_GSP_DEFAULT
  config") made GSP firmware the default for Ampere, which avoids
  the ACPI conflict entirely.  
I have only tested this on v6.17 and v7.0. I am leaving it to the
stable/LTS maintainers to determine whether this quirk should be
backported, as I have not verified the stability of the GSP firmware
path on intermediate releases.

Thanks,
Shivam Kalra
---
 drivers/acpi/video_detect.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/acpi/video_detect.c b/drivers/acpi/video_detect.c
index 0a3c8232d15d..458efa4fe9d4 100644
--- a/drivers/acpi/video_detect.c
+++ b/drivers/acpi/video_detect.c
@@ -916,6 +916,14 @@ static const struct dmi_system_id video_detect_dmi_table[] = {
 		DMI_MATCH(DMI_PRODUCT_NAME, "82K8"),
 		},
 	},
+	{
+	 .callback = video_detect_force_native,
+	 /* HP OMEN Gaming Laptop 16-n0xxx */
+	 .matches = {
+		DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+		DMI_MATCH(DMI_PRODUCT_NAME, "OMEN by HP Gaming Laptop 16-n0xxx"),
+		},
+	},
 
 	/*
 	 * x86 android tablets which directly control the backlight through

---
base-commit: 27d128c1cff64c3b8012cc56dd5a1391bb4f1821
change-id: 20260425-omen-16-backlight-fix-73fb8bc4a2b9

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

