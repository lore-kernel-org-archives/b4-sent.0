From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/2] clk: amlogic: add video-related clocks for S4 SoC
Date: Tue, 15 Jul 2025 20:51:37 +0800
Message-Id: <20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANlOdmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0NT3cSUlPiyzJTU/PjknGzdlGRjiyRTE1NLA0MLJaCegqLUtMwKsHn
 RsbW1AAXN6ehfAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752583900; l=744;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=yFg2ugs8HM/Q5rNkrVSdyOTr/8/Q68sOdBl3U9jUuK8=;
 b=W4jZvTGQHOHnuF5HvnTlxXyeeoF86/ruiJc65Bn+nIcrd9WrmBfPCnjbAanuw4uT5pIFFhF9J
 mc0bndzU4E1AHtMxH9tcsskTF7giz0GZPo3RaUwVV1hGhXjJS/rdV0g
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces new clock support for video processing components
including the encoder, demodulator and CVBS interface modules.

The related clocks have passed clk-measure verification.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (2):
      dt-bindings: clock: add video clock indices for Amlogic S4 SoC
      clk: amlogic: add video-related clocks for S4 SoC

 drivers/clk/meson/s4-peripherals.c                 | 256 +++++++++++++++++++++
 .../clock/amlogic,s4-peripherals-clkc.h            |  14 ++
 2 files changed, 270 insertions(+)
---
base-commit: 8a65268500b00ecee5402ef9f80618ff73f30707
change-id: 20250715-add_video_clk-dc38b5459018

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

