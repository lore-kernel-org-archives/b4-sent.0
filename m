From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Wed, 04 Nov 2026 12:19:10 -0600
Subject: [PATCH v2] doc: process: clarify scope of applying-patches as
 legacy reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261104-doc-patch-fix-v2-1-3601fc35c505@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMQQqDMBAAvyJ77hY3pIo99R/FQ9ysulCNJCIt4
 t+beu9xBmZ2SBJVEtyLHaJsmjTMGcylAB7dPAiqzwymNBVRadEHxsWtPGKvbyyNJelEGnOzkJs
 lStbn79lmHjWtIX7O/UY/+++0ERJWVHPX9Ja9rR/D5PR15TBBexzHF5c/gtuqAAAA
X-Change-ID: 20261104-doc-patch-fix-0241ebee9254
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: workflows@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>, 
 AleSZLucero <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793816438; l=2489;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=sMEgG92lV2S8wukRLwczoLII7snNh4u8DlMtfw3Y3JE=;
 b=XSmrTokT80a04Dod8J6Yb+qjh0NhrufV+RdRnf3zjFMN4o3B2ini6YGZX0ZOY44YeixCC8gKV
 YhVQzSOH26wAA6nH4Nc4pZ7TWqOwd2hJNis52Ou3f7zAn7Vzz10Wq2S
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
Signed-off-by: AleSZLucero <aleszlucero@gmail.com>
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20261104-doc-patch-fix-v1-1-617cb9f4cd47@gmail.com
---
 Documentation/process/applying-patches.rst | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/Documentation/process/applying-patches.rst b/Documentation/process/applying-patches.rst
index c269f5e1a0a3..285efb6e2df4 100644
--- a/Documentation/process/applying-patches.rst
+++ b/Documentation/process/applying-patches.rst
@@ -8,8 +8,15 @@ Original by:
 
 .. note::
 
-   This document is obsolete.  In most cases, rather than using ``patch``
-   manually, you'll almost certainly want to look at using Git instead.
+   This document focuses on the legacy method of manually manipulating source 
+   trees using the traditional ``patch`` and ``diff`` utilities. 
+
+   For the standard Git-based workflow used to clone the repository and work 
+   with kernel patches, please refer to :ref:`howto`.
+
+   The information below is maintained as a reference for constrained 
+   environments or legacy workflows where Git infrastructure is unavailable.
+
 
 A frequently asked question on the Linux Kernel Mailing List is how to apply
 a patch to the kernel or, more specifically, what base kernel a patch for
@@ -20,7 +27,6 @@ In addition to explaining how to apply and revert patches, a brief
 description of the different kernel trees (and examples of how to apply
 their specific patches) is also provided.
 
-
 What is a patch?
 ================
 

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261104-doc-patch-fix-0241ebee9254

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

