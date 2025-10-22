From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/3] clk: amlogic: optimize the PLL driver
Date: Wed, 22 Oct 2025 14:58:50 +0800
Message-Id: <20251022-optimize_pll_driver-v1-0-a275722fb6f4@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKqA+GgC/x3MywqAIBBA0V+JWSeo9P6VCCmdaqCHjBFR9O9Jy
 7O494GATBigSR5gPCnQvkWoNAE799uEglw0aKlzJbUUuz9opRuNXxbjmE5kUQ441qoqC5spiKV
 nHOn6r233vh/2hlFmZQAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761116340; l=880;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=AD9HSHNdMY0OM9nnzoBOYxn8pv3LYh4EXRbZNlxGZDY=;
 b=kxSqjlsNE/85yLqBjRjfLRykrNWn7ajZhDatN3y6+Uqup7ZGGj2wCQC38UPxyBoTzrGMwIpCI
 lqHa5F1aU8TANQvaBZLFNKRSHEx3VozY1u8BZQvzMATv8LCUjF0UH82
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series consists of three topics involving the amlogic PLL
driver:
- Fix out-of-range PLL frequency setting
- Optimize PLL enable timing
- Correct l_detect bit control

For easier review and management, these are submitted as a single
patch series.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (3):
      clk: amlogic: Fix out-of-range PLL frequency setting
      clk: amlogic: Optimize PLL enable timing
      clk: amlogic: Correct l_detect bit control

 drivers/clk/meson/a1-pll.c  |  1 +
 drivers/clk/meson/clk-pll.c | 76 ++++++++++++++++++++++++++++-----------------
 drivers/clk/meson/clk-pll.h |  2 ++
 3 files changed, 51 insertions(+), 28 deletions(-)
---
base-commit: 01f3a6d1d59b8e25a6de243b0d73075cf0415eaf
change-id: 20251020-optimize_pll_driver-7bef91876c41

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

