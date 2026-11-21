From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 21 Nov 2026 15:49:24 -0700
Subject: [PATCH 6/6] checkpatch.pl: generalize linker script macro
 exceptions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-vmlinux-lds-v1-6-49818f3f5cc0@gmail.com>
References: <20261121-vmlinux-lds-v1-0-49818f3f5cc0@gmail.com>
In-Reply-To: <20261121-vmlinux-lds-v1-0-49818f3f5cc0@gmail.com>
To: Arnd Bergmann <arnd@arndb.de>, Jason Baron <jbaron@akamai.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795301375; l=1707;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=xCW9O+AbKUBV4BIvimad+RBHO1OQaFVpJS/+K5VR+iI=;
 b=0VosmkYkQDOh1ZsR0s0Drc1tYC/PFQI9LCHx9Cf4c8dAjx0vQMsVNzfyClZpREyVYQImsWZnh
 kNWhjPL+PQdC+FS7xIoo9zNTPj0RDP3Kz5kYSu8iqHrjllNM12cdmuU
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

checkpatch skips macro-rule checks in linker scripts; 3 of them
explicitly check for vmlinux.lds.h, and 1 (the 1st) skips on any
*.lds.h.  Generalize the 3 to match the 1st, including the escapes on
the dots, so they're literal checks for '.'

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 scripts/checkpatch.pl | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index b8b64f720191..318e1f2577fd 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -6016,7 +6016,7 @@ sub process {
 # Usually multi-statement macros should be enclosed in a do {} while
 # (0) loop.  Grab the first statement and ensure its the whole macro
 # if its not enclosed in a known good container
-		if ($realfile !~ m@/vmlinux.lds.h$@ &&
+		if ($realfile !~ m@/\.lds\.h$@ &&
 		    $line =~ /^.\s*\#\s*define\s*$Ident(\()?/) {
 			my $ln = $linenr;
 			my $cnt = $realcnt;
@@ -6175,7 +6175,7 @@ sub process {
 
 # check for line continuations outside of #defines, preprocessor #, and asm
 
-		} elsif ($realfile =~ m@/vmlinux.lds.h$@) {
+		} elsif ($realfile =~ m@/\.lds\.h$@) {
 		    $line =~ s/(\w+)/$maybe_linker_symbol{$1}++/ge;
 		    #print "REAL: $realfile\nln: $line\nkeys:", sort keys %maybe_linker_symbol;
 		} else {
@@ -6192,7 +6192,7 @@ sub process {
 # single-statement macros do not need to be enclosed in do while (0) loop,
 # macro should not end with a semicolon
 		if ($perl_version_ok &&
-		    $realfile !~ m@/vmlinux.lds.h$@ &&
+		    $realfile !~ m@/\.lds\.h$@ &&
 		    $line =~ /^.\s*\#\s*define\s+$Ident(\()?/) {
 			my $ln = $linenr;
 			my $cnt = $realcnt;

-- 
2.56.1

