From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 16:24:45 +0200
Subject: [PATCH 1/4] binman: fit: Actually compress generated fdt images
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-binman-fit-fdt-compression-v1-1-4465558758cc@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791642291; l=2294;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=WWCtcfzM04pZoSaC6AMeIgI+OBKsFFnA2qcX3NOlT48=;
 b=qlDB1U29okYilIdHcZjahhPdltZM9qJU+jzSvtd/kkkAQ2oSpin2MDmEZ4Jn5ZM1wPqoqQpcO
 046X/81w6bnCSgEj/mJgdeYGqXct6E2c3VPmfgM8N0ZqRZjBcA4J5TK
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reads the node's "compression" property while generating each fdt
node and actually compresses the data before writing it when the value
isn't "none". Only "lzma" is implemented for now.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/etype/fit.py | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/tools/binman/etype/fit.py b/tools/binman/etype/fit.py
index f28b1e6b4cb..026a373ff79 100644
--- a/tools/binman/etype/fit.py
+++ b/tools/binman/etype/fit.py
@@ -13,6 +13,7 @@ import os
 
 from binman.entry import Entry, EntryArg
 from binman.etype.section import Entry_section
+from binman import bintool
 from binman import elf
 from dtoc import fdt_util
 from dtoc.fdt import Fdt
@@ -853,8 +854,11 @@ class Entry_fit(Entry_section):
                     else:
                         fname = tools.get_input_filename(fdt_fname + '.dtb')
                     fdt_phase = None
+                    compression = 'none'
                     with fsw.add_node(node_name):
                         for pname, prop in node.props.items():
+                            if pname == 'compression':
+                                compression = fdt_util.GetString(node, pname)
                             if pname == 'fit,firmware':
                                 if firmware:
                                     fsw.property_string('firmware', firmware)
@@ -892,6 +896,14 @@ class Entry_fit(Entry_section):
                                 data = tools.read_file(phase_fname)
                             else:
                                 data = tools.read_file(fname)
+                            if compression != 'none':
+                                if compression != 'lzma':
+                                    self.Raise(
+                                        "Unsupported fdt compression "
+                                        f"'{compression}' (only 'lzma' is "
+                                        "implemented)")
+                                comp = bintool.Bintool.create('lzma_alone')
+                                data = comp.compress(data)
                             fsw.property('data', data)
 
                         for subnode in node.subnodes:

-- 
2.55.0

