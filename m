From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 27 Jun 2025 11:27:25 +0200
Subject: [PATCH 1/5] sysctl: Nixify sysctl.sh
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250627-jag-sysctl-v1-1-20dd9801420b@kernel.org>
References: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
In-Reply-To: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=810;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=gbtN9iAolEaCiV9gpV7aHOW/rR2hqsOZc9r1CtdycQU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGheZInuFzY4h7evnT6lmDFOI2joCl1dQ00cb
 CXzz3XyO4K8gIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoXmSJAAoJELqXzVK3
 lkFPYfEL/3OwRZjo77JjVR/Y+FsoxCGJ5utRTtsTviWHC8mqOOQj1GQnMPiVSPSr35YmqOy4kCE
 ox34cAygccgUrVCcCN7x+yUtHukR1qN1qq8k3kEIZzg0YMH4harhadcGHG6eF+LbIjh7aU5YEUI
 MyZf0ALMLyO0gSwm5aEhLCOBXKL/xnrbXS6OBUqU63tqUMR3nZ9kxtdHFkIfVAU/DA6erq+zmE4
 RA7VCBCmRi3NrJ+2wxlr5hWccTJ8vgGLEYRZTLxBJL0LO4nxIzS6KCSPxwUJvSuC9ZHU8vUsnp+
 MtwKJx1XvJilir8o7t73aiHcIxDp15AGFtMP5Mu7j5Hd+Ew6f9f82JtE+lIlqwPrMksU5gCaSgh
 Yww3u/HqZY/qcD5CaN+kC7wxhSuj867+Ansb2AMFJDjNzhQTfawZoVGYMJo5NocFDXOGkaVqL35
 SWUriiBUrlUIjokINruOHPF3MAkTownu8HiyzYVhMHEYadFTtl3H89c3md4CT7nA5ZWlqcPBfh5
 Pk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use "#!/usr/bin/env bash" instead of "#!/bin/bash". Needed for testing
in nix environments as they only provide /usr/bin/env at the standard
location.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 tools/testing/selftests/sysctl/sysctl.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/sysctl/sysctl.sh b/tools/testing/selftests/sysctl/sysctl.sh
index a10350c8a46e42691f4f89763bc3e2d3dc270097..b2d8bd9026a721e96c26be20069f7f87b06a5cf7 100755
--- a/tools/testing/selftests/sysctl/sysctl.sh
+++ b/tools/testing/selftests/sysctl/sysctl.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 # SPDX-License-Identifier: GPL-2.0-or-later OR copyleft-next-0.3.1
 # Copyright (C) 2017 Luis R. Rodriguez <mcgrof@kernel.org>
 

-- 
2.47.2

