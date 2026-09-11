From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Subject: [PATCH RFC 00/10] arm64: qcom: sm6125-ginkgo: display, backlight,
 and touch support
Date: Fri, 11 Sep 2026 11:50:57 +0300
Message-Id: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPHAo2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0ND3fTMvOz0fN3i0qTczGKQat20zLzEHF0zcwPjJAtjUwNjU3MloO6
 CotS0zAqwydFKQW7OSrG1tQANxwocbgAAAA==
X-Change-ID: 20260911-ginkgo-submission-final-6703b8350357
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=6606;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=tXGlROxpJEoJs8ys8hL2wCVQSvGrnJqMHuLMf6SWryw=;
 b=F9sCtUdsZnrbTxUweRexehtvWmh7jODfw2hugXQy5LvdLtntAotU0HIT7olWxdAPKyTfFnW8p
 +S2m6ZLHc5eBimxf9ju4MCs5vuc/fqeRi0c2q5huyTRgrX2W6cS/ehk
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This RFC series introduces full display, backlight, and touchscreen support
for the Xiaomi Redmi Note 8 ("ginkgo"), based on the Qualcomm SM6125 platform.

Hardware architecture summary:
1. Kinetic KTD3136 3-channel 11-bit I2C LED backlight driver.
2. Novatek NT36672A TDDI controller driving a 1080x2340 FHD+ video-mode DSI panel.
3. Novatek NT36672A SPI touchscreen interface (co-packaged within the TDDI
   controller, sharing physical reset and power lines with the display panel).
4. Qualcomm DPU 5.4 / DSI display subsystem on SM6125.

-------------------------------------------------------------------------------
RFC / Open Review Questions
-------------------------------------------------------------------------------

1. Panel Compatible Naming:
   - The compatible used in this series is `tianma,fhd-video-ginkgo`.
   - THIS IS AN OPEN REVIEW QUESTION. An authoritative Tianma module part
     number (e.g. TMxxxx) is not currently known or visible on accessible
     hardware markings for this OEM display module.
   - This compatible is NOT claimed as established upstream naming. We welcome
     maintainer guidance on whether to retain `tianma,fhd-video-ginkgo`, standardize
     on a board-specific or controller-specific fallback, or use an alternate convention.

2. External Touchscreen Firmware:
   - The Novatek NT36672A touchscreen controller requires SRAM firmware download.
   - Firmware is dynamically requested via request_firmware() using the name
     "novatek/nt36672a_tianma.bin" (118,784 bytes).
   - This firmware is externally loaded from userspace filesystem and NOT
     included in the kernel patches.

3. SM6125 DPU Programmable Fetch Delay:
   - On the tested SM6125 hardware, video mode output empirically requires the
     programmable fetch start counter to be offset by one horizontal total line
     (fetch_start += horiz_total).
   - Without this offset, the hardware suffers immediate DSI FIFO/TIMEOUT status=5
     errors and fails to display pixels.
   - Patch 7 models this via a catalog quirk `has_prg_fetch_delay` for SM6125.
     Reviewer feedback on whether this should be catalog-driven or handled in the
     encoder layer is appreciated.

4. MSM DSI Host Link vs Video Streaming Separation:
   - Patch 9 separates host link enable (atomic_pre_enable) from video stream
     enable (atomic_enable) to allow video-mode panels to accept DCS initialization
     packets before active pixel transmission begins.
   - Patch 8 enforces mutual exclusion between command and video modes.

-------------------------------------------------------------------------------
Physical Hardware Validation Summary
-------------------------------------------------------------------------------

Validation on physical Xiaomi Redmi Note 8 (SM6125) hardware:
- Display / DRM: Console text and graphical output verified crisp and stable.
- Backlight: Kinetic KTD3136 11-bit brightness scaling (0..2047) verified.
- Touchscreen: Continuous 10-second user interaction confirmed smooth 60 Hz event
  flow (985 hardware interrupts, 5034 EV_ABS events, 536 SYN_REPORT frames,
  median interval 8.36 ms).
- Lifecycle / Stress:
  * 10 / 10 consecutive isolated display OFF -> ON cycles PASSED with active
    touch verified responsive after wake on every cycle.
  * Rapid power-button spam stress PASSED without wedging display or power daemon.
  * Zero DSI FIFO errors, zero firmware load timeouts (-110, -5).

-------------------------------------------------------------------------------
Series Structure
-------------------------------------------------------------------------------

Patch 01: dt-bindings: backlight: add Kinetic KTD3136
Patch 02: backlight: add Kinetic KTD3136 driver
Patch 03: dt-bindings: display: panel: novatek,nt36672a: add Tianma FHD+ video mode variant
Patch 04: drm/panel: novatek-nt36672a: add Tianma FHD+ video mode panel
Patch 05: dt-bindings: input: touchscreen: add Novatek NT36672A SPI touchscreen
Patch 06: Input: novatek-nt36672a-spi: add driver for Novatek NT36672A SPI touchscreen
Patch 07: drm/msm/dpu: describe SM6125 programmable-fetch delayed-start quirk
Patch 08: drm/msm/dsi: make command and video mode configuration mutually exclusive
Patch 09: drm/msm/dsi: separate host link enable from video stream enable
Patch 10: arm64: dts: qcom: sm6125-xiaomi-ginkgo: enable display, backlight and touchscreen

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
YİĞİTCAN KAVAKLI (10):
      dt-bindings: backlight: add Kinetic KTD3136
      backlight: add Kinetic KTD3136 driver
      dt-bindings: display: panel: novatek,nt36672a: add Tianma FHD+ video mode variant
      drm/panel: novatek-nt36672a: add Tianma FHD+ video mode panel
      dt-bindings: input: touchscreen: add Novatek NT36672A SPI touchscreen
      Input: novatek-nt36672a-spi: add driver for Novatek NT36672A SPI touchscreen
      drm/msm/dpu: describe SM6125 programmable-fetch delayed-start quirk
      drm/msm/dsi: make command and video mode configuration mutually exclusive
      drm/msm/dsi: separate host link enable from video stream enable
      arm64: dts: qcom: sm6125-xiaomi-ginkgo: enable display, backlight and touchscreen

 .../bindings/display/panel/novatek,nt36672a.yaml   |   1 +
 .../input/touchscreen/novatek,nt36672a-spi.yaml    |  66 ++
 .../bindings/leds/backlight/kinetic,ktd3136.yaml   |  65 ++
 .../boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi | 100 +++
 .../gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h |   1 +
 .../gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c   |  11 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h     |   2 +
 drivers/gpu/drm/msm/dsi/dsi.h                      |   1 +
 drivers/gpu/drm/msm/dsi/dsi_host.c                 |  29 +-
 drivers/gpu/drm/msm/dsi/dsi_manager.c              |  20 +
 drivers/gpu/drm/panel/panel-novatek-nt36672a.c     | 141 ++++-
 drivers/input/touchscreen/Kconfig                  |  11 +
 drivers/input/touchscreen/Makefile                 |   1 +
 drivers/input/touchscreen/novatek-nt36672a-spi.c   | 674 +++++++++++++++++++++
 drivers/video/backlight/Kconfig                    |  12 +
 drivers/video/backlight/Makefile                   |   1 +
 drivers/video/backlight/ktd3136-backlight.c        | 262 ++++++++
 17 files changed, 1362 insertions(+), 36 deletions(-)
---
base-commit: 893e11787f78e43b534e252249ac3fff4d1333f8
change-id: 20260911-ginkgo-submission-final-6703b8350357

Best regards,
-- 
YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>

