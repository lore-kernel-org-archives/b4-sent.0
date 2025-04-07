From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v3 0/6] clk: clk-axi-clkgen: improvements and some fixes
Date: Mon, 07 Apr 2025 11:28:14 +0100
Message-Id: <20250407-dev-axi-clkgen-limits-v3-0-33c7f27c9d69@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL+o82cC/3XNTQ6DIBCG4asY1qURqH9d9R5NFwiDTqrQgCE2x
 rsXTZqmC5fvl8wzCwngEQK5ZgvxEDGgsynEKSOql7YDijo14Tkvcs5qqiFSOSNVw7MDSwcccQq
 0FKbNVQFK1C1Jty8PBufdvT9S9xgm59/7m8i29Ss2B2JkNKe8NBUYdlG6UTdp5eC6s3Ij2cjIf
 4xg4ojhiWGVkMClLgVjf8y6rh9ox3O7AgEAAA==
X-Change-ID: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744021698; l=1425;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=DtKEQ7AKPSModph2Km+mV9LVY9fsLpdZjnc0srYg814=;
 b=jo9XcmxOLCAjs6V8XW5LEWb1woSRPM3xAM89MZhmfgX4wrOc4Q9+ACAWoeecVktuFWmiJKA/T
 h4ifHOOCv+sB0xvqQQI7uIdrhG3VqV+4ZoY9sKy2jUCrXmb+YTI2vTj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series starts with a small fix and then a bunch of small
improvements. The main change though is to allow detecting of
struct axi_clkgen_limits during probe().

---
Changes in v3:
- Patch 6:
    * Revert change and parenthesis back on 'if (((params->edge == 0) ^
      (frac_divider == 1))'. While checkpatch complains, it's more
      readable like this and in some configs we might even get -Wparentheses.
- Link to v2: https://lore.kernel.org/r/20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com

Changes in v2:
- Patch 3
   * Rename adi_axi_fgpa_technology -> adi_axi_fpga_technology.

- Link to v1: https://lore.kernel.org/r/20250219-dev-axi-clkgen-limits-v1-0-26f7ef14cd9c@analog.com

---
Nuno Sá (6):
      clk: clk-axi-clkgen: fix fpfd_max frequency for zynq
      clk: clk-axi-clkgen: make sure to include mod_devicetable.h
      include: fpga: adi-axi-common: add new helper macros
      clk: clk-axi-clkgen: detect axi_clkgen_limits at runtime
      clk: clk-axi-clkgen move to min/max()
      clk: clk-axi-clkgen: fix coding style issues

 drivers/clk/clk-axi-clkgen.c        | 147 +++++++++++++++++++++++++-----------
 include/linux/fpga/adi-axi-common.h |  35 +++++++++
 2 files changed, 140 insertions(+), 42 deletions(-)
---
base-commit: 82f69876ef45ad66c0b114b786c7c6ac0f6a4580
change-id: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
--

Thanks!
- Nuno Sá

