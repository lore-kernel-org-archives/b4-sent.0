From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH v2 0/2] clk: amlogic: Add A9 AO clock controller
Date: Wed, 03 Jun 2026 20:17:51 +0800
Message-Id: <20260603-a9_aoclk-v2-0-f47ea616ee78@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG8bIGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNj3UTL+MT85Jxs3aSkNFNjw6TElGQzYyWg8oKi1LTMCrBR0bG1tQB
 R02h7WgAAAA==
X-Change-ID: 20260603-a9_aoclk-bbf531badc63
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780489074; l=1192;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=3b8ojS+wH3roAMNHRcDrF0wXOLt4aC7rq6QhspbwGeA=;
 b=ssW7h1gUuATez6aWv+fBCRGzJntpeuLBQ4A8Vrptr7WNRt9/TrgwUOWc2LEco4uYitv/MDWiX
 KpgiwDA5gRBAqTptP6F69TKi1eT8yDuGO/BaNym0agsgG+nAx6cSItU
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds Amlogic A9 AO clock support, including dt-binding and AO clock driver.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v2:
- Split the A9 clock driver and send the AO clock separately.
- Rename aobus to soc
- Use CLK_HW_INIT_FW_NAME to describe clk_init_data
- Use CLK_HW_INIT_PARENTS_DATA to describe clk_init_data
- Use a9_ao prefix for MESON_COMP_SEL
- Correct duandiv name
- Fix pwm b reg
- Link to v1: https://lore.kernel.org/all/20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com/

---
Jian Hu (2):
      dt-bindings: clock: Add Amlogic A9 AO clock controller
      clk: amlogic: Add A9 AO clock controller driver

 .../bindings/clock/amlogic,a9-aoclkc.yaml          |  76 ++++
 drivers/clk/meson/Kconfig                          |  13 +
 drivers/clk/meson/Makefile                         |   1 +
 drivers/clk/meson/a9-aoclk.c                       | 419 +++++++++++++++++++++
 include/dt-bindings/clock/amlogic,a9-aoclkc.h      |  76 ++++
 5 files changed, 585 insertions(+)
---
base-commit: ca89c88bcf69daca829044c638a8163d5ce47af0
change-id: 20260603-a9_aoclk-bbf531badc63

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

