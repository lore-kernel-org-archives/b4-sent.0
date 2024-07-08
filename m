From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:17 +0100
Subject: [PATCH kmod v2 09/17] man: depmod.d: rework the opening
 description sentence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-9-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=1496;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=83pOnT6yg/gw40nxC3Dd7S2ZNLn9m8aBas3g3i5wP+M=;
 b=461tCIdPUfs2zMojecEeXOvyCxRf+k8ix2HQ5qblwYjlVlY3KOW3WPHgs35BViLJ3A+XVqGef
 qZw17VsyCCdBPNPX6xtFdqa+YOS4PGpSUpLxWHjGEJzwCIiWg1Qt7v0
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a slightly longer, more gradual introduction.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Lucas, I'm reading the first sentence and struggling a bit. What does
the "global or per-module" refer to?

Thanks in advance o/
---
 man/depmod.d.5.scd | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
index ddb1340..dc13ec7 100644
--- a/man/depmod.d.5.scd
+++ b/man/depmod.d.5.scd
@@ -18,11 +18,14 @@ depmod.d - Configuration directory for depmod
 
 # DESCRIPTION
 
-The order in which modules are processed by the *depmod* command can be altered
-on a global or per-module basis. This is typically useful in cases where
-built-in kernel modules are complemented by custom built versions of the same
-and the user wishes to affect the priority of processing in order to override
-the module version supplied by the kernel.
+On execution *depmod* reads the configuration files from the above location and
+based on that it processes the available modules and their dependencies. For
+example: one can change the search order, exclude folders, override specific
+module's location and more.
+
+This is typically useful in cases where built-in kernel modules are complemented
+by custom built versions of the same and the user wishes to affect the priority
+of processing in order to override the module version supplied by the kernel.
 
 # CONFIGURATION FORMAT
 

-- 
2.45.2

