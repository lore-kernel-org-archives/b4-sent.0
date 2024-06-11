From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:14 +0100
Subject: [PATCH kmod 14/20] man: depmod: remove hard-coded /etc/depmod.d
 references
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-14-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=753;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=svS1mKkzatb4KboeBAby/QJhwwhwtB4yaO8xQj7c6fc=;
 b=Du1CxaCDg3vwYItOFdLRho4j3zFJqneHFy05JLFecogJmEj4whra41k/EyQlna7RUmEmOK7nv
 VBea2Q+mYxbD1KLqiW5g6SwBlf18JW2p1femsDxxGrL6dNN4c4vuwrR
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
2.45.0

