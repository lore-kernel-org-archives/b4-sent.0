From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH v2 0/6] binman: fit: Compress generated fdt images and use
 it on Rockchip
Date: Sat, 17 Oct 2026 09:38:59 +0200
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OQQ7CIBAAv9Ls2TVQCzae/IfpoVBq11hoABtNw
 9+F+gGPk52d3Q2C8WQCXKoNvFkpkLMZ6kMFeurt3SANmaFmteSMM1QNKrJzb3GkiOMQUbt58Sa
 UTTxxKZVWAxdKQG7kwUjvvX/rfhxe6mF0LNFiTBSi85/9gZUX799bK0eGTSOFEO1ZtFpfF++iy
 z49j1mELqX0BencgBjhAAAA
X-Change-ID: 20261010-b4-binman-fit-fdt-compression-3166bcbd15b5
To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Marek Vasut <marex@nabladev.com>, 
 Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Alexey Charkov <alchark@flipper.net>, 
 James Hilliard <james.hilliard1@gmail.com>, 
 Aristo Chen <aristo.chen@canonical.com>, 
 Philippe Reynes <philippe.reynes@softathome.com>, 
 Daniel Golle <daniel@makrotopia.org>, Johan Jonker <jbx6244@gmail.com>, 
 Quentin Schulz <u-boot@0leil.net>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=3027;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=FF3S2yi58tQ3DFXXoJWH0P5qSrgVFpf7CVY3P6mPwkc=;
 b=P/m+f1TD9T/sggLrKpIRvGHMPiW/05wqVTC2zGLKpTTl+y09Ih17Kd1Xnj3whHJzdE0Eqz1m4
 LsAoJUxicQ7BUnJaUPlhKNiO1UiTqFJDWnrBKCUQNw584ypmysPYo3X
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Entry_fit's @fdt-SEQ generator always embeds the raw .dtb. Add a
'fit,compress' property so binman can compress it with any algorithm FIT
defines (xz is rejected) and set 'compression' to match.

Add a generic SPL_FIT_FDT_COMP choice (none, LZMA, gzip: what the SPL FIT
loader can currently decompress) and use it on Rockchip.

The default is none so no in-tree board changes.

---
Changes in v2:
- Use a binman-level 'fit,compress' property instead of acting on 'compression'
- Support all algorithms binman knows via a shared bintool-name helper
- Register the bintool in AddBintools() and handle a missing tool, reject 'xz'
- Split the test device trees and tests into their own patches
- Document the property in the Entry_fit docstring
- Expand the Rockchip commit message
- Add a generic SPL_FIT_FDT_COMP choice in boot/Kconfig used by Rockchip
- Link to v1: https://patch.msgid.link/20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com

To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>
Cc: Alper Nebi Yasak <alpernebiyasak@gmail.com>
Cc: Tom Rini <trini@konsulko.com>
Cc: Quentin Schulz <quentin.schulz@cherry.de>
Cc: Marek Vasut <marex@nabladev.com>
Cc: Wojciech Dubowik <Wojciech.Dubowik@mt.com>
Cc: Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Philipp Tomsich <philipp.tomsich@vrull.eu>
Cc: Kever Yang <kever.yang@rock-chips.com>
Cc: Jonas Karlman <jonas@kwiboo.se>
Cc: Petr Pavlata <petr@acrux.cz>
Cc: David Heidelberg <david@ixit.cz>
Cc: Alexey Charkov <alchark@flipper.net>
Cc: James Hilliard <james.hilliard1@gmail.com>
Cc: Aristo Chen <aristo.chen@canonical.com>
Cc: Philippe Reynes <philippe.reynes@softathome.com>
Cc: Daniel Golle <daniel@makrotopia.org>
Cc: Johan Jonker <jbx6244@gmail.com>
Cc: Quentin Schulz <u-boot@0leil.net>
Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>

---
Petr Hodina (6):
      binman: Factor out the compression bintool lookup
      binman: fit: Add fit,compress for generated fdt images
      binman: test: Add fit,compress device trees
      binman: test: Add tests for fit,compress
      boot: Add a choice for the compression of the FDT in the FIT
      rockchip: Allow compression of the FDT in the FIT

 arch/arm/dts/rockchip-u-boot.dtsi          | 15 ++++++-
 boot/Kconfig                               | 32 ++++++++++++++
 tools/binman/entry.py                      | 27 +++++++++---
 tools/binman/etype/fit.py                  | 67 ++++++++++++++++++++++++++++++
 tools/binman/ftest.py                      | 44 ++++++++++++++++++++
 tools/binman/test/fit/fdt_compress.dts     | 24 +++++++++++
 tools/binman/test/fit/fdt_compress_bad.dts | 24 +++++++++++
 tools/binman/test/fit/fdt_compress_xz.dts  | 24 +++++++++++
 8 files changed, 250 insertions(+), 7 deletions(-)
---
base-commit: 8d534cec0cc0109a37c0ded8854da03f1526dc0e
change-id: 20261010-b4-binman-fit-fdt-compression-3166bcbd15b5

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

