From: Mark Dietzer <git@doridian.net>
Date: Sun, 04 May 2025 10:54:52 -0700
Subject: [PATCH] Add GPD Pocket 2 04/17/2020 BIOS to drm_orientation_quirks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250504-gpd_pocket2_biosver-v1-1-7e2506ea723f@doridian.net>
X-B4-Tracking: v=1; b=H4sIAOupF2gC/x3MQQqAIBBA0avErBNs0IKuEhFlow1BikYE4t2Tl
 m/xf4ZEkSnB2GSI9HBif1V0bQPmWC9HgvdqQIlaaqmEC/sSvDnpxmVjnx6Kou/REio5aG2hliG
 S5fe/TnMpH9GxRTtlAAAA
X-Change-ID: 20250504-gpd_pocket2_biosver-662fe240755f
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Mark Dietzer <git@doridian.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746381419; l=1794;
 i=git@doridian.net; s=20250228; h=from:subject:message-id;
 bh=qciSeWWt/KY5XJWHB5Z6wuF+QWqEbYgWc54AWkioEmA=;
 b=4FpyCa8WlZkfO2LABvQC2VkZUqoA4A8W4lNk+VU7GoRvA7U974YvF3Ogua5cDTtwOdxChU6IY
 BtL8JQrhZjtAUxg8xOS45hL/Qsrq7HHO+TUmPrznJ0d0i1QhL6aIPMa
X-Developer-Key: i=git@doridian.net; a=ed25519;
 pk=XY9bZ7EBhoLNoRt6zd2/vutpAXC3tsX6OytpZHjbUsQ=
X-Endpoint-Received: by B4 Relay for git@doridian.net/20250228 with auth_id=353
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing BIOS version to drm_orientation_quirks for the
GPD Pocket 2

---
This seems to be the latest available offical BIOS for this machine.
I can no longer find it hosted by GPD themselves, but did find it
at least archived (on archive.org) here:
https://archive.org/download/gpd-pocket-2-drivers-and-os/driver-and-bios/

Testing and confirmed working on my own GPD Pocket 2.

Below is the output of "dmideocde", specifically the BIOS section

Handle 0x0000, DMI type 0, 24 bytes
BIOS Information
        Vendor: American Megatrends Inc.
        Version: 0.27
        Release Date: 04/17/2020
        Address: 0xF0000
        Runtime Size: 64 kB
        ROM Size: 16 MB
        Characteristics:
                [left out for clarity]
        BIOS Revision: 0.27
        Firmware Revision: 0.18

Signed-off-by: Mark Dietzer <git@doridian.net>
---
 drivers/gpu/drm/drm_panel_orientation_quirks.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_panel_orientation_quirks.c b/drivers/gpu/drm/drm_panel_orientation_quirks.c
index c554ad8f246b65a1d20237d6d52c699c8afd2329..a90ada0c7adf4f25bc58c335d1920ccd5e690a71 100644
--- a/drivers/gpu/drm/drm_panel_orientation_quirks.c
+++ b/drivers/gpu/drm/drm_panel_orientation_quirks.c
@@ -58,7 +58,7 @@ static const struct drm_dmi_panel_orientation_data gpd_pocket2 = {
 	.width = 1200,
 	.height = 1920,
 	.bios_dates = (const char * const []){ "06/28/2018", "08/28/2018",
-		"12/07/2018", NULL },
+		"12/07/2018", "04/17/2020", NULL },
 	.orientation = DRM_MODE_PANEL_ORIENTATION_RIGHT_UP,
 };
 

---
base-commit: 593bde4ca9b1991e81ccf98b0baf8499cab6cab9
change-id: 20250504-gpd_pocket2_biosver-662fe240755f

Best regards,
-- 
Mark Dietzer <git@doridian.net>

