From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 08 Apr 2025 10:02:43 +0200
Subject: [PATCH 3/3] scripts: Clarify doc messages in archive-source.sh
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-jag-sysctl-v1-3-f5c4aba3e7ff@kernel.org>
References: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
In-Reply-To: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1549;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=PTQEmEN9vlIeeSga0uIH4UsLep0Yj7zyUxnE3/azy2o=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGf02FiT5lU77XOBOnPLcrO041WCwz4OONPNW
 qLz4t4m6hIjiokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9NhYAAoJELqXzVK3
 lkFPT1kL/0a9Ts19i7snCRrx2UlIS60HqnrD6rStowz2wjhypQVHsyQNnuLYU/Qy5qep+2P/xfw
 9G4PuCbXCjS1TxisNiTC7gvPe0i6ueI6+KsZ/61tFNnYLxPO6zqyz6OewXPE9Hbm+uRDkMgUdam
 MlNuD95MolWr8xQ9MiRIIVE5OyCm3Adr4UIqcbtoIBObHvdNoh7RB8XrKDU9KEZ1EbjtTSGow+2
 B6FjYy7B8ygYGZdz22ARRXN4cXzwBCPIkZ/N3WCa4ohkxY0he6UuepA8lpysG38V1nTP81a9uzG
 gGQRRLGziIBXrS2fN4ygi7V+ehZW61Mz8XT75OMyis9aEBqh7dr80IGkMVhO7GZzoQQlaXzTrp+
 qMsc123ESZgV0jQq+l1a0H9f5/6NDevSfPp2V19LNxo21fLXsmjs5uMzn+5CoCNLhNhe8n26oG9
 SPDx/t8JQGCgb+GOQqpRrFwTymCELMCpjRu2e4Evt5KzgXSYfZVTr3rVBXK/rpydb8/PxeORaF9
 OM=
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

