From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH v2 0/2] clk: amlogic: Add A9 peripherals clock controller
Date: Wed, 03 Jun 2026 20:03:55 +0800
Message-Id: <20260603-a9_peripherals-v2-0-ee1b8c0a1e6c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACsYIGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNj3UTL+AKgloKM1KLEnGJdEyNDk1RzS3MD05RkJaCmgqLUtMwKsIH
 RsbW1AFtuaQ9gAAAA
X-Change-ID: 20260603-a9_peripherals-4214e79705dc
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780488242; l=1319;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=JkDzMQd2L4L6r0Yr9fg6b/1lXleiCN8jZ/P5N4eWY4I=;
 b=2JsWtytZuobV0Qw7gQcvTiZipvvm8BxQ3CILqhIjANBz/nZlWHk/xmAvem9fl9NgLWkkR6afE
 2kBATLbGq//C7SIfDiCVJ8u+nqhQSKOYN8Ft7jW7WhUXbJFOFsHccgg
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds Amlogic A9 peripherals clock support,
including dt-binding and peripherals clock driver.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v2:
- Split the A9 clock driver and send the peripherals clock separately.
- Add COMPILE_TEST in Kconfig
- Drop the 'optional'
- Rename apb4 to soc
- Sort the header file
- Rename hifi to hifi0
- Use CLK_HW_INIT_PARENTS_DATA to describe clk_init_data
- Use CLK_HW_INIT_HW to describe clk_init_data
- Use CLK_HW_INIT_PARENTS_HW to describe clk_init_data
- Link to v1: https://lore.kernel.org/all/20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com/

---
Jian Hu (2):
      dt-bindings: clock: Add Amlogic A9 peripherals clock controller
      clk: amlogic: Add A9 peripherals clock controller driver

 .../clock/amlogic,a9-peripherals-clkc.yaml         |  160 ++
 drivers/clk/meson/Kconfig                          |   15 +
 drivers/clk/meson/Makefile                         |    1 +
 drivers/clk/meson/a9-peripherals.c                 | 1927 ++++++++++++++++++++
 .../clock/amlogic,a9-peripherals-clkc.h            |  352 ++++
 5 files changed, 2455 insertions(+)
---
base-commit: ca89c88bcf69daca829044c638a8163d5ce47af0
change-id: 20260603-a9_peripherals-4214e79705dc

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

