From: AleSZLucero <aleszlucero@gmail.com>
Date: Wed, 04 Nov 2026 07:53:29 -0600
Subject: [PATCH] doc: process: clarify scope of applying-patches as legacy
 reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-doc-patch-fix-v1-1-617cb9f4cd47@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bkHFgvpKdDDdci8qGhGIf086z
 sBMhUKZqcA6VMj0cOEYOshxAOtNuAjZdQYl1Cyl0OiixWRu6/HkF4XSkg6iRU0aepMydf3/tr2
 1D2sqEiRfAAAA
X-Change-ID: 20261104-doc-patch-fix-0241ebee9254
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: workflows@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, AleSZLucero <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793800413; l=2000;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=6D7WcOq0h4YcM4Z4K2LccHCGleOSZiNJjyl0B7SS6fs=;
 b=NAaFqc7c38Fl8v4KPRiEc7EEuhMVfWxXk7IRJiaZPfgi/+WI/NbrbrsMzUxEx3/MolYjrwp4X
 Nq5d0DITiXTBVktkAEHKKyNP63JBcyzymU5kGdUviMGqp4Kp3SHfWz2
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
as a reference for legacy or constrained workflows. Provide direct
cross-references to submitting-patches.rst and howto.rst to steer
contributors toward the standard Git infrastructure.

Signed-off-by: AleSZLucero <aleszlucero@gmail.com>
---
 Documentation/process/applying-patches.rst | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/Documentation/process/applying-patches.rst b/Documentation/process/applying-patches.rst
index c269f5e1a0a3..74af6d8a2249 100644
--- a/Documentation/process/applying-patches.rst
+++ b/Documentation/process/applying-patches.rst
@@ -8,8 +8,15 @@ Original by:
 
 .. note::
 
-   This document is obsolete.  In most cases, rather than using ``patch``
-   manually, you'll almost certainly want to look at using Git instead.
+   This document focuses on the legacy method of manually manipulating source
+   trees using the traditional ``patch`` and ``diff`` utilities.
+
+   For the standard Git-based workflow used in current development, including
+   how to format, apply, and send patches via Git, please refer to
+   :ref:`submitting_patches` and :ref:`howto`.
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
AleSZLucero <aleszlucero@gmail.com>

