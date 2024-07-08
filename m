From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:18 +0100
Subject: [PATCH kmod v2 10/17] man: depmod: remove hard-coded /etc/depmod.d
 references
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-10-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=753;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=otdwumXn7ZUPlDKiwK3+mO+jr/HiZ1lNqtK6tXl61go=;
 b=KKDGco88/YAybeur/dVau0GEX/Xlr2IgWSZP3wu7xtDJJvZQDrwWTEtee4Zy3AIQaYyoiSsAU
 2IOebVskVsJAWTDTtvq6zQ84vkTEnlYz5ld0pq03VzEMRf0yEK9O9Xd
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Point the users to depmod.d(5) instead.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/depmod.8.scd | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/man/depmod.8.scd b/man/depmod.8.scd
index 7a2e84b..0252a72 100644
--- a/man/depmod.8.scd
+++ b/man/depmod.8.scd
@@ -61,8 +61,8 @@ rather than the current kernel version (as returned by *uname -r*).
 	being the one set by _outdir_.
 
 *-C*, *--config* _file_ _or_ _directory_
-	This option overrides the default configuration directory at
-	/etc/depmod.d/.
+	This option overrides the default configuration files. See
+	*depmod.d*(5).
 
 *-e*, *--errsyms*
 	When combined with the *-F* option, this reports any symbols which a

-- 
2.45.2

