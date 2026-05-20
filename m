From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Wed, 20 May 2026 18:40:05 +0200
Subject: [PATCH 01/11] drm/panel: edp: Add LG LP129WT232166 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260520-surface-sp9-5g-for-next-v1-1-9df52552bf87@gmail.com>
References: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
In-Reply-To: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779295238; l=1891;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=tHgNfvGMlnmFZXZkNh+6YfvXvVf/DcuqMDaolZYKux8=;
 b=G/9cCj3ftv34zFnJlbaPYRueYnY93DaRgqWvlQmn4g8AN4468H6z5LNKpCulkpXEHlhv/FEYw
 AZCDq7GoWC2AYPBdFB48f2yYeFpzFBCtzxI26eYDx04W7qgBCXU667Z
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the eDP LG LP129WT232166 panel used in
the Microsoft Surface Pro 9 5G.

edid-decode (hex):

00 ff ff ff ff ff ff 00 30 e4 b2 06 a1 25 10 00
00 1f 01 04 a5 1b 12 78 01 ef 70 a7 51 4c a8 26
0e 4f 53 00 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 fd 00 18 78 f1
f1 48 01 0a 20 20 20 20 20 20 00 00 00 fe 00 4c
47 44 5f 4d 50 31 2e 30 5f 0a 20 20 00 00 00 fe
00 4c 50 31 32 39 57 54 32 33 32 31 36 36 01 23

70 13 79 00 00 03 01 14 56 16 01 88 3f 0b 4f 00
07 80 1f 00 7f 07 55 00 47 00 07 00 03 01 14 56
16 01 08 3f 0b 4f 00 07 80 1f 00 7f 07 2b 08 47
00 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 2c 90

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 drivers/gpu/drm/panel/panel-edp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 679f4af5246d8a984387002c3fb0c6283cc21cb2..7eff79e80fa0578755a0b688cf792f58d8abcbe5 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -2080,6 +2080,7 @@ static const struct edp_panel_entry edp_panels[] = {
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x0567, &delay_200_500_e200_d200, "Unknown"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x05af, &delay_200_500_e200_d200, "Unknown"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x05f1, &delay_200_500_e200_d200, "Unknown"),
+	EDP_PANEL_ENTRY('L', 'G', 'D', 0x06b2, &delay_200_500_e200_d200, "LP129WT232166"),
 	EDP_PANEL_ENTRY('L', 'G', 'D', 0x0778, &delay_200_500_e200_d200, "134WT1"),
 
 	EDP_PANEL_ENTRY('S', 'H', 'P', 0x1511, &delay_200_500_e50, "LQ140M1JW48"),

-- 
2.47.3

