From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/4] arm: carry and filter previous bootloader's bootargs
Date: Fri, 11 Sep 2026 20:18:46 +0200
Message-Id: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ7CMAwAwK9UnrEUCkSUryAGOzHFDAmySwWq+
 ncCjLfcAi6m4nDqFjCZ1bWWhu2mg3SjMgpqboY+9DEMYUDeI5VsVTNyrRPZ6JjI7F1nMdwJc4r
 xeGCK0I6HyVVfv/98+duffJc0fVNY1w+wPiTtgQAAAA==
X-Change-ID: 20260909-b4-android-bootargs-carryover-3ebbc6685ba6
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Simon Glass <sjg@chromium.org>, Kory Maincent <kory.maincent@bootlin.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, 
 Alexey Charkov <alchark@gmail.com>, Heiko Schocher <hs@nabladev.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Anshul Dalal <anshuld@ti.com>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789150739; l=2075;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=UasbxUjffhQxY7H0NqWCzpDwwfkLu216GvawNMzwsmg=;
 b=aXSZSd2EaeSWO/DbJ/edvsQsgXiRqKfOhMpD5DDY9Y2YUYERXILoHp65cSY7y2RTZ3V2Xf6jy
 hM7lfQZ+EmcCkysM7oiw8Y4ZgLHo+SDJUxred0kq++ejnOeoA0fLuZw
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series supports chainloaded U-Boot on Android devices where the
previous stage bootloader (e.g. Android ABL) hands off a kernel
command line via /chosen/bootargs. Some of those parameters need to
be carried over into U-Boot's own $bootargs, while others such as
skip_initramfs need to be explicitly dropped before the command
line reaches the kernel.

Therefore this series adds a small command-line utility library
and uses it to carry over and filter the inherited bootargs.

Four patches:

  1. common: Add command line parsing utilities
     Parse key=value parameters out of a command-line string.

  2. common: Add command line parameter masking functionality
     Mask or drop individual parameters from a command-line string.

  3. common: Add Android bootloader parameter parsing helper
     Convenience wrapper for the numerous androidboot.* parameters.

  4. arm: carry previous bootloader's bootargs into $bootargs
     Wire the above utilities into the boot path. Copy the previous
     bootloader's /chosen/bootargs into $bootargs. Drop parameters
     that must not survive the handoff (e.g.  skip_initramfs)
     when CONFIG_SAVE_PREV_BL_BOOTARGS is enabled.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (4):
      common: Add command line parsing utilities
      common: Add command line parameter masking functionality
      common: Add Android bootloader parameter parsing helper
      arm: carry previous bootloader's bootargs into $bootargs

 MAINTAINERS                      |   6 +
 arch/arm/lib/save_prev_bl_data.c |  15 +-
 boot/Kconfig                     |   8 +
 include/cmdline_utils.h          |  60 +++++++
 lib/Makefile                     |   1 +
 lib/cmdline_utils.c              | 331 +++++++++++++++++++++++++++++++++++++++
 6 files changed, 420 insertions(+), 1 deletion(-)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260909-b4-android-bootargs-carryover-3ebbc6685ba6

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

