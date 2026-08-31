From: Tobias Jakobsen <tjakobsen84@protonmail.com>
Subject: [PATCH v2 0/2] Report platform enforced SPI flash write protection
Date: Mon, 31 Aug 2026 14:05:50 +0200
Message-Id: <20260831-spi-nor-platform-lock-v2-0-6cc75b909241@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7RgYCYIr72FYNG2RidBppoRoC
 He3cgGX7yX//Q2SV/YJbsUG6ldOLCEDnQqwowlPj+wyA5XUlC11mCJjEMU4mWUQnXES+0JnTNf
 WzlB7JcjbqH7g99F99JlHTovo57hZq5/9V1wrLNG6S0Ou7qra0z2qLBJmw9PZygz9vu9faEJow
 78AAAA=
X-Change-ID: 20260829-spi-nor-platform-lock-daa984da2872
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Mark Brown <broonie@kernel.org>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-spi@vger.kernel.org, Tobias Jakobsen <tjakobsen84@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788177954; l=2977;
 i=tjakobsen84@protonmail.com; s=20260829; h=from:subject:message-id;
 bh=XxFUu38Xpgfw5uH5rLWH9TFddXTQwTMb/VoPXqh4zDg=;
 b=/WgtaKN2ADvM0QeWuHKb3ySKNZE5CmbRyLgubMeA7/eyVSw4ZV/2Ju6IJBu28eNc+wlFzOJ4a
 4vSqtOyrh7sBVXfGyhA7NfddNMQpC1KTfQ/V2CVJObg2N1gJ4hk49RE
X-Developer-Key: i=tjakobsen84@protonmail.com; a=ed25519;
 pk=UREd6cisfwsFIDP455nUH6Ysx+ZDGnAVE9nGmKzm1Ks=
X-Endpoint-Received: by B4 Relay for tjakobsen84@protonmail.com/20260829 with auth_id=986
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MEMISLOCKED currently answers only from the flash chip's own block
protection bits. On platforms where write protection is enforced
elsewhere -- an Intel PCH SPI controller with protected range registers
being the common case -- those bits say nothing about what is actually
enforced, and are typically left clear.

The result is that MEMISLOCKED either fails with -EOPNOTSUPP, or, once
the chip gains SPI_NOR_HAS_LOCK, confidently reports a range as unlocked
while the controller is refusing writes to it. As more chips gain lock
flags over time, the second case replaces the first, so the wrong answer
spreads rather than the missing one.

Patch 1 lets a platform supply an is_locked() callback through struct
flash_platform_data, which spi-nor prefers over the chip's own bits. It
is inert on its own: nothing sets the callback, so every existing
platform keeps the behaviour it has today, and the series stays
bisectable.

Patch 2 adds the only user, spi-intel, which already computes protected
range state at probe but has had no way to expose it since the SPI MEM
conversion removed its visibility of the MTD device.

Full before/after numbers from a Coffee Lake NUC are in patch 2. Only
the Intel PCH path is functionally tested; the flash.h change is an
append-only addition and all existing users of that struct use
designated initialisers, so they are unaffected.

This came out of a discussion about fwupd reporting the BIOS region as
unlocked on Intel PCH systems:
https://bugzilla.kernel.org/show_bug.cgi?id=221927

Tooling disclosure, per Documentation/process/generated-content.rst:
this series was produced with the help of an LLM assistant in an
interactive session. All code was tested, results reviewed and can be
defended.

Question for the maintainers: this straddles MTD and SPI, so I do not
know which tree it should go through. Happy to resend in whatever shape
suits.

Signed-off-by: Tobias Jakobsen <tjakobsen84@protonmail.com>
---
Changes in v2:
- Reuse the protected range register decoding via a new helper instead
  of duplicating it (Mika Westerberg)
- Drop an unhelpful comment in intel_spi_is_locked() (Mika Westerberg)
- Add an Assisted-by tag and a tooling disclosure in the cover letter
- Link to v1: https://lore.kernel.org/r/20260829-spi-nor-platform-lock-v1-0-cd362d4914e2@protonmail.com

---
Tobias Jakobsen (2):
      mtd: spi-nor: allow the platform to supply write protection state
      spi: spi-intel: report controller enforced write protection

 drivers/mtd/spi-nor/core.c | 52 +++++++++++++++++++++++++++++++++--
 drivers/spi/spi-intel.c    | 68 ++++++++++++++++++++++++++++++++++++++++++----
 include/linux/spi/flash.h  | 12 ++++++++
 3 files changed, 124 insertions(+), 8 deletions(-)
---
base-commit: 1b78070aaef63512688aebfbc82365ef9d6660f1
change-id: 20260829-spi-nor-platform-lock-daa984da2872

Best regards,
-- 
Tobias Jakobsen <tjakobsen84@protonmail.com>

