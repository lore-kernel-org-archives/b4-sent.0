From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/4] binman: fit: compress generated fdt images and use it
 on Rockchip
Date: Sat, 10 Oct 2026 16:24:44 +0200
Message-Id: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBCF4auUWTuQqW0WXkVcdJKJjtBUMlGE0
 rs31eXP430rmBQVg0u3QpGPmi65BZ06CI8p3wU1tobe9Z4cOeQBWfM8ZUxaMcWKYZlfRex44pm
 858CRRh6hGW1I+v3519u/7c1PCfVAYdt23Ar8ZIEAAAA=
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
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791642291; l=1548;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=qJWDiDovEmfT81HjKbVzJn0ktLPTALKy8ZNdma0jFio=;
 b=B50cU6mk0REWRoQr3ppNbOZpaXEVWMyRDOyzng6LXmnNkWictjRzwgRlE210zOSOykXKZJltb
 Knsglz7zczfA9Kxm9iyxpn18IYgAkXZC9SHLGdrJ4hi22AkMPgipYI7
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Entry_fit's @fdt-SEQ generator copies the node's "compression" property
into the FIT. However, it embeds the raw .dtb. A FIT can therefore claim
"compression = lzma" while holding uncompressed data and SPL will fail
to decompress it during boot.

The patchset fixes the following:
 - Patch 1 makes the generator act on the property (lzma onl)
 - Patch 2 adds the test device trees
 - Patch 3 adds the tests covering both the lzma round trip
   and the unsupported-algorithm error.
 - Patch 4 uses it on Rockchip where the shared @fdt-SEQ template gets
   FIT_FDT_COMP, "lzma" when SPL_LZMA is enabled and "none" otherwise

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (4):
      binman: fit: Actually compress generated fdt images
      binman: test: Add fit fdt compression device trees
      binman: test: Check compression of generated fit fdt images
      rockchip: LZMA-compress the FDT image in the FIT based on FIT_FDT_COMP

 arch/arm/dts/rockchip-u-boot.dtsi      |  8 +++-
 tools/binman/etype/fit.py              | 12 ++++++
 tools/binman/ftest.py                  | 29 ++++++++++++++
 tools/binman/test/fit/fdt_bad_comp.dts | 72 ++++++++++++++++++++++++++++++++++
 tools/binman/test/fit/fdt_lzma.dts     | 72 ++++++++++++++++++++++++++++++++++
 5 files changed, 192 insertions(+), 1 deletion(-)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-binman-fit-fdt-compression-3166bcbd15b5

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

