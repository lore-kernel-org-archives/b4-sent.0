From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:20 +0100
Subject: [PATCH kmod v2 12/17] man: modprobe.d: factor out a CONFIGURATION
 FORMAT section
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-12-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=1209;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=NiOhn7IMbJ4OSc6NZUJE+4c+XAAVRQTVxShgJHylHo4=;
 b=9YD5uK+5V72UztVpMETyIgDZY4jL8ArhdBZHxdkdYKcncl1XClzGoQhLWFE0Or6fDuNudfXwI
 R3LuMZ9K2I2AqWGCF9QSzYmzGj6rJWHYz39YCoxhzdEx49FOy7JoIId
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keep the description neat and tidy.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/modprobe.d.5.scd | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
index 2a6a789..823ba62 100644
--- a/man/modprobe.d.5.scd
+++ b/man/modprobe.d.5.scd
@@ -29,10 +29,13 @@ Note that module and alias names (like other module names) can have - or \_ in
 them: both are interchangeable throughout all the module commands as underscore
 conversion happens automatically.
 
-The format of files under modprobe.d is simple: one command per line, with blank
-lines and lines starting with '#' ignored (useful for adding comments). A '\\'
-at the end of a line causes it to continue on the next line, which makes the
-file a bit neater.
+# CONFIGURATION FORMAT
+
+The configuration files contain one command per line, with blank lines and lines
+starting with '#' ignored (useful for adding comments). A '\\' at the end of a
+line causes it to continue on the next line, which makes the files a bit neater.
+
+See the COMMANDS section below for more.
 
 # CONFIGURATION DIRECTORIES AND PRECEDENCE
 

-- 
2.45.2

