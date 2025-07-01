From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 01 Jul 2025 10:56:43 +0200
Subject: [PATCH 2/6] docs: Use skiplist when checking sysctl admin-guide
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-jag-sysctldoc-v1-2-936912553f58@kernel.org>
References: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
In-Reply-To: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
To: Kees Cook <kees@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1565;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=4SwDv1lBWtZq4b3iXzi192DtKqn0vm08JtS+5Pq6gkE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjouk395j9INJu6XGoPtLhnYLVRImz/idRJ
 Bw1XhnQJa7A9IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LpAAoJELqXzVK3
 lkFPByAL/AhVuluFhQDaN1/+hYluKuL1g+JPOvAP4y4xv+4ypZ8F5drM1GN4DF5TmyoRLxXOSte
 Hk+Owhk8bCsbQqMwaFhnSyAoEP0OgJFGOClUi+dqj8sVzOrrGVn26h9cXIHZitUYwb1THgZY6b3
 Xn1k+BKUbkBU+jC34bUPBsHU5ikcShW6sVXGUTedVUutMDzCRknCEcEWDMPRIYtiboRU/FFY9cD
 cgNpkgw/IM3udgid7ijUOoYclmWebEdkcp3wJq0Aq/UVB2wJk0LXUQMomqlk6TeeulnBOOoS+6L
 u+h4pQ44Rw2zBEDS96IOrpN0RwHGaqVFVwzxj2GGQyxqk/BwxDjll1F3HcOpjhIHFC6M3ZsI89l
 6aykS9jwuHMXaAk1aycsIZHgJhkWvSQqyEiN6IEQ46wObE4ygQTjlcHFlqDjmOUxXr4G99RdwLx
 liuj2ppd7SGWMIkl0sOX3OW/3VdiPiZ/D/m+INYc5s50dxN6A8LQlzXDgcJbGtaptV28509kBi3
 WU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a skiplist to "skip" the titles in the guide documentation
(Documentation/admin-guide/sysctl/*) that are not sysctls. This will
give a more accurate account of what sysctl are miss-documented.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/check-sysctl-docs | 21 +++++++++++++++++----
 1 file changed, 17 insertions(+), 4 deletions(-)

diff --git a/scripts/check-sysctl-docs b/scripts/check-sysctl-docs
index 178dcf2888ffd21845e8464fc2595052c02ff4a3..568197cb1c0a84147785f05aabbbc6ab9dd896bc 100755
--- a/scripts/check-sysctl-docs
+++ b/scripts/check-sysctl-docs
@@ -17,6 +17,18 @@ BEGIN {
 	print "Please specify the table to look for using the table variable" > "/dev/stderr"
 	exit 1
     }
+
+	# Documentation title skiplist
+	skiplist[0] = "^Documentation for"
+	skiplist[1] = "Network core options$"
+	skiplist[2] = "POSIX message queues filesystem$"
+	skiplist[3] = "Configuration options"
+	skiplist[4] = ". /proc/sys/fs"
+	skiplist[5] = "^Introduction$"
+	skiplist[6] = "^seccomp$"
+	skiplist[7] = "^pty$"
+	skiplist[8] = "^firmware_config$"
+	skiplist[9] = "^random$"
 }
 
 # The following globals are used:
@@ -53,10 +65,11 @@ function printentry(entry) {
 
 # Stage 1: build the list of documented entries
 FNR == NR && /^=+$/ {
-    if (prevline ~ /Documentation for/) {
-	# This is the main title
-	next
-    }
+	for (i in skiplist) {
+		if (prevline ~ skiplist[i]) {
+			next
+		}
+	}
 
     # The previous line is a section title, parse it
     $0 = prevline

-- 
2.47.2

