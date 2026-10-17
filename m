From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:01 +0200
Subject: [PATCH v2 2/6] binman: fit: Add fit,compress for generated fdt
 images
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-2-d7e290847543@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=5801;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=7FbrXVZt4C9C2kOpsqvK4cKFKYZgImZaeW+ksMMkbcE=;
 b=9OFQpxTfPKCziyiJoG+PcfAbRFM/4BkMOPs1HftCcRzo1reOgOt4dgAnONAZlL30Iinj3TzA4
 GAJvFoZXv/eBXeqQLYH8mpLbcQljct7BYcPYMKuzmj5ilbVscSdi3KW
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 'compression' property of a FIT image is only metadata.

Add a 'fit,compress' property for generator nodes. It names the
algorithm so binman compresses each .dtb with it and writes
the algorithm to 'compression' in the generated node.

Any algorithm known to Entry.AddBintools() is accepted.

Register the needed bintools in Entry_fit.AddBintools() and
report a missing one in the usual way instead of failing.

Document the property.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/etype/fit.py | 67 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 67 insertions(+)

diff --git a/tools/binman/etype/fit.py b/tools/binman/etype/fit.py
index 4657ed1fd76..a81e3a1de0e 100644
--- a/tools/binman/etype/fit.py
+++ b/tools/binman/etype/fit.py
@@ -274,6 +274,29 @@ class Entry_fit(Entry_section):
     string from the root node of the devicetree, so that things work correctly
     with FIT's configuration-matching algortihm.
 
+    Compressing the FDT images
+    ~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+    The 'compression' property of an image node is copied into the FIT as
+    metadata only. It tells the loader how the data is stored, but binman does
+    not touch the data.
+    For generated FDT nodes, the 'fit,compress' property can be used to ask
+    binman to compress the .dtb as well. The algorithm is written to
+    the 'compression' property of each generated node, so it should
+    not also be given there::
+
+        images {
+            @fdt-SEQ {
+                description = "fdt-NAME";
+                type = "flat_dt";
+                fit,compress = "lzma";
+            };
+        };
+
+    Any algorithm supported by binman can be used (see the 'compress' property
+    of entries) except "xz" which FIT does not define or "none". The matching
+    compression tool must be installed.
+
     Dealing with phases
     ~~~~~~~~~~~~~~~~~~~
 
@@ -746,6 +769,26 @@ class Entry_fit(Entry_section):
 
         return tools.read_file(output_fname)
 
+    def _compress_fdt(self, algo, data):
+        """Compress the data of a generated fdt node
+
+        Args:
+            algo (str): Compression algorithm
+            data (bytes): Data to compress
+
+        Returns:
+            bytes: Compressed data
+
+        Raises:
+            ValueError: if the compression tool is not available
+        """
+        btool = self.fdt_comp_bintools[algo]
+        if not btool.is_present():
+            raise ValueError(
+                f"Cannot compress fdt with '{algo}': tool '{btool.name}' is "
+                f"missing")
+        return btool.compress(data)
+
     def _raise_subnode(self, node, msg):
         """Raise an error with a paticular FIT subnode
 
@@ -883,6 +926,7 @@ class Entry_fit(Entry_section):
                     else:
                         fname = tools.get_input_filename(fdt_fname + '.dtb')
                     fdt_phase = None
+                    compress = 'none'
                     with fsw.add_node(node_name):
                         for pname, prop in node.props.items():
                             if pname == 'fit,firmware':
@@ -902,6 +946,9 @@ class Entry_fit(Entry_section):
                                 fsw.property('compatible', prop.bytes)
                             elif pname == 'fit,fdt-phase':
                                 fdt_phase = fdt_util.GetString(node, pname)
+                            elif pname == 'fit,compress':
+                                compress = fdt_util.GetString(node, pname)
+                                fsw.property_string('compression', compress)
                             elif pname.startswith('fit,'):
                                 self._raise_subnode(
                                     node, f"Unknown directive '{pname}'")
@@ -922,6 +969,8 @@ class Entry_fit(Entry_section):
                                 data = tools.read_file(phase_fname)
                             else:
                                 data = tools.read_file(fname)
+                            if compress != 'none':
+                                data = self._compress_fdt(compress, data)
                             fsw.property('data', data)
 
                         for subnode in node.subnodes:
@@ -1148,10 +1197,28 @@ class Entry_fit(Entry_section):
             entry.SetImagePos(image_pos + self.offset)
 
     def AddBintools(self, btools):
+        # Add the tool for each algorithm requested by a generator node
         super().AddBintools(btools)
         self.mkimage = self.AddBintool(btools, 'mkimage')
         self.fdtgrep = self.AddBintool(btools, 'fdtgrep')
 
+        self.fdt_comp_bintools = {}
+        def _add_comp_bintools(node):
+            for prop in node.props.values():
+                if prop.name == 'fit,compress' and prop.value != 'none':
+                    if prop.value == 'xz':
+                        self._raise_subnode(
+                            node, "fit,compress 'xz' is not a FIT compression")
+                    try:
+                        name = self.get_comp_bintool_name(prop.value)
+                    except ValueError as exc:
+                        self._raise_subnode(node, str(exc))
+                    self.fdt_comp_bintools[prop.value] = self.AddBintool(
+                        btools, name)
+            for subnode in node.subnodes:
+                _add_comp_bintools(subnode)
+        _add_comp_bintools(self._node)
+
     def CheckMissing(self, missing_list):
         # We must use our private entry list for this since generator nodes
         # which are removed from self._entries will otherwise not show up as

-- 
2.55.0

