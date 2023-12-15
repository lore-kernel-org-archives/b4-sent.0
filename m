From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/2] clk: ccf: fix enable_count mismatch
Date: Sat, 16 Dec 2023 02:28:50 +0800
Message-Id: <20231111-enable_count-v3-0-08a821892fa9@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOKafGUC/32NQQ7CIBAAv9JwFrOAra0n/2GMAbq1xBYMtETT9
 O9Cbx50b7Ob2VlIQG8wkFOxEI/RBONsArEriO6lvSM1bWLCgQuWhqKVasCbdrOdqGxLACZ4VbO
 SJEXJgFR5aXWfpVGGCX0+PD125rV1LtfEvQmT8+8tG1ne/ihERoGW0HQHANk0Wp3dPA3OPfbaj
 SS/ivyfzpPOAcWR1xWAKr/1dV0/Bg0eXwIBAAA=
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702664931; l=1401;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=OUovCpskf3sjR88V7uRl9KTZC43ZbpJtQSn38lTvjqk=;
 b=tkgiV1QT1VUw06eQuTJ0AKBio9C1QAt5nKD05m0lnxNHrBb+gcB7+5CZgZKBsIcST2q0X3XNt
 KhSVzoVzENlBP7Hr8TgX6zSH2xLHR1jHg/8TCIOrPwbjlQLnOHgs3bL
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As described in [1], enable_count is incremented by 2 when
ccf_clk_enable() is called. This series of patch fixed this issue and
added a testcase for that.

[1]: https://lore.kernel.org/all/SEZPR06MB695927A6DEEEF8489A06897396A7A@SEZPR06MB6959.apcprd06.prod.outlook.com/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- move i2v_root in front of devm clocks. So that clk_test driver needs a
  minimum modification
- squash patch 1, 3 and 4. -- Suggested by Sean
- rewrite commit log for clarity.
- Link to v2: https://lore.kernel.org/r/20231111-enable_count-v2-0-20e3728600b5@outlook.com

Changes in v2:
- add missing SoB in patch 1/4, no functional change
- Link to v1: https://lore.kernel.org/r/20231111-enable_count-v1-0-509f400a99cb@outlook.com

---
Yang Xiwen (2):
      clk: get correct ops for clk_enable() and clk_disable()
      test: dm: clk_ccf: test ccf_clk_ops

 arch/sandbox/dts/test.dts      |  4 +++-
 arch/sandbox/include/asm/clk.h |  1 +
 drivers/clk/clk-uclass.c       |  2 ++
 drivers/clk/clk_sandbox_ccf.c  |  1 +
 drivers/clk/clk_sandbox_test.c |  1 +
 test/dm/clk_ccf.c              | 14 +++++++++++---
 6 files changed, 19 insertions(+), 4 deletions(-)
---
base-commit: 3b913c148249a2b9d12ff25517ec311646e83bee
change-id: 20231111-enable_count-ad5001326815

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

