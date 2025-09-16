From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v5 0/2] clk: amlogic: add video-related clocks for S4 SoC
Date: Tue, 16 Sep 2025 10:06:05 +0800
Message-Id: <20250916-add_video_clk-v5-0-e25293589601@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA3GyGgC/3XNSwrCMBSF4a2UjI3cvNrEkfsQKXlVg9VIK0Ep3
 bvRSbXV4bnw/XdAve+C79GmGFDnU+hDvOQhVgWyR305eBxc3ogCFVARgbVzdQrOx9q2J+wsk0Z
 woYBIlM218024v3u7fd7H0N9i93jnE3ld/5USwYA5+KopGWtYSbb63MZDsGsbz+jVSnTykvC5p
 9kbQ43QoqEK+NKzyStY/GfZSwbcKmKkUT88//Rq7nn2woMF4niltfz24zg+Aapg/Y1sAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757988387; l=1583;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=9kK68Xs+KCmxOIP2SAhilPIrfTsceTJZcF5LekB7CjI=;
 b=nkaxWwNE5fra2bm3s9BXD4almurc1c50e/MeIIel3z6gjw+9eMM/sYz0NEoQvw99qUNoZiwcP
 5xi9b8BjZ3jAnCPUugGo5SfS5d6mXEvuQ+pT7SKmPR3u8+p6qYRjGZi
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces new clock support for video processing components
including the encoder, demodulator and CVBS interface modules.

The related clocks have passed clk-measure verification.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
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
Chuan Liu (2):
      dt-bindings: clock: add video clock indices for Amlogic S4 SoC
      clk: amlogic: add video-related clocks for S4 SoC

 drivers/clk/meson/s4-peripherals.c                 | 206 ++++++++++++++++++++-
 .../clock/amlogic,s4-peripherals-clkc.h            |  11 ++
 2 files changed, 213 insertions(+), 4 deletions(-)
---
base-commit: 01f3a6d1d59b8e25a6de243b0d73075cf0415eaf
change-id: 20250715-add_video_clk-dc38b5459018

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

