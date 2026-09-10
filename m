From: Petr Hodina <petr.hodina@protonmail.com>
Date: Thu, 10 Sep 2026 13:47:37 +0200
Subject: [PATCH u-boot 3/3] lib: qrcodegen: optional gzip pre-compression
 of payloads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-b4-lib-qrcode-v1-3-d36db6055c95@protonmail.com>
References: <20260910-b4-lib-qrcode-v1-0-d36db6055c95@protonmail.com>
In-Reply-To: <20260910-b4-lib-qrcode-v1-0-d36db6055c95@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789040859; l=4601;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=qD1iJ4/0y+YXjHalgq/zQ4IJ/+Vz7XQPPIgIapq2z2c=;
 b=8o4Z6/+4644Y2agySQBrm0W8nS/D5hr0LKgHQYVMzduUemWn4nAYgk7LisaMFZA+vVBpfFMvm
 3kcRXKAbJ3rBc5i3mayL1XsjomJRq2WOvYqI08vlNnYxvKswYES0kxa
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CONFIG_LIB_QRCODE_GZIP (bool, depends on GZIP_COMPRESSED) and a
new helper qrcodegen_encodeBinaryCompressed() that tries the plain
binary encoder first, and on failure transparently gzip-compresses
the payload and re-encodes it in binary mode with a four-byte "QRGZ"
magic header so the scanner side knows to decompress.

The compressed payload can later be decoded by:
`zbarimg --raw -q <QR_CODE> | tail -c +5 | gunzip`

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 include/qrcodegen.h  | 14 ++++++++++++++
 lib/Kconfig          | 15 +++++++++++++++
 lib/Makefile         |  1 +
 lib/qrcodegen_gzip.c | 45 +++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 75 insertions(+)

diff --git a/include/qrcodegen.h b/include/qrcodegen.h
index b67b77a30fe..590b61cd871 100644
--- a/include/qrcodegen.h
+++ b/include/qrcodegen.h
@@ -235,6 +235,20 @@ bool qrcodegen_encodeBinary(uint8_t dataAndTemp[], size_t dataLen, uint8_t qrcod
 	enum qrcodegen_Ecc ecl, int minVersion, int maxVersion, enum qrcodegen_Mask mask, bool boostEcl);
 
 
+#if defined(CONFIG_LIB_QRCODE_GZIP)
+/*
+ * Encode a payload, transparently falling back to gzip compression
+ * if the plain payload does not fit in any QR code version up to
+ * qrcodegen_VERSION_MAX at the requested ECC level.
+ *
+ * Returns true on success, false if neither plain nor gzip-compressed
+ * payload fits.
+ */
+bool qrcodegen_encodeBinaryCompressed(uint8_t dataAndTemp[], size_t dataLen,
+	uint8_t qrcode[], enum qrcodegen_Ecc ecl);
+#endif
+
+
 /*---- Functions (low level) to generate QR Codes ----*/
 
 /* 
diff --git a/lib/Kconfig b/lib/Kconfig
index 5f37a07e512..ed67d2f8161 100644
--- a/lib/Kconfig
+++ b/lib/Kconfig
@@ -321,6 +321,21 @@ config LIB_QRCODE_MAX_VERSION
 	  pairing tokens or short URLs and want to reclaim the static
 	  buffer footprint. The default of 40 matches upstream Nayuki.
 
+config LIB_QRCODE_GZIP
+	bool "Allow gzip pre-compression of QR code payloads"
+	depends on LIB_QRCODE
+	depends on GZIP_COMPRESSED
+	help
+	  When a payload does not fit in the configured maximum QR code
+	  version, transparently gzip-compress it and re-encode in binary
+	  mode with a four-byte magic header ("QRGZ"), so the scanner side
+	  knows to decompress.
+
+	  Useful for diagnostic / state-dump QR codes where the raw payload
+	  is highly compressible (printable text, log fragments) but would
+	  not otherwise fit a small QR symbol. The plain (uncompressed)
+	  encoder remains the first attempt; this just adds a fallback.
+
 choice
 	prompt "Pseudo-random library support type"
 	depends on NET_RANDOM_ETHADDR || RANDOM_UUID || CMD_UUID || \
diff --git a/lib/Makefile b/lib/Makefile
index 60e62d5e6e2..5f3e5300462 100644
--- a/lib/Makefile
+++ b/lib/Makefile
@@ -129,6 +129,7 @@ obj-y += linux_string.o
 obj-$(CONFIG_$(PHASE_)LMB) += lmb.o
 obj-y += membuf.o
 obj-$(CONFIG_LIB_QRCODE) += qrcodegen.o
+obj-$(CONFIG_LIB_QRCODE_GZIP) += qrcodegen_gzip.o
 obj-$(CONFIG_REGEX) += slre.o
 obj-y += string.o
 obj-y += tables_csum.o
diff --git a/lib/qrcodegen_gzip.c b/lib/qrcodegen_gzip.c
new file mode 100644
index 00000000000..fe0c6567a00
--- /dev/null
+++ b/lib/qrcodegen_gzip.c
@@ -0,0 +1,45 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Optional gzip compression for QR code payloads.
+ */
+
+#include <gzip.h>
+#include <linux/string.h>
+#include <linux/types.h>
+#include <qrcodegen.h>
+
+#define QRGZ_MAGIC_LEN	4
+
+static const u8 qrgz_magic[QRGZ_MAGIC_LEN] = { 'Q', 'R', 'G', 'Z' };
+
+bool qrcodegen_encodeBinaryCompressed(uint8_t dataAndTemp[], size_t dataLen,
+				      uint8_t qrcode[], enum qrcodegen_Ecc ecl)
+{
+	size_t buf_max = qrcodegen_BUFFER_LEN_FOR_VERSION(qrcodegen_VERSION_MAX);
+	unsigned long out_len;
+	u8 *scratch;
+
+	if (qrcodegen_encodeBinary(dataAndTemp, dataLen, qrcode, ecl,
+				   qrcodegen_VERSION_MIN, qrcodegen_VERSION_MAX,
+				   qrcodegen_Mask_AUTO, true))
+		return true;
+
+	if (buf_max < QRGZ_MAGIC_LEN)
+		return false;
+
+	scratch = qrcode;
+	out_len = buf_max;
+	if (gzip(scratch, &out_len, dataAndTemp, dataLen) != 0)
+		return false;
+
+	if (out_len + QRGZ_MAGIC_LEN > buf_max)
+		return false;
+
+	memmove(dataAndTemp + QRGZ_MAGIC_LEN, scratch, out_len);
+	memcpy(dataAndTemp, qrgz_magic, QRGZ_MAGIC_LEN);
+
+	return qrcodegen_encodeBinary(dataAndTemp, out_len + QRGZ_MAGIC_LEN,
+				      qrcode, ecl, qrcodegen_VERSION_MIN,
+				      qrcodegen_VERSION_MAX, qrcodegen_Mask_AUTO,
+				      true);
+}

-- 
2.55.0

