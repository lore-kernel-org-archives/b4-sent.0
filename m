From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Thu, 05 Nov 2026 13:14:05 -0600
Subject: [PATCH v4] doc: process: clarify scope of applying-patches as
 legacy reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261105-doc-patch-fix-v4-1-3eb49e363f64@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33MSwqDMBSF4a1Ixk3JzUNrR91H6UBvbjRQjaiEF
 nHvjY5KoQ7Pge9f2ESjp4lds4WNFP3kQ5+GPmUM26pviHubNpNC5gBCcxuQD9WMLXf+xYXUQDV
 RKY1myQwjpXvv3R9pt36aw/je8xG2918pAgeeQ4F16TRaXdyarvLPM4aObaUoD7VMWuUCHCqDR
 phfrQ61StoVgHixZAtbfut1XT+8xyF6JgEAAA==
X-Change-ID: 20261104-doc-patch-fix-0241ebee9254
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, aleszlucero@gmail.com
Cc: workflows@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793906058; l=2347;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=uXAeXMYJHBZaq18If5t37B8wZb2wghKi5aFBALJmnDg=;
 b=khlWhtgm3JIArww2rBqs4kYMf3N+eC2YdcxDXdzbYFWUnNfeTTQyzy1t2hsgJBvRo1GCKxf/v
 dsCfLkNF+lxBh4wxMs4RfXEp8j7W1aFBbPcZfL18pwyTeNb48bsR6Ia
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The applying-patches.rst document describes the manual manipulation of
source trees using the traditional 'patch' and 'diff' utilities. While
technically accurate for non-Git or constrained environments, it can
create friction for new contributors seeking the primary Git-based
workflows.

Update the opening note to explicitly state that this document serves
as a reference for legacy or constrained workflows. Provide a direct
cross-reference to howto.rst to steer contributors toward the standard
Git infrastructure.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Update the applying-patches.rst document to clarify that it serves as a
reference for legacy or constrained workflows where Git infrastructure
is unavailable, redirecting new contributors to standard Git-based tools.
---
Changes in v4:
- Restored missing blank line, cleaned template markers, dropped duplicated alias, and updated links across versions v1 to v4.
---
 Documentation/process/applying-patches.rst | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/Documentation/process/applying-patches.rst b/Documentation/process/applying-patches.rst
index c269f5e1a0a3..70142c8ec9a3 100644
--- a/Documentation/process/applying-patches.rst
+++ b/Documentation/process/applying-patches.rst
@@ -8,8 +8,14 @@ Original by:
 
 .. note::
 
-   This document is obsolete.  In most cases, rather than using ``patch``
-   manually, you'll almost certainly want to look at using Git instead.
+   This document focuses on the legacy method of manually manipulating source 
+   trees using the traditional ``patch`` and ``diff`` utilities. 
+
+   For the standard Git-based workflow used to clone the repository and work 
+   with kernel patches, please refer to Documentation/process/howto.rst.
+
+   The information below is maintained as a reference for constrained 
+   environments or legacy workflows where Git infrastructure is unavailable.
 
 A frequently asked question on the Linux Kernel Mailing List is how to apply
 a patch to the kernel or, more specifically, what base kernel a patch for

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261104-doc-patch-fix-0241ebee9254

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

