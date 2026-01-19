From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/6] clk: support arbitrary clk_register() sequence
Date: Tue, 20 Jan 2026 03:07:17 +0800
Message-Id: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOaAbmkC/3XMSw6CMBSF4a2Qjq1pL48WR+7DOCjlVhqQkhYbD
 WHvFhIHmjg8J/n+hQT0FgM5ZQvxGG2wbkwjP2REd2q8IbVt2gQYlKwCTvXQU4+T8jjOVNatKE2
 lJLKaJDJ5NPa55y7XtDsbZudfez3y7f0TipwyWkglDJic67I+u8c8ONcftbuTLRXhwyvG2S+Hx
 HNsCmiE1MLwb76u6xsyDN+G6QAAAA==
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>, 
 Simon Glass <simon.glass@canonical.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768849639; l=2889;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=/X92dXFD7JRPJEjwp/o703wKHBTDwYjM8O7J/qb/TmY=;
 b=qOTwUHpmQ6KBfnwpx3+NV+jTXZY+Qb4z+hxRP2Ni/Rvhh1XWLHHbzPMYuianXUGgLrrtFirfX
 IoFH7emPsvpBzkS5Pb2WLd/Ji6dSg8e6ZT69agWY4tW8f/n0LlAJJGC
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
Changes in v3:
- dm: core: drop Simon's rb because the logic is incompelete and broken.
  I forgot to add the child to the parent's child_node list which fails
  the test I've written for the dev_reparent() change. (Simon)
- test: dm: add tests for device_reparent()
- test: clk: rebase onto master, clk_dm() -> dev_clk_dm(), add required
  CLK_ID() macro.
- Link to v2: https://lore.kernel.org/r/20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com

Changes in v2:
- tests: add a simple test for this feature
- clk: restrict this feature to only U-Boot proper, excluding xPLs from
  support (Tom)
- clk: some minor tweaks that should not matter too much
- Link to v1: https://lore.kernel.org/r/20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com

---
Yang Xiwen (6):
      drivers: core: device: set new parent when old parent is NULL
      test: dm: core: add some assertions for device_reparent()
      clk: add uclass id check to clk_get_parent()
      clk: use clk_get_parent() helper in clk_en(dis)able()
      clk: allow assigning parent lazily
      test: clk: add test for CLK_LAZY_REPARENT

 drivers/clk/Kconfig           | 12 ++++++++
 drivers/clk/clk-uclass.c      | 72 +++++++++++++++++++++++++++++++++++--------
 drivers/clk/clk.c             | 14 +++++++--
 drivers/clk/clk_sandbox_ccf.c | 10 ++++++
 drivers/core/device.c         |  8 +++++
 include/clk.h                 |  2 ++
 include/sandbox-clk.h         |  2 ++
 test/dm/clk_ccf.c             | 40 ++++++++++++++++++++++++
 test/dm/core.c                | 34 ++++++++++++++++++--
 9 files changed, 178 insertions(+), 16 deletions(-)
---
base-commit: 6b2d05748cf3cd6ba417a96c00602b0122e10af6
change-id: 20250621-clk-reparent-89d75f6a8e09

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

