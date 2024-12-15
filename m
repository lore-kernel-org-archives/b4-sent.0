From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 15 Dec 2024 16:38:29 +0100
Subject: [PATCH] doc: fit: Format image tree source example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241215-fdt-fmt-v1-1-81f8b27b6eb3@posteo.net>
X-B4-Tracking: v=1; b=H4sIAPT3XmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDI0Mj3bSUEt203BLdVMNUQ8vkNGMTY7M0JaDqgqLUtMwKsEnRsbW1AA4
 PRY1ZAAAA
X-Change-ID: 20241212-fdt-fmt-e1e19cf3436f
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734277122; l=3156;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Fe/VvMe3FkkIkQQKWTv32RL7TTOwDYeL00kYy3ByvZY=;
 b=pAkLTkamxuqGOIIGxaxUE/vJlHFfHoNAY8HKxJe/QOHybA2QnrNXhAJ3dlEWakqK8oJTGZTXG
 gS3fjfFnF31BnAiypk2CJZVw3M/UFj7iPmeCoKuo38HyN8yolPDSr7g
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The example in kernel_fdt.rst is inconsistently indented, making it
difficult to read.

Indent the example with the same standard as the other examples:
Four spaces for the ReST code block and for every nesting level.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 doc/usage/fit/kernel_fdt.rst | 88 ++++++++++++++++++++++----------------------
 1 file changed, 44 insertions(+), 44 deletions(-)

diff --git a/doc/usage/fit/kernel_fdt.rst b/doc/usage/fit/kernel_fdt.rst
index 9cc26fb7831e4bc244c4843645221f9643c0c1ae..3802c8292d6c5f6f30301db314d2740a52558c9d 100644
--- a/doc/usage/fit/kernel_fdt.rst
+++ b/doc/usage/fit/kernel_fdt.rst
@@ -5,50 +5,50 @@ Single kernel and FDT blob
 
 ::
 
-	/dts-v1/;
+    /dts-v1/;
 
-	/ {
-	description = "Simple image with single Linux kernel and FDT blob";
-	#address-cells = <1>;
+    / {
+        description = "Simple image with single Linux kernel and FDT blob";
+        #address-cells = <1>;
 
-	images {
-		kernel {
-		description = "Vanilla Linux kernel";
-		data = /incbin/("./vmlinux.bin.gz");
-		type = "kernel";
-		arch = "ppc";
-		os = "linux";
-		compression = "gzip";
-		load = <00000000>;
-		entry = <00000000>;
-		hash-1 {
-			algo = "crc32";
-		};
-		hash-2 {
-			algo = "sha256";
-		};
-		};
-		fdt-1 {
-		description = "Flattened Device Tree blob";
-		data = /incbin/("./target.dtb");
-		type = "flat_dt";
-		arch = "ppc";
-		compression = "none";
-		hash-1 {
-			algo = "crc32";
-		};
-		hash-2 {
-			algo = "sha256";
-		};
-		};
-	};
+        images {
+            kernel {
+                description = "Vanilla Linux kernel";
+                data = /incbin/("./vmlinux.bin.gz");
+                type = "kernel";
+                arch = "ppc";
+                os = "linux";
+                compression = "gzip";
+                load = <00000000>;
+                entry = <00000000>;
+                hash-1 {
+                    algo = "crc32";
+                };
+                hash-2 {
+                    algo = "sha256";
+                };
+            };
+            fdt-1 {
+                description = "Flattened Device Tree blob";
+                data = /incbin/("./target.dtb");
+                type = "flat_dt";
+                arch = "ppc";
+                compression = "none";
+                hash-1 {
+                    algo = "crc32";
+                };
+                hash-2 {
+                    algo = "sha256";
+                };
+            };
+        };
 
-	configurations {
-		default = "conf-1";
-		conf-1 {
-		description = "Boot Linux kernel with FDT blob";
-		kernel = "kernel";
-		fdt = "fdt-1";
-		};
-	};
-	};
+        configurations {
+            default = "conf-1";
+            conf-1 {
+                description = "Boot Linux kernel with FDT blob";
+                kernel = "kernel";
+                fdt = "fdt-1";
+            };
+        };
+    };

---
base-commit: 8aab7730c1c26192b0e4218fbf2f6009f955cb88
change-id: 20241212-fdt-fmt-e1e19cf3436f

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

