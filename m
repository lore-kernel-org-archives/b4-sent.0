From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v6 0/3] clk: amlogic: add video-related clocks for S4 SoC
Date: Fri, 19 Sep 2025 13:58:58 +0800
Message-Id: <20250919-add_video_clk-v6-0-fe223161fb3f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACPxzGgC/3XPzWoCMRSG4VuRrBs5+TmZpKveRxHJzxkNVVNmJ
 LTI3LvRjTKjyy/wvIdc2EhDppF9ri5soJrHXE5tmI8Vi3t/2hHPqW0mQSJ0ArlPaVtzorKNhx+
 eorIBNToQljXzO1Cf/+69703b+zyey/B/z1dxe31XqoID10Bdb5TqlRFf/ngouxzXsRzZrVXlw
 1uh5142H4IM6LGXDvTSq4d3sLivmrcKdHQi2OBeeP3s3dzr5pEggki6894uPT55YeYemyeJ0im
 0zsDs/9M0XQHF8HpArAEAAA==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Chuan Liu <chuan.liu@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758261548; l=1984;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ARN6P9/X424zlXLiKTbeILtanwkQtWd4O4u45ktBDnM=;
 b=XXP6mQSo6VYw2td4KrrELnplOge6oWnhKcSZSb+u2Xr4OOmy2ahWYAZ3efQOYgziW+ySI+p7C
 kh9uYnVngwBDttGGcI1ZdGpcOzEN8UVV20TQpALs/I9Lf+4KyV+HqZ7
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces new clock support for video processing components
including the encoder, demodulator and CVBS interface modules.

The related clocks have passed clk-measure verification.

Some potentially unsafe flag configurations were identified in other
video clocks, and they are cleaned up as part of this patch series.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Changes in v6:
- Split the flag removal changes for video clocks into a separate patch.
- Link to v5: https://lore.kernel.org/r/20250916-add_video_clk-v5-0-e25293589601@amlogic.com

Changes in v5:
- Add Acked-by tags from Conor.
- Remove unnecessary flags as suggested by Jerome.
- Link to v4: https://lore.kernel.org/r/20250909-add_video_clk-v4-0-5e0c01d47aa8@amlogic.com

Changes in v4:
- Add Acked-by tags from Rob and Krzysztof.
- Fix compilation errors.
- Link to v3: https://lore.kernel.org/r/20250905-add_video_clk-v3-0-8304c91b8b94@amlogic.com

Changes in v3:
- Rebase with Jerome's latest code base.
- Link to v2: https://lore.kernel.org/r/20250814-add_video_clk-v2-0-bb2b5a5f2904@amlogic.com

Changes in v2:
- Removed lcd_an clock tree (previously used in meson series but obsolete in
newer chips).
- Removed Rob's 'Acked-by' tag due to dt-binding changes (Is it necessary?).
- Link to v1: https://lore.kernel.org/r/20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com

---
Chuan Liu (3):
      dt-bindings: clock: add video clock indices for Amlogic S4 SoC
      clk: amlogic: add video-related clocks for S4 SoC
      clk: amlogic: remove potentially unsafe flags from S4 video clocks

 drivers/clk/meson/s4-peripherals.c                 | 206 ++++++++++++++++++++-
 .../clock/amlogic,s4-peripherals-clkc.h            |  11 ++
 2 files changed, 213 insertions(+), 4 deletions(-)
---
base-commit: 01f3a6d1d59b8e25a6de243b0d73075cf0415eaf
change-id: 20250715-add_video_clk-dc38b5459018

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

