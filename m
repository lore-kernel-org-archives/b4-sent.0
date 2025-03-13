From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/6] clk: clk-axi-clkgen: improvements and some fixes
Date: Thu, 13 Mar 2025 15:14:42 +0000
Message-Id: <20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGL20mcC/3WNwQ6CMBAFf4X07Jq2CIIn/8NwKGULG6E1LWkwp
 P9uJfHocSZ583YW0BMGdit25jFSIGczyFPB9KTsiEBDZia5rLgUDQwYQW0Een6OaGGmhdYAdWl
 6rivUZdOzvH15NLQd3UeXeaKwOv8+bqL42l+x/VOMAjjI2lzRiIseWn1XVs1uPGu3sC6l9AF9n
 do9uwAAAA==
X-Change-ID: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741878886; l=1074;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zcGj1uOEL8WR4UP614EhP+WDUNi3KOZTpWDDpUBnmv0=;
 b=ElfHDd6UrzzxERpEEORfL8eDB3IhstNDMUwliSk6zJ3yJiMTKaTL63/+YKLInzQ23liTiBpUQ
 o5jYG6ac+X8BA0jv0IF+tCvzSPHPqz1C1GKSksccbnDfpImNCWM4uwz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series starts with a small fix and then a bunch of small
improvements. The main change though is to allow detecting of
struct axi_clkgen_limits during probe().

---
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

 drivers/clk/clk-axi-clkgen.c        | 149 +++++++++++++++++++++++++-----------
 include/linux/fpga/adi-axi-common.h |  35 +++++++++
 2 files changed, 141 insertions(+), 43 deletions(-)
---
base-commit: 82f69876ef45ad66c0b114b786c7c6ac0f6a4580
change-id: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
--

Thanks!
- Nuno Sá

