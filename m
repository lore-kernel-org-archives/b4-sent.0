From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:21 +0100
Subject: [PATCH kmod v2 13/17] man: add few mentions about MODPROBE_OPTIONS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-13-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=1611;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=jvyZXK6JVrVR8ZmU5jRnoTu3XQfa8Wl/GSRQyRWVWKc=;
 b=BH5eMfDAIX5QiKXKjOZljajYGxup435c1L2gM0lOLXB25S8fEaEL0ipRKjuQl13ahcxFqKBqw
 AulAeksUD4RBjFvg83Afn5KEBrZ2vCsvua0AwEM+1Ncl+IYP2QCn4EN
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The environment variable may alter config file ordering, so mention it
in the man page.

In addition, highlight that the format is intentionally undocumented
since the use by third parties is discouraged.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
v2: tweak (5) wording, add details to (8)
---
 man/modprobe.8.scd   | 8 ++++++--
 man/modprobe.d.5.scd | 3 +++
 2 files changed, 9 insertions(+), 2 deletions(-)

diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index b47908b..321fa59 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -192,8 +192,12 @@ database.
 
 # ENVIRONMENT
 
-The MODPROBE_OPTIONS environment variable can also be used to pass arguments to
-*modprobe*.
+The MODPROBE_OPTIONS environment variable can also be used to pass command line
+arguments to *modprobe*. The format is intentionally left undocumented, since
+the use by third-party tools and scripts is discouraged.
+
+The environment variable originates with the implementation of the install
+rules.
 
 # COPYRIGHT
 
diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
index 823ba62..b7b1942 100644
--- a/man/modprobe.d.5.scd
+++ b/man/modprobe.d.5.scd
@@ -49,6 +49,9 @@ directory they reside in. Configuration files can either be completely replaced
 priority) or partially replaced (by having a configuration file that is ordered
 later).
 
+NOTE: The configuration directories may be altered via the MODPROBE_OPTIONS
+environment variable. See the ENVIRONMENT section in *modprobe*(8).
+
 # COMMANDS
 
 alias _wildcard_ _modulename_

-- 
2.45.2

