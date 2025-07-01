From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 01 Jul 2025 10:56:42 +0200
Subject: [PATCH 1/6] docs: nixify check-sysctl-docs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-jag-sysctldoc-v1-1-936912553f58@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=723;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=JVXQ/8IYf8XnXtTQdEVwyxaiGUvK4wO6JQSfGjOdsb8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjoukEx+FI2E8vSQQRccHuWoI9V1GcM0R7d
 fKbDkKzE3co9okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LpAAoJELqXzVK3
 lkFPbHMMAI06sGLAcctT2iDoYoE/iAsxas2+g68NDcMNxpeiUDzAlcKHcqy19oUW60QUNafaHbw
 XhZBaJFUFsXTtDn7IOAEtmosQ/kIHVMmkDdzvhzzOAEBxgIWTKygd7/0t5wQ+AVlJaREhqw5M4k
 ejm9QMffJ6cxlQvwlZ/B50nBTPQVPnH/LNHpP/Hc/LjZ59SrTcoOq55h5ni+/Z9hzCunhpDaV2b
 mUb44PwZRk8xanfhibjwR1CUk/EBTRNgcIPgCL66a/+AwGbEhr+TcoXVWKr+sL1tcbKxm9UNk+C
 56u4lIMZNouNy3oiDq4qx0OvjtIbRxKlCjPW+tVvi2IAqFRwTDTYCLReBxc1vQzzpRhdzFxkbF+
 eOHc4TiPgzxYqgy8WZw9Xlmd7sUlsEbgHE0miDath+JJ2jj/dCL7uwnFAW4BsupMwMZLTgFqg5X
 inKmhL/NfdUjCpkf3EPkAPpGVrqsm0pawB6v1HzsAjdY2eJTtc64AkZv4GZzNc6nmBEVpC7UuY3
 30=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use "#!/usr/bin/env -S gawk -f" instead of "#!/bin/gawk". Needed for
testing in nix environments as they only provide /usr/bin/env at the
standard location.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/check-sysctl-docs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/check-sysctl-docs b/scripts/check-sysctl-docs
index 20274c63e7451a8722137e7077f4456f293f4e54..178dcf2888ffd21845e8464fc2595052c02ff4a3 100755
--- a/scripts/check-sysctl-docs
+++ b/scripts/check-sysctl-docs
@@ -1,4 +1,4 @@
-#!/usr/bin/gawk -f
+#!/usr/bin/env -S gawk -f
 # SPDX-License-Identifier: GPL-2.0
 
 # Script to check sysctl documentation against source files

-- 
2.47.2

