From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:17 +0100
Subject: [PATCH kmod 17/20] man: modprobe.d: mention about MODPROBE_OPTIONS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-17-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1492;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=i0qBUwKgbC+64tmZG/2a7YKtjhyh59kDUIlSs5fyIrg=;
 b=wPqeIcdKIzbkN0BkqDZMzMtLAKjqbqmXgz44m7nHejkTwtzsHIqZY0J1hQ6xTIsgK2wCKJ378
 eWkH/qpVk4oAVzff52T/QvZYyDJvIx8ZAFYuNjxrbK9B3Q1bW83UiFs
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The environment variable alters the config file ordering, so mention it
in the man page.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Hi Lucas,

Looking at modprobe(8), while the variable is mentioned there is no
details about:
 - the format and it's stability across versions - is it ABI
 - is the same option (say config) allowed multiple times
   - if so, does the latest(?) instance override the previous ones, or
   - all instances are in effect, with the latest(?) having the highest
     priority

Can you shed some light? I'd be happy to put that in patch form :-)

Thanks
Emil
---
 man/modprobe.d.5.scd | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/man/modprobe.d.5.scd b/man/modprobe.d.5.scd
index b300758..9d03c49 100644
--- a/man/modprobe.d.5.scd
+++ b/man/modprobe.d.5.scd
@@ -46,6 +46,10 @@ the SYNOPSIS section above. Files must have the ".conf" extension. Files in
 @DISTCONFDIR@/, and /lib/. Files in /run/ override files with the same name
 under /usr/, @DISTCONFDIR@/ and /lib/.
 
+NOTE: Any configuration directories set via the MODPROBE_OPTIONS environment
+variable are added with the top-most priority. See the ENVIRONMENT section in
+*modprobe*(8).
+
 All configuration files are sorted by their filename in lexicographic order,
 regardless of which of the directories they reside in. If multiple files specify
 the same option, the entry in the file with the lexicographically latest name

-- 
2.45.0

