From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 11 Sep 2026 20:25:16 +0200
Subject: [PATCH u-boot v2 2/3] lib: qrcodegen: configurable maximum QR code
 version
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-b4-lib-qrcode-v2-2-c5291fb7c646@protonmail.com>
References: <20260911-b4-lib-qrcode-v2-0-c5291fb7c646@protonmail.com>
In-Reply-To: <20260911-b4-lib-qrcode-v2-0-c5291fb7c646@protonmail.com>
To: u-boot@lists.u-boot-project.org
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789151116; l=2578;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=KEFc0IGNdnHH/KW2Az/zDEUde8UYpqr6m3aX1epjazY=;
 b=q1iZiov3pZ3HpjPlrDb+PVoTZ8ipcu7hmGQFjqu2L6p+737beinVvfFl3qAdm5YdV4Dy3vMeT
 yvZIdbMTgRzBnacrO4GKSZrTSDYs5W6hdTxD2a413oQDLxA3bLZeolf
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CONFIG_LIB_QRCODE_MAX_VERSION (int, range 1..40, default 40) so
callers can cap the QR code "version" the library is built to handle.

The version determines both the maximum payload capacity and the
static scratch-buffer size demanded of callers: each buffer is
qrcodegen_BUFFER_LEN_FOR_VERSION(N) bytes (~370 B at N=20, ~810 B at
N=30, ~1430 B at N=40), and callers typically need two of them.

The default of 40 matches upstream Nayuki, so no existing callers
need to change.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 include/qrcodegen.h |  4 ++++
 lib/Kconfig         | 18 ++++++++++++++++++
 2 files changed, 22 insertions(+)

diff --git a/include/qrcodegen.h b/include/qrcodegen.h
index 6f87b76bb2a..b67b77a30fe 100644
--- a/include/qrcodegen.h
+++ b/include/qrcodegen.h
@@ -134,7 +134,11 @@ struct qrcodegen_Segment {
 /*---- Macro constants and functions ----*/
 
 #define qrcodegen_VERSION_MIN   1  // The minimum version number supported in the QR Code Model 2 standard
+#ifdef CONFIG_LIB_QRCODE_MAX_VERSION
+#define qrcodegen_VERSION_MAX  CONFIG_LIB_QRCODE_MAX_VERSION
+#else
 #define qrcodegen_VERSION_MAX  40  // The maximum version number supported in the QR Code Model 2 standard
+#endif
 
 // Calculates the number of bytes needed to store any QR Code up to and including the given version number,
 // as a compile-time constant. For example, 'uint8_t buffer[qrcodegen_BUFFER_LEN_FOR_VERSION(25)];'
diff --git a/lib/Kconfig b/lib/Kconfig
index 18311276443..5f37a07e512 100644
--- a/lib/Kconfig
+++ b/lib/Kconfig
@@ -303,6 +303,24 @@ config LIB_QRCODE
 
 	  Imported from https://github.com/nayuki/QR-Code-generator
 
+config LIB_QRCODE_MAX_VERSION
+	int "Maximum QR code version supported (1..40)"
+	depends on LIB_QRCODE
+	range 1 40
+	default 40
+	help
+	  Maximum QR code "version" the library is built to support, in
+	  the range 1..40. The version determines both the maximum payload
+	  capacity and the static scratch-buffer size demanded of callers:
+
+	    qrcodegen_BUFFER_LEN_FOR_VERSION(N) bytes per buffer,
+	    growing quadratically (N=20 -> ~370 B, N=30 -> ~810 B,
+	    N=40 -> ~1430 B per buffer; callers typically need two).
+
+	  Lower this if you only need to encode short payloads such as
+	  pairing tokens or short URLs and want to reclaim the static
+	  buffer footprint. The default of 40 matches upstream Nayuki.
+
 choice
 	prompt "Pseudo-random library support type"
 	depends on NET_RANDOM_ETHADDR || RANDOM_UUID || CMD_UUID || \

-- 
2.55.0

