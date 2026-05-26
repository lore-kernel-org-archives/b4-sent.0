From: Zhentao Guo <zhentao.guo@amlogic.com>
Date: Tue, 26 May 2026 16:40:18 +0800
Subject: [PATCH RFC RESEND v5 2/6] firmware: meson: sm: video firmware
 loading via secure monitor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260526-b4-s4-vdec-upstream-v5-2-33bc817f93f4@amlogic.com>
References: <20260526-b4-s4-vdec-upstream-v5-0-33bc817f93f4@amlogic.com>
In-Reply-To: <20260526-b4-s4-vdec-upstream-v5-0-33bc817f93f4@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, Zhentao Guo <zhentao.guo@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779784828; l=663;
 i=zhentao.guo@amlogic.com; s=20251024; h=from:subject:message-id;
 bh=2+l4DUwLwWn2GDHI6LoxkCkn7TDYkl4Sv8Q4p9SlS/E=;
 b=K7DQ71fqbh3rYm2IuWeVYzvl26czXaJUk8ABXFSly1FA93FtCy5MvdN+V97ol5CT3L/Ne6gVs
 uiXU0OZRZ+nAqzEtvPQxyrRgdqJ+VgAZoNl41CZfQc9FQaxaTCVp9fZ
X-Developer-Key: i=zhentao.guo@amlogic.com; a=ed25519;
 pk=5yfDKrjreXwcAoEUsdtWafy6YN500upXp/CgtnXjLVU=
X-Endpoint-Received: by B4 Relay for zhentao.guo@amlogic.com/20251024 with auth_id=555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SM_LOAD_VIDEO_FW to the secure monitor command enum
to allow decoder drivers to load firmware through the meson_sm
interface.

Signed-off-by: Zhentao Guo <zhentao.guo@amlogic.com>
---
 include/linux/firmware/meson/meson_sm.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/firmware/meson/meson_sm.h b/include/linux/firmware/meson/meson_sm.h
index 8eaf8922ab02..f40867a000f1 100644
--- a/include/linux/firmware/meson/meson_sm.h
+++ b/include/linux/firmware/meson/meson_sm.h
@@ -14,6 +14,7 @@ enum {
 	SM_GET_CHIP_ID,
 	SM_A1_PWRC_SET,
 	SM_A1_PWRC_GET,
+	SM_LOAD_VIDEO_FW,
 };
 
 struct meson_sm_firmware;

-- 
2.42.0

