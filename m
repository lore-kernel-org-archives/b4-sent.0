From: Jim Cromie <jim.cromie@gmail.com>
Date: Mon, 23 Nov 2026 18:30:38 -0700
Subject: [PATCH v2 6/6] checkpatch: generalize linker script macro
 exceptions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-vmlinux-lds-v2-6-6f608abfa042@gmail.com>
References: <20261123-vmlinux-lds-v2-0-6f608abfa042@gmail.com>
In-Reply-To: <20261123-vmlinux-lds-v2-0-6f608abfa042@gmail.com>
To: Arnd Bergmann <arnd@arndb.de>, Jason Baron <jbaron@akamai.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>, 
 Joe Perches <joe@perches.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795483834; l=2564;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=D+nyQSgsplW6kEBtvNiftnG6J4U1bswNBaff1Gx5wkc=;
 b=Ajrfl887GBG1JbFUQRjM689KZ3y2yDRv/hRwXl8ck9wWCI2QMeShNopH1FGv9G0PyIIck+kPl
 wt3Y3aXeMUwBah2/TcdnvRDDzWOXyW4E15mkxpy649OEp5yuGFGruR8
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

checkpatch skips macro-rule checks in linker scripts; 3 of them match
only /vmlinux.lds.h and 1 matches *.lds.h.  Introduce a single
$is_linker_file = '\.lds\.h$' regex and use it across all 4 checks.

Suggested-by: Joe Perches <joe@perches.com>
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 scripts/checkpatch.pl | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index b8b64f720191..634cd7100474 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -80,7 +80,8 @@ my $git_command ='export LANGUAGE=en_US.UTF-8; git';
 my $tabsize = 8;
 my ${CONFIG_} = "CONFIG_";
 
-my %maybe_linker_symbol; # for externs in c exceptions, when seen in *vmlinux.lds.h
+my $is_linker_file = '\.lds\.h$';
+my %maybe_linker_symbol; # for externs in c exceptions, when seen in *.lds.h
 
 sub help {
 	my ($exitcode) = @_;
@@ -5416,7 +5417,7 @@ sub process {
 				# A colon needs no spaces before when it is
 				# terminating a case value or a label.
 				} elsif ($opv eq ':C' || $opv eq ':L') {
-					if ($ctx =~ /Wx./ and $realfile !~ m@.*\.lds\.h$@) {
+					if ($ctx =~ /Wx./ and $realfile !~ /$is_linker_file/) {
 						if (ERROR("SPACING",
 							  "space prohibited before that '$op' $at\n" . $hereptr)) {
 							$good = rtrim($fix_elements[$n]) . trim($fix_elements[$n + 1]);
@@ -6016,7 +6017,7 @@ sub process {
 # Usually multi-statement macros should be enclosed in a do {} while
 # (0) loop.  Grab the first statement and ensure its the whole macro
 # if its not enclosed in a known good container
-		if ($realfile !~ m@/vmlinux.lds.h$@ &&
+		if ($realfile !~ /$is_linker_file/ &&
 		    $line =~ /^.\s*\#\s*define\s*$Ident(\()?/) {
 			my $ln = $linenr;
 			my $cnt = $realcnt;
@@ -6175,7 +6176,7 @@ sub process {
 
 # check for line continuations outside of #defines, preprocessor #, and asm
 
-		} elsif ($realfile =~ m@/vmlinux.lds.h$@) {
+		} elsif ($realfile =~ /$is_linker_file/) {
 		    $line =~ s/(\w+)/$maybe_linker_symbol{$1}++/ge;
 		    #print "REAL: $realfile\nln: $line\nkeys:", sort keys %maybe_linker_symbol;
 		} else {
@@ -6192,7 +6193,7 @@ sub process {
 # single-statement macros do not need to be enclosed in do while (0) loop,
 # macro should not end with a semicolon
 		if ($perl_version_ok &&
-		    $realfile !~ m@/vmlinux.lds.h$@ &&
+		    $realfile !~ /$is_linker_file/ &&
 		    $line =~ /^.\s*\#\s*define\s+$Ident(\()?/) {
 			my $ln = $linenr;
 			my $cnt = $realcnt;

-- 
2.56.1

