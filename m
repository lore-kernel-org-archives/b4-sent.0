From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH u-boot 0/3] lib: qrcodegen: import Nayuki QR Code generator
Date: Thu, 10 Sep 2026 13:47:34 +0200
Message-Id: <20260910-b4-lib-qrcode-v1-0-d36db6055c95@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBQFr0Le2p9QIk31KsYFLQ/9xlBtwZgQ7
 m7B5UwysyAzKTPO1YLEj2aNYwFzqBDu3XijaF8YTd3Y2hoj/ihP9fJOIfaUrg10J1o3uBaleSU
 O+t1/F8ziY5xw/fs8+wfDtM2wrj/00CfKeQAAAA==
X-Change-ID: 20260611-b4-lib-qrcode-a5ce89e68f85
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Heiko Schocher <hs@nabladev.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Heiko Stuebner <heiko@sntech.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Alexey Charkov <alchark@gmail.com>, David Lechner <dlechner@baylibre.com>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789040858; l=1749;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=wE6LSDLIVrBomQl/32my3DVIQ7k5IALGTzK86GxE5hA=;
 b=QnCIs/hFGJX+Sy2O3kHEh50/Eu0kTEfHvfVBhP84PF6GCeojaho1b+5JoY9/JKj9rcLMVMu5e
 wtPlJDOhQ+hAXWDJMmmCB+K90utZsme3VFvsFmsEvh+2LNfGLrcnRqX
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a small QR code generator library so U-Boot boards can encode
arbitrary text or binary into a QR symbol. Main use cases include
displaying URLs, pairing tokens, serial numbers or
self-diagnostic state from the bootloader (e.g. during porting to a
new mobile device with no serial console or usb peripheral working).

Optionally apply gzip compression for the QR code payload.

Three patches:

1. Verbatim import of Nayuki's public-domain / MIT-licensed C QR Code
   generator (qrcodegen.{h,c}) under CONFIG_LIB_QRCODE. No code
   changes and the only adjustments are SPDX header, swapping <assert.h>
   for U-Boot's <log.h>.

2. CONFIG_LIB_QRCODE_MAX_VERSION (int, 1..40, default 40) so callers
   can cap the maximum QR version. The version trades payload capacity for
   smaller static scratch buffers.

3. CONFIG_LIB_QRCODE_GZIP (bool, depends on GZIP_COMPRESSED) and a
   helper qrcodegen_encodeBinaryCompressed(). Perpends four-byte "QRGZ"
   magic header so the scanner side can detect and decompress.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (3):
      lib: qrcodegen: Import Nayuki QR Code generator library
      lib: qrcodegen: configurable maximum QR code version
      lib: qrcodegen: optional gzip pre-compression of payloads

 include/qrcodegen.h  |  407 ++++++++++++++++++++
 lib/Kconfig          |   44 +++
 lib/Makefile         |    2 +
 lib/qrcodegen.c      | 1034 ++++++++++++++++++++++++++++++++++++++++++++++++++
 lib/qrcodegen_gzip.c |   45 +++
 5 files changed, 1532 insertions(+)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260611-b4-lib-qrcode-a5ce89e68f85

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

