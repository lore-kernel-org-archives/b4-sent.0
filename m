From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/2] clk: Fix issues related to CLK_IGNORE_UNUSED failures
 and amlogic glitch free mux
Date: Sun, 29 Sep 2024 14:10:04 +0800
Message-Id: <20240929-fix_glitch_free-v1-0-22f9c36b7edf@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADzv+GYC/x2MQQqAIBAAvxJ7TtCtg/aVCAlbdSEsNCII/550H
 JiZFwplpgJT90KmmwsfqYHqO3BxTYEEb40BJY7SoBGeHxt2vly0PhMJNNJpbXBwg4JWnZma8h/
 npdYP3BY0HWEAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727590225; l=2225;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=VuF+6B8clsCESzRY45mjWVDnp0roeP9EanMgzGgHiWE=;
 b=uv2V//H+abP/S3Lw1qAz+VmyJFzrQupRRNbZVAZLVVbSOXL4PGoneT4nrv9LXoR4p9o9RDGqB
 VeQpA48RrjADXJl+sHwiniuTizO/DMQ0PwSjqDVVZVEBJLoBCahwUM5
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If CLK_OPS_PARENT_ENABLE is configured for clock,
clk_core_disable_unprepare() is called in clk_disable_unused_subtree().
Even clocks that are configured with CLK_IGNORE_UNUSED are disabled,
resulting in the failure of CLK_IGNORE_UNUSED.

To ensure that amlogic glitch free mux can switch clock channels
properly, add flag CLK_OPS_PARENT_ENABLE to glitch free mux. The issue
that CLK_OPS_PARENT_ENABLE in CCF causes CLK_IGNORE_UNUSED to fail is
also exposed.

glitch free mux channel switchover failure issue(Test vpu_clk on S4):
step 1:
$ cat /sys/kernel/debug/clk/vpu/clk_parent 
vpu_0
$ cat /sys/kernel/debug/clk/vpu_0/clk_rate 
399999994
$ cat /sys/kernel/debug/clk/vpu_1/clk_rate 
666666656
$ echo 1 > /sys/kernel/debug/clk/vpu/clk_prepare_enable 
$ cat /sys/kernel/debug/meson-clk-msr/clks/cts_vpu_clk
399987500       +/-12500Hz

step 2:
$ echo 0 > /sys/kernel/debug/clk/vpu/clk_prepare_enable 
$ echo 1 > /sys/kernel/debug/clk/vpu/clk_parent 
$ cat /sys/kernel/debug/clk/vpu/clk_parent 
vpu_1
$ cat /sys/kernel/debug/clk/vpu/clk_rate 
666666656
$ echo 1 > /sys/kernel/debug/clk/vpu/clk_prepare_enable 
$ cat /sys/kernel/debug/meson-clk-msr/clks/cts_vpu_clk
0       +/-3125Hz

In step2, vpu_0 is disabled, and the vpu is not switched to vpu_1. At
this time, the vpu is still connected to vpu_0 and vpu_0 is disabled at
this time, resulting in the clk-measure not measuring the clock.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (2):
      clk: Fix the CLK_IGNORE_UNUSED failure issue
      clk: meson: Fix glitch free mux related issues

 drivers/clk/clk.c                  | 67 ++++++++++++++++++++++++++++++++++++--
 drivers/clk/meson/a1-peripherals.c | 12 +++----
 drivers/clk/meson/axg.c            | 16 +++++----
 drivers/clk/meson/c3-peripherals.c |  6 ++--
 drivers/clk/meson/g12a.c           | 18 ++++++----
 drivers/clk/meson/gxbb.c           | 18 ++++++----
 drivers/clk/meson/s4-peripherals.c | 32 +++++++++---------
 7 files changed, 122 insertions(+), 47 deletions(-)
---
base-commit: e736da1956cf0880a02ec5023f3487eea7611b5f
change-id: 20240929-fix_glitch_free-290c88923c31

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

