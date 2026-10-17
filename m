From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:02 +0200
Subject: [PATCH v2 3/6] binman: test: Add fit,compress device trees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-3-d7e290847543@protonmail.com>
References: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
In-Reply-To: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=2463;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=+Mpu+0oug3ucO0VgvXFvEiJfvU4lS6VnLgo7Vdl03r8=;
 b=HTHDI0K/iBm8EjgmV6yTZTOHtJC0rz66xjuNlvmJ4110tb+RNLUdlEFwyTEPeINXqq1Sn/FDd
 PdPQ73C175ABoAQyiZYIb2XJ9Q+utcwORkU3MA3GoFUj2jMuPnESVFw
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two minimal device trees with a FIT containing an @fdt-SEQ template
which uses 'fit,compress': one with "lzma", another on with "xz" which
is currently not supported in SPL and one with an unknown algorithm.

They are used by the tests in the next patch.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/test/fit/fdt_compress.dts     | 24 ++++++++++++++++++++++++
 tools/binman/test/fit/fdt_compress_bad.dts | 24 ++++++++++++++++++++++++
 tools/binman/test/fit/fdt_compress_xz.dts  | 24 ++++++++++++++++++++++++
 3 files changed, 72 insertions(+)

diff --git a/tools/binman/test/fit/fdt_compress.dts b/tools/binman/test/fit/fdt_compress.dts
new file mode 100644
index 00000000000..77c38fe9e05
--- /dev/null
+++ b/tools/binman/test/fit/fdt_compress.dts
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		fit {
+			description = "test-desc";
+			#address-cells = <1>;
+			fit,fdt-list = "of-list";
+
+			images {
+				@fdt-SEQ {
+					description = "fdt-NAME.dtb";
+					type = "flat_dt";
+					fit,compress = "lzma";
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/fit/fdt_compress_bad.dts b/tools/binman/test/fit/fdt_compress_bad.dts
new file mode 100644
index 00000000000..93ea20272a4
--- /dev/null
+++ b/tools/binman/test/fit/fdt_compress_bad.dts
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		fit {
+			description = "test-desc";
+			#address-cells = <1>;
+			fit,fdt-list = "of-list";
+
+			images {
+				@fdt-SEQ {
+					description = "fdt-NAME.dtb";
+					type = "flat_dt";
+					fit,compress = "bad";
+				};
+			};
+		};
+	};
+};
diff --git a/tools/binman/test/fit/fdt_compress_xz.dts b/tools/binman/test/fit/fdt_compress_xz.dts
new file mode 100644
index 00000000000..6c2d1c89399
--- /dev/null
+++ b/tools/binman/test/fit/fdt_compress_xz.dts
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		fit {
+			description = "test-desc";
+			#address-cells = <1>;
+			fit,fdt-list = "of-list";
+
+			images {
+				@fdt-SEQ {
+					description = "fdt-NAME.dtb";
+					type = "flat_dt";
+					fit,compress = "xz";
+				};
+			};
+		};
+	};
+};

-- 
2.55.0

