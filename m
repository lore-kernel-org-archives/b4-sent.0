From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Fri, 13 Nov 2026 22:04:55 -0500
Subject: [PATCH] drm/panel-edp: Add LG LP129WT332166 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-sp11-panel-lgd0779-v1-1-1020a0f2f83d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bsE1UOor0aFyq4UwUYhA/HvSc
 QZmCmROwhlGVSDxI1nu0IA6Bdu5hINRfGMw2lgi6jFHIoxL4Auvw2vnBlybJzLWGT1AC2PiXd5
 /Os21fq1DhhpkAAAA
X-Change-ID: 20261113-sp11-panel-lgd0779-b11311267209
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794625502; l=2909;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=k1zdeOuZKmI346GK/WJs+LsEMnIwuG5UcbSu0sYIEIA=;
 b=uCgZPWh+NTVyBWtti2DSCdUFQRqqylx3b7GtGWNo+59m0mVMHyIJCudgKJMzTuzWzHB4otRsj
 zXiTBeA0L87DT8r6TKXUgiCs8lhP82U84fPepy8lJ+ET2nYdc3dVOEJ
X-Developer-Key: i=jimmie.lin@gmail.com; a=ed25519;
 pk=3KDRF1RQ/9A7ZUVTdRVEZnVrGltdmq1bRocsOYeXezI=
X-Endpoint-Received: by B4 Relay for jimmie.lin@gmail.com/20261011 with auth_id=1164
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the eDP LG LP129WT332166 panel used in the Microsoft
Surface Pro 11 (LCD variant).

No datasheet available. Delays were not derived from ACPI or firmware
tables. delay_200_500_e200_d200 was copied from the entry for the
closely related LG LP129WT232166 (LGD 0x06b2, Surface Pro 9 5G) which
most LGD entries also use.

Tested on Surface Pro 11 with ftrace (function_graph on
msm_dp_wait_hpd_asserted and gpio events for panel power).
Tested 22 cycles DPMS off/on, suspend/resume successfully with no prep-
are retries. HPD asserts 179-182 ms after panel power-on within the
200 ms hpd_absent.

Cross-checked that the Windows display driver qcdxkmext8380_DENidp.bin
waits 500 ms after power-off, which agrees with the 500 ms unprepare
delay.

edid-decode (hex):

00 ff ff ff ff ff ff 00 30 e4 79 07 a1 21 00 12
00 21 01 04 b5 1b 12 78 03 f0 70 aa 50 4e a8 26
0e 4f 53 00 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 fd 00 18 78 f0
f0 48 01 0a 20 20 20 20 20 20 00 00 00 fe 00 4c
47 44 5f 44 56 31 2e 30 5f 0a 20 20 00 00 00 fe
00 4c 50 31 32 39 57 54 33 33 32 31 36 36 01 48

70 20 79 02 00 20 00 19 3c e6 24 79 07 a1 21 00
12 00 17 0d 4c 50 31 32 39 57 54 33 33 32 31 36
36 21 00 1d b4 0a 26 07 40 0b 80 07 00 ac aa 50
e1 f4 a7 62 e2 0e f2 f4 52 b0 60 b0 60 99 35 13
78 26 00 09 06 00 00 00 00 00 40 00 00 22 00 28
c0 e9 0a 84 3f 0b 63 00 07 80 1f 00 7f 07 4f 00
41 00 07 00 c0 e9 0a 04 3f 0b 63 00 07 80 1f 00
7f 07 1f 08 41 00 07 00 00 00 00 00 00 00 d1 90

Assisted-by: LLM
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
This adds LGD 0x0779 panel based on similar entries for the SP9 LCD
panel (the datasheet is unavailable) and live testing based on a
v7.2.11 downstream kernel for the Surface Pro 11 with this patch.

Thanks,
---
 drivers/gpu/drm/panel/panel-edp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 3e0bdae8e272..6b9cc771e88e 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -2200,6 +2200,7 @@ static const struct edp_panel_entry edp_panels[] = {
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x05f1, &delay_200_500_e200_d200, "Unknown"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x06b2, &delay_200_500_e200_d200, "LP129WT232166"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x0778, &delay_200_500_e200_d200, "134WT1"),
+	EDP_PANEL_ENTRY('L', 'G', 'D', 0x0779, &delay_200_500_e200_d200, "LP129WT332166"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x07fe, &delay_200_500_e200_d200, "LP116WHA-SPB1"),
 
 	EDP_PANEL_ENTRY('S', 'H', 'P', 0x1511, &delay_200_500_e50, "LQ140M1JW48"),

---
base-commit: fc72cd52fb284f3707fa36a68ea5a22543a51d71
change-id: 20261113-sp11-panel-lgd0779-b11311267209

Best regards,
-- 
Haipeng Lin <jimmie.lin@gmail.com>

