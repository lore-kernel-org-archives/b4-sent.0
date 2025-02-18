From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 18 Feb 2025 14:39:45 +0100
Subject: [PATCH] serial: ns16550: Fix pointer type mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250218-serial-type-v1-1-c05a15bd21c5@posteo.net>
X-B4-Tracking: v=1; b=H4sIAKCNtGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0MLXZD6xBzdksqCVF0Ls2RjQ0sLg+QkI1MloI6CotS0zAqwadGxtbU
 ANz12Cl0AAAA=
X-Change-ID: 20250218-serial-type-86c31980cb25
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739885990; l=2033;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=t/ngiIGfYy3uOUv1UZCztlmqW9gxocba7Dk0oGKMID0=;
 b=6pBhflOOUL5nBy12CPzIcGj4mflaevCFVTsF5jkffkTjzIHKyb1sZTzEdmSyPXM2NvTwLbjb5
 jYqBLyDCaK/D5yTLnhAadNqSYegdL0ijC0zGt0FpQwzdhmi4I68ITzp
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

serial_out_dynamic() takes a u8* addr and uses it for 8-bit or 32-bit
accesses, depending on the value of plat->reg_width. This results in a
pointer type mismatch that the compiler may even turn into an error:

drivers/serial/ns16550.c: In function ‘serial_out_dynamic’:
drivers/serial/ns16550.c:115:42: error: passing argument 1 of ‘out_be32’ from incompatible pointer type [-Wincompatible-pointer-types]
  115 |                                 out_be32(addr, value);
      |                                          ^~~~
      |                                          |
      |                                          u8 * {aka unsigned char *}

This error was observed on PowerPC.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/serial/ns16550.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/serial/ns16550.c b/drivers/serial/ns16550.c
index 042220081079382a611877aef14ab3ea4b005441..06665d1b3385d90b14c09c3f816bb01802cea2ab 100644
--- a/drivers/serial/ns16550.c
+++ b/drivers/serial/ns16550.c
@@ -112,9 +112,9 @@ static void serial_out_dynamic(struct ns16550_plat *plat, u8 *addr,
 	} else if (plat->reg_width == 4) {
 		if (plat->flags & NS16550_FLAG_ENDIAN) {
 			if (plat->flags & NS16550_FLAG_BE)
-				out_be32(addr, value);
+				out_be32((u32 *)addr, value);
 			else
-				out_le32(addr, value);
+				out_le32((u32 *)addr, value);
 		} else {
 			writel(value, addr);
 		}
@@ -132,9 +132,9 @@ static int serial_in_dynamic(struct ns16550_plat *plat, u8 *addr)
 	} else if (plat->reg_width == 4) {
 		if (plat->flags & NS16550_FLAG_ENDIAN) {
 			if (plat->flags & NS16550_FLAG_BE)
-				return in_be32(addr);
+				return in_be32((u32 *)addr);
 			else
-				return in_le32(addr);
+				return in_le32((u32 *)addr);
 		} else {
 			return readl(addr);
 		}

---
base-commit: 3b1c055bf9e254ab6395907779af4e2ce14bb7e6
change-id: 20250218-serial-type-86c31980cb25

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

