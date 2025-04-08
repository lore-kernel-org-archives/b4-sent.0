From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 08 Apr 2025 22:14:48 +0200
Subject: [PATCH 3/3] scripts: Clarify doc messages in archive-source.sh
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-jag-sysctl-v1-3-3f4f38b751be@kernel.org>
References: <20250408-jag-sysctl-v1-0-3f4f38b751be@kernel.org>
In-Reply-To: <20250408-jag-sysctl-v1-0-3f4f38b751be@kernel.org>
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: qemu-devel@nongnu.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1549;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=PTQEmEN9vlIeeSga0uIH4UsLep0Yj7zyUxnE3/azy2o=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGf1g7uLEQy49b/IdJeLRAAzBd0nu2tTpwVxO
 iWD3d/F3TzecYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9YO7AAoJELqXzVK3
 lkFPeI0L/3KjR1okWTLiBDmdr2YURT1VB+4ldvkNtPbeVbAm5dabfTjFkcHqltn2Mfzw+WHUyU4
 X3mcEIIDduoKyPS0SrOxlsVz6thb1wp+OaxW5Giq6Xx/CrqizH5yCW2dyCeJEUURW8n8WGYQ8l2
 pruGWjxz/Jn4poyATlwEqMKdhhAjKp1esHIuU4PKiYKDW6BdveCr5zpb+0t21c3rOTXTM5BI7aF
 engqOFRZQtYmrTiuX81llDc3WTJ8FtwNJ5VHkzoSWBPygqqsmCUFdYT0iN3uA88U2PvLNK/MkDy
 bGnqObONi6VTb0JDXVZHrcOGaBdVDd0Rc0i4X6nJtVITZBna6kyGkfJlgu2rQtxpL/GHcQLlBrJ
 QJ6Rudu+qXuetZ6Tjox6bV0lUuHOHRuaNypUSDFmSQEV99ko5Wcdv6JrQnGhn8QVsgOC/yivXAn
 aQMtdsXKjJ+zMktcvDwSdf/y35EERR6RtiaNlnQ4gT+niQMr0Y2w+2JWTn78PZ6D9T2bbO1uEo7
 fA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/archive-source.sh | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)

diff --git a/scripts/archive-source.sh b/scripts/archive-source.sh
index 7143aaefc1133fe991b329df3c78e6ed7726322f..eb6ee715a8a3a33d8abe333fd896ad1048821b0f 100755
--- a/scripts/archive-source.sh
+++ b/scripts/archive-source.sh
@@ -2,17 +2,15 @@
 #
 # Author: Fam Zheng <famz@redhat.com>
 #
-# Archive source tree, including submodules. This is created for test code to
-# export the source files, in order to be built in a different environment,
-# such as in a docker instance or VM.
+# This script exports source files and submodules used by test code to build in
+# "different" environments such as docker or VM.
 #
 # This code is licensed under the GPL version 2 or later.  See
 # the COPYING file in the top-level directory.
 
-# We want a predictable list of submodules for builds, that is
-# independent of what the developer currently has initialized
-# in their checkout, because the build environment is completely
-# different to the host OS.
+# subprojects is a predictable list of submodules that is independent of what
+# the developer has in their checkout. This is needed because the build
+# environment is completely different to the host OS.
 subprojects="keycodemapdb libvfio-user berkeley-softfloat-3
   berkeley-testfloat-3 arbitrary-int-1-rs bilge-0.2-rs
   bilge-impl-0.2-rs either-1-rs itertools-0.11-rs proc-macro2-1-rs

-- 
2.44.1

