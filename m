From: Sam Day <me@samcday.com>
Subject: [PATCH v2 0/6] MSM8916: Bring secondary cores online with
 spin-table
Date: Tue, 02 Jun 2026 17:18:56 +1000
Message-Id: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ7CIBQFr9KwFgMoQl15D9NFhY9lQUF+29g0v
 btYY9y4nJe8mYUgZA9IztVCMkwefewLiF1FTNf2d6DeFiaCCcm4UDRg0DU/UQyJ4phSzAOVToK
 6HWvLFJDyTBmcf27Wa/PhDI+xyIff2HkcYp638sTf6zei/0YmThk91FIrx7VxzFywDca2897EQ
 Jp1XV/gohYkzQAAAA==
X-Change-ID: 20250127-msm8916-smp-support-5f5e7b49d07e
To: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Mark Kettenis <mark.kettenis@xs4all.nl>, Sumit Garg <sumit.garg@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 Casey Connolly <casey.connolly@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=2524;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=isRyibY0H+lkNaujLtRY0btlPaqJyqRSHaBLQFbwFiU=;
 b=iFhHh4pMqtNlVMoMA5WecbooVSaEtSHaaMmN2BOQ2B5JT3QoHMODvbu13uPKcW66AV3LCgTrB
 pzIt8tDv3YOC/GRWGxpUA6Rcyoq1bAxBFUR8bJp8TljDtvCcm29N1g9
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series depends on the "mach-snapdragon: handle platforms
without PSCI support" patch that was submitted earlier today. That first
patch lays some groundwork to handle detecting when a device is booting
without PSCI and deletes the /psci node in that case.

This series builds on top of that detection by rewriting all CPUs with
enable-method="psci" to "spin-table".

Once this is done, the existing spin-table support in U-Boot handles
further patching the nodes with the appropriate cpu-release-addr and
reserving the memory with the spin-table instructions.

Interestingly, this spin-table code doesn't seem to be in active use
anywhere, and it had bitrotted a little. But after blowing the dust off
it and fixing a couple of missing #includes, it works great.

I extended the spin-table support a little to make it easier for
consumers to plug in a method that is called for each CPU that needs to
be brought online. This saves the qcom board code from needing to hook
into ft_board_setup or something that runs before booting the OS.

Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v2:
- Reworked the SCM impl to be a proper firmware driver, and streamlined
  the API so callers aren't forced to deal with calling conventions
  (thanks Casey).
- Link to v1: https://lore.kernel.org/r/20250128-msm8916-smp-support-v1-0-39587f18cf0c@samcday.com

---
Sam Day (6):
      armv8: spin_table: Fix missing includes
      armv8: spin_table: add hook for booting cores
      firmware: Add qcom SCM driver
      mach-snapdragon: fixup CPUs with PSCI enable-method
      mach-snapdragon: MSM8916 spin-table CPU boot support
      qcom_defconfig: enable spin-table support

 MAINTAINERS                            |   2 +
 arch/arm/cpu/armv8/spin_table.c        |  20 +++
 arch/arm/include/asm/spin_table.h      |   3 +
 arch/arm/mach-snapdragon/Makefile      |   1 +
 arch/arm/mach-snapdragon/board.c       |  41 +++++
 arch/arm/mach-snapdragon/msm8916-smp.c | 138 +++++++++++++++++
 configs/qcom_defconfig                 |   3 +
 drivers/firmware/Kconfig               |   9 ++
 drivers/firmware/Makefile              |   1 +
 drivers/firmware/qcom-scm.c            | 274 +++++++++++++++++++++++++++++++++
 include/firmware/qcom/scm.h            |  71 +++++++++
 11 files changed, 563 insertions(+)
---
base-commit: 30b77f6aa146c96b831cb4ece038130b655b6a41
change-id: 20250127-msm8916-smp-support-5f5e7b49d07e

Best regards,
-- 
Sam Day <me@samcday.com>

