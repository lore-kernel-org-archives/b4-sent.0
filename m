From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:00 +0200
Subject: [PATCH v2 1/6] binman: Factor out the compression bintool lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-1-d7e290847543@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=1809;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=lDinsgehjNDmAwqHdKu/sh+Rx+4S/uawzdMkBiqzPdM=;
 b=9r43RYVP2Tbq/1EIj0Zvz5XnxqYacsrCsgMHsx96GNxtBcDudxmchc7goXMhMyAWxz0g6qeq3
 R+XccxMz6IeCmaS6Eh/MDrOQyShgrHXfgFOneEl5dbDngV3xpYVzMgr
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the compression-algorithm-to-bintool mapping out of
Entry.AddBintools() into get_comp_bintool_name() so that
it can be shared with other etypes.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 tools/binman/entry.py | 27 +++++++++++++++++++++------
 1 file changed, 21 insertions(+), 6 deletions(-)

diff --git a/tools/binman/entry.py b/tools/binman/entry.py
index 9b39c711889..5eef1d57be9 100644
--- a/tools/binman/entry.py
+++ b/tools/binman/entry.py
@@ -1297,12 +1297,27 @@ features to produce new behaviours.
         """
         algo = self.compress
         if algo != 'none':
-            algos = ['bzip2', 'gzip', 'lz4', 'lzma', 'lzo', 'xz', 'zstd']
-            if algo not in algos:
-                raise ValueError("Unknown algorithm '%s'" % algo)
-            names = {'lzma': 'lzma_alone', 'lzo': 'lzop'}
-            name = names.get(self.compress, self.compress)
-            self.comp_bintool = self.AddBintool(btools, name)
+            self.comp_bintool = self.AddBintool(
+                btools, self.get_comp_bintool_name(algo))
+
+    @staticmethod
+    def get_comp_bintool_name(algo):
+        """Get the name of the bintool which handles a compression algorithm
+
+        Args:
+            algo (str): Compression algorithm, e.g. 'gzip'
+
+        Returns:
+            str: Name of bintool
+
+        Raises:
+            ValueError: if the algorithm is not supported
+        """
+        algos = ['bzip2', 'gzip', 'lz4', 'lzma', 'lzo', 'xz', 'zstd']
+        if algo not in algos:
+            raise ValueError("Unknown algorithm '%s'" % algo)
+        names = {'lzma': 'lzma_alone', 'lzo': 'lzop'}
+        return names.get(algo, algo)
 
     @classmethod
     def AddBintool(self, tools, name):

-- 
2.55.0

