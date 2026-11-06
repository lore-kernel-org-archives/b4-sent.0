From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Fri, 06 Nov 2026 15:49:52 -0600
Subject: [PATCH] doc: process: clarify legacy status of applying-patches
 and point to Git
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261106-doc-modernize-git-v1-1-8b59c1a578ba@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMBAF0avI1i64EVJ4FbEI5hu3MJFERBTvb
 rB8xcxDBVlRaGgeyji1aIoV0jY0ry4GsPpqMp2xIp1ln2bekkeOeoODHixwkN4JrOmpdnvGotf
 /HKf3/QAr9AyCYwAAAA==
X-Change-ID: 20261106-doc-modernize-git-1eae13a1e623
To: corbet@lwn.net, aleszlucero@gmail.com
Cc: rdunlap@infradead.org, krzk@kernel.org, wy@wyuan.org, 
 workflows@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794001826; l=2295;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=FfmGaQr2PKw9L5UvENGZLwJkaVf3M6sYK2t9mS4IA9Q=;
 b=qPWnFdIadXQLDEOV/h49Nc6q7aih2Vny04cBm74A96kxu1S48fDPvEOo4mVC4VOwOTBHtFzOC
 WI3IL+4cJxJAHlmSF3d0hcBEV43x5/eQDZwQyssZ2An4hUwRETenC/x
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The applying-patches.rst document heavily details the legacy 'patch'
utility, which creates confusion for new contributors since current
development relies almost entirely on Git infrastructure.

This patch updates the opening notes to explicitly mark the manual
patching process as a legacy reference and redirects readers to
contemporary Git-based guides.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
The applying-patches.rst document heavily details the legacy 'patch'
utility, which creates confusion for new contributors since current
development relies almost entirely on Git infrastructure.

This series updates the introduction to explicitly mark the manual 
patching process as a legacy reference and redirects readers to 
contemporary Git-based guides.

Thanks to Randy Dunlap, Krzysztof Kozlowski, and Weijie Yuan for 
their initial conceptual review and support.
---
 Documentation/process/applying-patches.rst | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/Documentation/process/applying-patches.rst b/Documentation/process/applying-patches.rst
index c269f5e1a0a3..2ccd74d6dd05 100644
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
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261106-doc-modernize-git-1eae13a1e623

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

