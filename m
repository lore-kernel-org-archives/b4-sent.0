From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/6] clk: clk-axi-clkgen: improvements and some fixes
Date: Wed, 19 Feb 2025 17:20:18 +0000
Message-Id: <20250219-dev-axi-clkgen-limits-v1-0-26f7ef14cd9c@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANIStmcC/x3MQQqAIBBA0avErBtQw4iuEi1KxxoyC40IpLsnL
 d/i/wyJIlOCvsoQ6ebERyiQdQVmncJCyLYYlFBaKNmhpRunh9H4baGAnne+EraNm4XRZJpuhtK
 ekRw//3cY3/cDW3y8mWcAAAA=
X-Change-ID: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739985620; l=872;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=lhlb0oWuR17RNf0Vp0EHzjC/aagOic5Ps7J0XIlnC4o=;
 b=gAGHHx90yruTZFfFG9Pro8Lq67D9hlStPBzCz/mR0e8R52paS8QpFwcLUfWcEuFb8xNCG79jR
 0WROiYBw1u/CS5Fyw5cwyNlHkh8oUBl0rVA8fs6P69TLTllJtp6+Gj9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series starts with a small fix and then a bunch of small
improvements. The main change though is to allow detecting of
struct axi_clkgen_limits during probe().

---
Nuno Sá (6):
      clk: clk-axi-clkgen: fix fpfd_max frequency for zynq
      clk: clk-axi-clkgen: make sure to include mod_devicetable.h
      include: fpga: adi-axi-common: add new helper macros
      clk: clk-axi-clkgen: detect axi_clkgen_limits at runtime
      clk: clk-axi-clkgen move to min/max()
      clk: clk-axi-clkgen: fix coding style issues

 drivers/clk/clk-axi-clkgen.c        | 149 +++++++++++++++++++++++++-----------
 include/linux/fpga/adi-axi-common.h |  35 +++++++++
 2 files changed, 141 insertions(+), 43 deletions(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
--

Thanks!
- Nuno Sá

