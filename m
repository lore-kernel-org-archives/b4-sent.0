From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:12 +0100
Subject: [PATCH kmod 12/20] man: depmod.d: factor out a CONFIGURATION
 FORMAT section
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-12-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1204;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=MBZ9u1YsdBWLrsS6IKXPuouEtLSbXg3krfB43+8XHQ4=;
 b=QJ/gnXbBCy8GK71vHXtdApLHBLnvLQfJ5TSP0TpGfLaP0nO2eS9ZY/EcS9HPPXdCq4AGuqqTA
 wSfi4WKaoa/DwyG8B86ASfpCfbvQfcwaq6WxlQ1iM6bBui9/oJydFac
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keep the description neat and tidy.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/depmod.d.5.scd | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/man/depmod.d.5.scd b/man/depmod.d.5.scd
index 9ee35e8..ef57aac 100644
--- a/man/depmod.d.5.scd
+++ b/man/depmod.d.5.scd
@@ -24,10 +24,13 @@ built-in kernel modules are complemented by custom built versions of the same
 and the user wishes to affect the priority of processing in order to override
 the module version supplied by the kernel.
 
-The format of files under depmod.d is simple: one command per line, with blank
-lines and lines starting with '#' ignored (useful for adding comments). A '\\'
-at the end of a line causes it to continue on the next line, which makes the
-files a bit neater.
+# CONFIGURATION FORMAT
+
+The configuration files contain one command per line, with blank lines and lines
+starting with '#' ignored (useful for adding comments). A '\\' at the end of a
+line causes it to continue on the next line, which makes the files a bit neater.
+
+See the COMMANDS section below for more.
 
 # CONFIGURATION DIRECTORIES AND PRECEDENCE
 

-- 
2.45.0

