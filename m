From: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Date: Fri, 05 Jun 2026 14:57:04 +0800
Subject: [PATCH RESEND] checkpatch: Suppress warnings when Reported-by: is
 followed by Link:
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-checkpatch-v1-1-8c68ae618513@linux.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OOw+CMBSF/wq5szUtPhqcHGR10NEwtJerLUZK2
 kI0hP9uwdXxnHznMUIgbynAIRvB02CDdW0SYpUBGtU+iNk6ach5vudbLhgawmenIhqmC1lz1CS
 JCkiBztPdvpeyG1zKa3k+QfXzQ68bwjg3zaSxITr/WVYHsfD/BgbBBNvJWnGUivSGH/s2/YuEZ
 o3uBdU0TV89BkK0wgAAAA==
X-Change-ID: 20260401-checkpatch-b97d0cbe7ee9
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: Andrew Morton <akpm@linux-foundation.org>, linux-doc@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, zhanjun@uniontech.com, 
 niecheng1@uniontech.com, kernel@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, Petr Vorel <pvorel@suse.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780642625; l=1814;
 i=cryolitia.pukngae@linux.dev; s=20260401; h=from:subject:message-id;
 bh=c9WOjIkf6PqQcC+UWyqhsH7Lp0mHPos984XKOAN5Tdo=;
 b=wmZomkal1ceAYLxYqsR55LBmE95VujryRzX7m4nZXkxbncAL+HlNFyns9W1vugQF9VpuvsNUC
 tdG5nZGkDf6Dw3/lubNoHtBG5fuOHAJhPQlmNOcAaM9Hs2hBtq7nwCj
X-Developer-Key: i=cryolitia.pukngae@linux.dev; a=ed25519;
 pk=kF6wBkp7j9167keuk8Q9RvPgMRPuHlJztbLy0vbJ3K0=
X-Endpoint-Received: by B4 Relay for cryolitia.pukngae@linux.dev/20260401 with auth_id=712
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cryolitia PukNgae <cryolitia@uniontech.com>

> The tag should be followed by a Closes: tag pointing to the report,
> unless the report is not available on the web. The Link: tag can be
> used instead of Closes: if the patch fixes a part of the issue(s)
> being reported.

Accroding to Documentation/process/submitting-patches.rst , Link: is
also acceptable to followed a Reported-by:, if the patch fixes a part
of the issue(s) being reported.

Reviewed-by: Petr Vorel <pvorel@suse.cz>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index 0492d6afc9a1..bb452f5313b6 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -3233,10 +3233,10 @@ sub process {
 			if ($sign_off =~ /^reported(?:|-and-tested)-by:$/i) {
 				if (!defined $lines[$linenr]) {
 					WARN("BAD_REPORTED_BY_LINK",
-					     "Reported-by: should be immediately followed by Closes: with a URL to the report\n" . $herecurr . "\n");
-				} elsif ($rawlines[$linenr] !~ /^closes:\s*/i) {
+					     "Reported-by: should be immediately followed by Closes: or Link: with a URL to the report\n" . $herecurr . "\n");
+				} elsif ($rawlines[$linenr] !~ /^(closes|link):\s*/i) {
 					WARN("BAD_REPORTED_BY_LINK",
-					     "Reported-by: should be immediately followed by Closes: with a URL to the report\n" . $herecurr . $rawlines[$linenr] . "\n");
+					     "Reported-by: should be immediately followed by Closes: or Link: with a URL to the report\n" . $herecurr . $rawlines[$linenr] . "\n");
 				}
 			}
 		}

---
base-commit: ddd664bbff63e09e7a7f9acae9c43605d4cf185f
change-id: 20260401-checkpatch-b97d0cbe7ee9

Best regards,
--  
Cryolitia PukNgae <cryolitia.pukngae@linux.dev>

