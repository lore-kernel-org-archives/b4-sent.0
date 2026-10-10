From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 16:24:46 +0200
Subject: [PATCH 2/4] binman: test: Add fit fdt compression device trees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-binman-fit-fdt-compression-v1-2-4465558758cc@protonmail.com>
References: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
In-Reply-To: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791642291; l=3589;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=25dRcKDeN8eZSGb06AEbdr13LFy88eBHoMFpYEseEBA=;
 b=eSf8AKTUVR6DeEHtlFtoffeLkp2FEW4BbFvWP57ybAUDZ7EEHbwaT87noRvmCR1wkAJslVn/t
 S/dgSpQk+tKAGF+qk08yHnl+A7JwtZPGryr8caAKWW1Zn9WZkdu54xU
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two copies of fit/fdt.dts whose @fdt-SEQ template asks for "lzma"
and for an unsupported algorithm ("bzip2").

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/test/fit/fdt_bad_comp.dts | 72 ++++++++++++++++++++++++++++++++++
 tools/binman/test/fit/fdt_lzma.dts     | 72 ++++++++++++++++++++++++++++++++++
 2 files changed, 144 insertions(+)

diff --git a/tools/binman/test/fit/fdt_bad_comp.dts b/tools/binman/test/fit/fdt_bad_comp.dts
new file mode 100644
index 00000000000..26a74895ac7
--- /dev/null
+++ b/tools/binman/test/fit/fdt_bad_comp.dts
@@ -0,0 +1,72 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		u-boot {
+		};
+		fit {
+			description = "test-desc";
+			#address-cells = <1>;
+			fit,fdt-list = "of-list";
+
+			images {
+				atf {
+					description = "atf firmware";
+					type = "firmware";
+					compression = "none";
+					load = <00000000>;
+					entry = <00000000>;
+				};
+				uboot {
+					description = "U-Boot firmware";
+					type = "firmware";
+					compression = "none";
+					load = <00000000>;
+					entry = <00000000>;
+				};
+				kernel {
+					description = "Vanilla Linux kernel";
+					type = "kernel";
+					arch = "ppc";
+					os = "linux";
+					compression = "gzip";
+					load = <00000000>;
+					entry = <00000000>;
+					hash-1 {
+						algo = "crc32";
+					};
+					hash-2 {
+						algo = "sha1";
+					};
+					u-boot {
+					};
+				};
+				@fdt-SEQ {
+					description = "fdt-NAME.dtb";
+					type = "flat_dt";
+					compression = "bzip2";
+					hash {
+						algo = "sha256";
+					};
+				};
+			};
+
+			configurations {
+				default = "@config-DEFAULT-SEQ";
+				@config-SEQ {
+					description = "conf-NAME.dtb";
+					firmware = "uboot";
+					loadables = "atf";
+					fdt = "fdt-SEQ";
+				};
+			};
+		};
+		u-boot-nodtb {
+		};
+	};
+};
diff --git a/tools/binman/test/fit/fdt_lzma.dts b/tools/binman/test/fit/fdt_lzma.dts
new file mode 100644
index 00000000000..1a25ded4b8b
--- /dev/null
+++ b/tools/binman/test/fit/fdt_lzma.dts
@@ -0,0 +1,72 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	binman {
+		u-boot {
+		};
+		fit {
+			description = "test-desc";
+			#address-cells = <1>;
+			fit,fdt-list = "of-list";
+
+			images {
+				atf {
+					description = "atf firmware";
+					type = "firmware";
+					compression = "none";
+					load = <00000000>;
+					entry = <00000000>;
+				};
+				uboot {
+					description = "U-Boot firmware";
+					type = "firmware";
+					compression = "none";
+					load = <00000000>;
+					entry = <00000000>;
+				};
+				kernel {
+					description = "Vanilla Linux kernel";
+					type = "kernel";
+					arch = "ppc";
+					os = "linux";
+					compression = "gzip";
+					load = <00000000>;
+					entry = <00000000>;
+					hash-1 {
+						algo = "crc32";
+					};
+					hash-2 {
+						algo = "sha1";
+					};
+					u-boot {
+					};
+				};
+				@fdt-SEQ {
+					description = "fdt-NAME.dtb";
+					type = "flat_dt";
+					compression = "lzma";
+					hash {
+						algo = "sha256";
+					};
+				};
+			};
+
+			configurations {
+				default = "@config-DEFAULT-SEQ";
+				@config-SEQ {
+					description = "conf-NAME.dtb";
+					firmware = "uboot";
+					loadables = "atf";
+					fdt = "fdt-SEQ";
+				};
+			};
+		};
+		u-boot-nodtb {
+		};
+	};
+};

-- 
2.55.0

