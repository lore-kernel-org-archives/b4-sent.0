From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/5] clk: support arbitrary clk_register() sequence
Date: Thu, 01 Jan 2026 03:52:46 +0800
Message-Id: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA9/VWkC/3XMQQ7CIBRF0a00fywGUFroyH2YDgj9WNJaGkCia
 di72LnD+5J3dogYHEbomx0CZhedX2vwUwNm0usDiRtrA6dc0JYzYpaZBNx0wDURqcZO2FZLpAr
 qZQto3fvg7kPtycXkw+fQM/utf6DMCCVXqTvL7YUZoW7+lRbv57PxTxhKKV8RirxsqgAAAA==
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210768; l=2298;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=mSu9TmXAvfG7agAICGA9sCQanawvbrUqjTizOlYNKFw=;
 b=JmGI2ZSWzxrd2RKgBTV0fgd/wT6gStN1GmbjFfD1ZplWdsiMFtjiDKcGvYLg4SH4qVy7w2Ani
 Mg2VqwcpZnmBkIC22M+wvDwEX9FExyhjTLRypPnPopxkaipgsdmGWcp
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the U-Boot clk framework mandates that clock registration
begins at the root and proceeds to children. This creates an additional
requirement that does not exist in the Linux kernel, making the porting
of clk drivers more difficult.

This series handles the dependency entirely within the clk framework,
allowing drivers the freedom to register clocks in any order.

This is achieved by assigning the parent "lazily". The framework caches
the parent name in the core clk struct and attempts to resolve the
actual parent when clk consumers call clk_get_parent(). The process is
transparent to clk consumers as long as they use standard clk framework
APIs.

I've run `ut dm clk*` and verified these commits do not break any
existing test cases. It also passes the new test case.

This feature is disabled for xPLs by default. I have not found a clean
way to enable this separately for xPLs without introducing a repetitive
Kconfig entry (e.g., xPL_CLK_LAZY_REPARENT), which looks very ugly.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- tests: add a simple test for this feature
- clk: restrict this feature to only U-Boot proper, excluding xPLs from
  support (Tom)
- clk: some minor tweaks that should not matter too much
- Link to v1: https://lore.kernel.org/r/20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com

---
Yang Xiwen (5):
      drivers: core: device: set new parent when old parent is NULL
      clk: add uclass id check to clk_get_parent()
      clk: use clk_get_parent() helper in clk_en(dis)able()
      clk: allow assigning parent lazily
      test: clk: add test for CLK_LAZY_REPARENT

 drivers/clk/Kconfig           | 12 ++++++++
 drivers/clk/clk-uclass.c      | 72 +++++++++++++++++++++++++++++++++++--------
 drivers/clk/clk.c             | 14 +++++++--
 drivers/clk/clk_sandbox_ccf.c | 10 ++++++
 drivers/core/device.c         |  5 +++
 include/clk.h                 |  2 ++
 include/sandbox-clk.h         |  2 ++
 test/dm/clk_ccf.c             | 29 +++++++++++++++++
 8 files changed, 132 insertions(+), 14 deletions(-)
---
base-commit: 721eecd9cbf2cc59c5230abd37d02d4a02f75cc7
change-id: 20250621-clk-reparent-89d75f6a8e09

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

