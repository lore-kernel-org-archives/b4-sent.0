From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 24 May 2025 11:19:09 +0200
Subject: [PATCH v3 2/6] drm/panel-edp: add N160JCE-ELL CMN panel for Lenovo
 Thinkbook 16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250524-tb16-dt-v3-2-17e26d935e73@oldschoolsolutions.biz>
References: <20250524-tb16-dt-v3-0-17e26d935e73@oldschoolsolutions.biz>
In-Reply-To: <20250524-tb16-dt-v3-0-17e26d935e73@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, linux-usb@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748078352; l=1516;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=tHgac9hVQDbAaXNwsVj/n84C1GFybdnTbmVUs8xBXGE=;
 b=/8UFrqByg0mrieUk3yMAUUIrl0E/UZ1a0wAIb4reDpuqJnN3GPadDXgqdfZn7cBjOM7oR+Ms+
 7R08QqyfqOoAnNLxiN0VLx/KrrgbYA+pScVORVggiOMbNxP8zUH6FRA
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Panel is widely used in 16" laptops, and also in my Thinkbook 16 G7 QOY.

CMN N160JCE-ELL EDID
edid-decode (hex):

00 ff ff ff ff ff ff 00 0d ae 2b 16 00 00 00 00
20 20 01 04 a5 22 16 78 03 28 65 97 59 54 8e 27
1e 50 54 00 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 42 3c 80 a0 70 b0 24 40 30 20
a6 00 58 d7 10 00 00 18 35 30 80 a0 70 b0 24 40
30 20 a6 00 58 d7 10 00 00 18 00 00 00 fd 00 28
3c 4b 4b 10 01 0a 20 20 20 20 20 20 00 00 00 fe
00 4e 31 36 30 4a 43 45 2d 45 4c 4c 0a 20 00 95

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/gpu/drm/panel/panel-edp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 90e8c154a9788ad40e2101fdf39cbd92f2e0773a..ec9622e0a313f4a228618f119e2aaa812f63d5a4 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -1973,6 +1973,7 @@ static const struct edp_panel_entry edp_panels[] = {
 	EDP_PANEL_ENTRY('C', 'M', 'N', 0x14d4, &delay_200_500_e80_d50, "N140HCA-EAC"),
 	EDP_PANEL_ENTRY('C', 'M', 'N', 0x14d6, &delay_200_500_e80_d50, "N140BGA-EA4"),
 	EDP_PANEL_ENTRY('C', 'M', 'N', 0x14e5, &delay_200_500_e80_d50, "N140HGA-EA1"),
+	EDP_PANEL_ENTRY('C', 'M', 'N', 0x162b, &delay_200_500_e80_d50, "N160JCE-ELL"),
 
 	EDP_PANEL_ENTRY('C', 'S', 'O', 0x1200, &delay_200_500_e50_p2e200, "MNC207QS1-1"),
 	EDP_PANEL_ENTRY('C', 'S', 'O', 0x1413, &delay_200_500_e50_p2e200, "MNE007JA1-2"),

-- 
2.48.1

