From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:04 +0200
Subject: [PATCH v2 5/6] boot: Add a choice for the compression of the FDT
 in the FIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-5-d7e290847543@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=1762;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=4zYaQ6H7gvea7wuTACDytrlHDVzm52hqn+UVZvLezIA=;
 b=6Z4bW1d5h1MvhOicY7WOFFB1h5sjSdERn/Q4t3unKTQAh5itQ/0zSz1w2l1c6bjXF3sTCjM76
 lbe3GEyKXGACPIwrHZ3ACRWTUs2+tcymEj8NH6yhtPUnMRxcIacWQoO
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SPL_FIT_FDT_COMP so a board can select how binman compresses the
devicetrees in its FIT (none, LZMA or gzip). LZMA and gzip are the only
algorithms the SPL FIT loader can decompress. The default is none.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/Kconfig | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/boot/Kconfig b/boot/Kconfig
index 8fcdc36c931..b84a75062b4 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -236,6 +236,38 @@ config SPL_FIT_FULL_CHECK
 	  advantage of bugs or omissions in the code. This includes a bad
 	  structure, multiple root nodes and the like.
 
+choice
+	prompt "Compression of the FDT in the FIT"
+	depends on SPL_FIT
+	default SPL_FIT_FDT_COMP_NONE
+	help
+	  Select how binman compresses the devicetrees in the FIT. This is
+	  independent of the compression of U-Boot itself. SPL must be able to
+	  decompress the chosen algorithm. Only boards whose binman description
+	  uses the fit,compress property are affected.
+
+config SPL_FIT_FDT_COMP_NONE
+	bool "None"
+	help
+	  Do not compress the devicetrees. This needs no decompression support
+	  in SPL but makes the FIT larger.
+
+config SPL_FIT_FDT_COMP_LZMA
+	bool "LZMA"
+	depends on SPL_LZMA
+	help
+	  Compress the devicetrees with LZMA. This gives the smallest FIT but
+	  needs the most time and memory to decompress in SPL.
+
+config SPL_FIT_FDT_COMP_GZIP
+	bool "gzip"
+	depends on SPL_GZIP
+	help
+	  Compress the devicetrees with gzip. This decompresses faster than
+	  LZMA in SPL but the FIT is larger.
+
+endchoice
+
 config SPL_FIT_SIGNATURE
 	bool "Enable signature verification of FIT firmware within SPL"
 	depends on SPL_DM

-- 
2.55.0

