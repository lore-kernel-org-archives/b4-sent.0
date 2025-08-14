From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v2 0/2] clk: amlogic: add video-related clocks for S4 SoC
Date: Thu, 14 Aug 2025 14:32:43 +0800
Message-Id: <20250814-add_video_clk-v2-0-bb2b5a5f2904@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAuDnWgC/3XMQQ6DIBCF4auYWZcGRNS66j0aYywMOqlKAw1pY
 7h7qfsu/5e8b4eAnjBAV+zgMVIgt+UoTwXoedwmZGRyQ8lLxRuh2GjMEMmgG/TyYEbL9q4qdeG
 ihfx5erT0Prxbn3um8HL+c/BR/NZ/UhSMs4pjY2sprazFdVwXN5E+a7dCn1L6AgvXnoqsAAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755153176; l=1032;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=xqoMW8XQ1IL75gw5lb1OBnSfzSjiDXCBOC9x4KnlLSU=;
 b=E9qwT/Wglp5klWxgaqu55zaf7kslbuWrgnxDSlI5uC6A/jiIeb80gLHO4L7bEWyWkeHO9fg22
 wVZO7UoAtatCXo0rYwDEQWepfMylL42p3Q3Fq2yVcudVVZI1qkWbJ1e
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces new clock support for video processing components
including the encoder, demodulator and CVBS interface modules.

The related clocks have passed clk-measure verification.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Changes in v2:
- Removed lcd_an clock tree (previously used in meson series but obsolete in
newer chips).
- Removed Rob's 'Acked-by' tag due to dt-binding changes (Is it necessary?).
- Link to v1: https://lore.kernel.org/r/20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com

---
Chuan Liu (2):
      dt-bindings: clock: add video clock indices for Amlogic S4 SoC
      clk: amlogic: add video-related clocks for S4 SoC

 drivers/clk/meson/s4-peripherals.c                 | 203 +++++++++++++++++++++
 .../clock/amlogic,s4-peripherals-clkc.h            |  11 ++
 2 files changed, 214 insertions(+)
---
base-commit: 8a65268500b00ecee5402ef9f80618ff73f30707
change-id: 20250715-add_video_clk-dc38b5459018

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

