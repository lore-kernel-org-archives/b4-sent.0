From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Tue, 13 Oct 2026 17:57:05 +0200
Subject: [PATCH] drm/panel-edp: Add AUO 0x0db3 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-panel-edp-add-auo-v1-1-c04bfe6cd9ba@canonical.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTuQxFLQq4iLaeavjkgaEluE0
 rsbdfkt3tuoohgqnbuNClarNqcGf+go3iXdwKbNFFwYvPOBsyQ8GZpZVFmWmR1cHHE8aS8DtS4
 XTPb+PS/Xv+syPhBf3xHt+wekAX0IdQAAAA==
X-Change-ID: 20261012-panel-edp-add-auo-0e0cbe39d4a6
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2251;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=GcOUJ+XVwlNhxpKGThhrQ1L3OjN6SagPdh8JW/dIx84=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzlTYMY0HJoh6TCS7xqgivi7jVcoAV0widqn/e
 rb3Tqo+oumJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas5U2AAKCRAP04sJC6ZC
 t4b+D/9KD0hyLheoUCf1djuvfU5xW6TxD2SmskPKqm4Zwf5xStma+W531yOpwJYxWkDmIGnBikP
 EhAxcnjFJu6hu2gcNJ+MQNnUaFP/g2VUPW5DCm6vl4hxi0IdTNRmY5VfjyLxRdOuVPl7TAKzQeh
 X/tULdZZufSfp+siG6Z9e+mz9mLe4ghbOTgggRU8WMQEamseGm4/tYgHwAGHdF7APqzN51P9c/l
 7otCmOOEVJ8pXMcKkN0G9ZqNHuKIgp/7MhIqdOH9hlIKR4yyLuHAnIBasYX0ykdFWcRPSpaoJ61
 LojlaPyjppb72/G2GYztEFI5v7oosV3RBL+6j4Pj9+72NEUDdA2Ev6taVpQ3WM0I2ywugEdWdX2
 cP2seuAcECumcpknEDdzCQgmVC5V+78riP+KryQKY0gP6DU2VnPw99/AVyzPrGeL49OmIfABJ4n
 Q7+Sn+XcOnLvWcD4pmyKUd9PAHfil4xDe9qDv2URQxrNVRHXU8oe26wEgUsTIw4e9tdDZPSa4aB
 B5bfJdhAzg+m8zXAUpDljNq8WhQvBTCF1EUEtMJEYASmbCJBKweEMEWTgnHVLF7C0Qe1HAvGOSs
 JiLz0XZ+O+ZZm7jYNGDKU4+qyt8NhrsmSyJMWzrnoqtINZ6iJYss28YTJdL3BQorvXJUo5VjJ4Z
 9STVmjVNcbfhSOA==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the AUO 0x0db3 eDP panel used in the HP EliteBook 6 G1q.

The EDID does not contain a product name descriptor nor detailed timings,
so list as "Unknown" and use the standard AUO power sequence delay which
works fine.

FWIW, this is likely a panel from the B140UAN series.

Raw EDID:

00 ff ff ff ff ff ff 00 06 af b3 0d 01 01 00 00
1b 22 01 04 a5 1e 13 78 03 f4 75 91 56 58 93 2a
20 50 54 00 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 0e 3d 80 a4 70 b0 32 40 30 20
35 00 2d bc 10 00 00 18 b4 28 80 a4 70 b0 32 40
30 20 35 00 2d bc 10 00 00 18 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02
00 10 3c ff 0f 3c 96 0d 0c 1e 96 00 00 20 01 e8

70 20 79 02 00 22 00 14 8b 62 02 85 7f 07 a3 00
2f 80 1f 00 af 04 31 00 02 00 04 00 25 01 09 8b
62 02 8b 62 02 28 3c 80 2b 00 0c 27 00 28 3b 00
00 27 00 28 3b 00 00 81 00 15 74 1a 00 00 03 01
28 3c 00 00 53 51 53 51 3c 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 8e 90

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 drivers/gpu/drm/panel/panel-edp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 2b455369ed70..6fb60b2b8894 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -1958,6 +1958,7 @@ static const struct edp_panel_entry edp_panels[] = {
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x0290, &delay_200_500_e50, "B140XTN07.5"),
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x04a4, &delay_200_500_e50, "B122UAN01.0"),
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x0ba4, &delay_200_500_e50, "B140QAX01.H"),
+	EDP_PANEL_ENTRY('A', 'U', 'O', 0x0db3, &delay_200_500_e50, "Unknown"),
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x105c, &delay_200_500_e50, "B116XTN01.0"),
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x1062, &delay_200_500_e50, "B120XAN01.0"),
 	EDP_PANEL_ENTRY('A', 'U', 'O', 0x125c, &delay_200_500_e50, "Unknown"),

---
base-commit: 705529dab1fa872d8b53b09c95e1b03a95573376
change-id: 20261012-panel-edp-add-auo-0e0cbe39d4a6

Best regards,
-- 
Juerg Haefliger <juerg.haefliger@canonical.com>

