From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Thu, 19 Sep 2024 12:42:00 +0200
Subject: [PATCH] scripts: checkpatch: Check spaces in Makefiles.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240919-checkpatch-makefile-spaces-v1-1-f247fd2ba4cf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPf/62YC/x3MQQqEMAxA0atI1gZsEbRzFXFRY7RBR0sjIoh3t
 7h8fPg3KCdhhV9xQ+JTVPYtw5QFUPDbzChjNtjK1pUzDikwLdEfFPDvF55kZdToiRWbmsxAo22
 tI8iDmHK+vnnXP88LqSXOx2wAAAA=
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726742538; l=1959;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=cj6gu4/UTXFzy6OsqnaOr/hYFlv40OHqBGK224ZRoTY=;
 b=6NtY27pxl6eurNqMk3Nvy0KrRMsJSNpoJaZdHfi8EJQAHiHbIxaMLrMPx5VDPQnPu34NEMeVQ
 o9QTsTXClT+AH7eafe5Yw8hFOgd/BxfLK6b6LlhKbifGe2RP+v8JLYq
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I've found a Makefile that looked like this:
    obj-$(X)<tab><tab>+=<space>X.o
    obj-$(Y)<space><space>+=<space>Y.o

This patch allows checkpatch to detect this type of style error
in Makefiles. The check is disabled for the comment-only lines.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 scripts/checkpatch.pl | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index 4427572b2477..25b6f5b024c0 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -6,6 +6,7 @@
 # (c) 2007,2008, Andy Whitcroft <apw@uk.ibm.com> (new conditions, test suite)
 # (c) 2008-2010 Andy Whitcroft <apw@canonical.com>
 # (c) 2010-2018 Joe Perches <joe@perches.com>
+# (c) 2024 Tóth János <gomba007@gmail.com>
 
 use strict;
 use warnings;
@@ -3718,6 +3719,26 @@ sub process {
 			     "Use of $flag is deprecated, please use \`$replacement->{$flag} instead.\n" . $herecurr) if ($replacement->{$flag});
 		}
 
+		if ($realfile =~ /Makefile.*/ && $rawline !~ /^\+\#/) {
+			if ($rawline =~ /  /) {
+				my $herevet = "$here\n" . cat_vet($rawline) . "\n";
+				WARN("MULTIPLE_SPACES",
+				     "please, use tabs\n" . $herevet)
+			}
+
+			if ($rawline =~ / \t/) {
+				my $herevet = "$here\n" . cat_vet($rawline) . "\n";
+				WARN("SPACE_BEFORE_TAB",
+				     "please, no space before tabs, use tabs\n" . $herevet)
+			}
+
+			if ($rawline =~ /\t /) {
+				my $herevet = "$here\n" . cat_vet($rawline) . "\n";
+				WARN("TAB_BEFORE_SPACE",
+				     "please, no tab before spaces, use tabs\n" . $herevet)
+			}
+		}
+
 # check for DT compatible documentation
 		if (defined $root &&
 			(($realfile =~ /\.dtsi?$/ && $line =~ /^\+\s*compatible\s*=\s*\"/) ||

---
base-commit: 98f7e32f20d28ec452afb208f9cffc08448a2652
change-id: 20240919-checkpatch-makefile-spaces-74c1bcd2829c

Best regards,
-- 
Tóth János <gomba007@gmail.com>

