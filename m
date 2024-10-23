From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 23 Oct 2024 22:10:30 +0200
Subject: [PATCH RESEND 2/2] .b4-config: add b4 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241023-add-maintainers-file-v1-2-beaa0fdb7f8c@samsung.com>
References: <20241023-add-maintainers-file-v1-0-beaa0fdb7f8c@samsung.com>
In-Reply-To: <20241023-add-maintainers-file-v1-0-beaa0fdb7f8c@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d@kruces.com>, kdevops@lists.linux.dev, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729714235; l=1247;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=6ZdVTdaEhW89kmttz1r6ZJj8jv9rMcQnbFq107FvY5g=;
 b=+ooHcYBjtCBH+hC9ssp2BfA5PHqwU/KZa5aJLz0PY3quHAAj2kFrkxlhqFCaUppelhB3FB6JL
 6qILPwj44rsAAr6bm6saq5Wrr2QaHN4HbfL6I+SS+OlfieV+qqIRhH+
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To be able to support b4 properly, we need to configure a custom
get_maintainers.pl argument list in b4. Use the same b4 default
arguments + "--no-tree" to run the script outside a kernel tree.

Documentation b4.send-auto-to-cmd and b4.send-auto-cc-cmd:
https://b4.docs.kernel.org/en/latest/
config.html#contributor-oriented-settings

This allows to run 'b4 prep --auto-to-cc', to collect the relevant
addresses from the MAINTAINERS file for the commits/files included in
the contributor patch series.

For more information about contributor workflow:
https://b4.docs.kernel.org/en/latest/contributor/
overview.html#what-s-the-b4-contributor-workflow

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
Reviewed-by: Luis Chamberlain <mcgrof@kernel.org>
---
 .b4-config | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/.b4-config b/.b4-config
new file mode 100644
index 0000000..e6cbbe6
--- /dev/null
+++ b/.b4-config
@@ -0,0 +1,3 @@
+[b4]
+  send-auto-to-cmd = "scripts/get_maintainer.pl --nogit --nogit-fallback --nogit-chief-penguins --norolestats --nol --no-tree"
+  send-auto-cc-cmd = "scripts/get_maintainer.pl --nogit --nogit-fallback --nogit-chief-penguins --norolestats --nom --no-tree"

-- 
2.39.2

