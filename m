From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 15 Aug 2025 17:14:30 +0800
Subject: [PATCH v2] cpupower: fix mangled powercap comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-mangled_cpupower-v2-1-6ec877145c47@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAHX6nmgC/32OTQ6CMBCFr0JmbU1bUiyuuIchBspgm0hLWkAN6
 d0dOYB5q+8l72eHhNFhgmuxQ8TNJRc8gTwVYGznH8jcQAySS8U1r9hE5hOHu5nXObwwMiV0ddH
 1qHvZA8XmiKN7H5W3lti6tIT4ORY28XP/lG2CkTqlalHyUlZ9s3p6tKCxZxMmaHPOX+9rdBC0A
 AAA
X-Change-ID: 20250806-mangled_cpupower-5186789f8b2b
To: Thomas Renninger <trenn@suse.com>, Shuah Khan <shuah@kernel.org>, 
 "John B. Wyatt IV" <jwyatt@redhat.com>, John Kacur <jkacur@redhat.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wangyuli@uniontech.com, Guanwentao@uniontech.com, Zhanjun@uniontech.com, 
 Niecheng1@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755249278; l=1825;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=9ykgyTgoh2lTXbqw1zH4abC6aqqZU7uyOJ0J1/86iV8=;
 b=ifh4iMw6UDBi/MHxRQzpTQPSYx63sosgOtlReVx/ZxojPljMaonehGX2QF4yF/FLEpUHwMGnM
 3P9GbJMxTUDAwHUGvoQstp0otfJbvjTPQv53pMe0RsZ5AXS5LGrsrL+
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove leading dashes from current comments and clarify its semantics

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
The current comment exhibits a clear failed patch application artifact:
1. A stray '-' prefix indicating failed line removal
2. Broken sentence structure from improper context patching

For those interested in archaeology:

What appears to be version control residue has persisted since its
initial introduction and through the 2022 kernel submission[1]. While
my archaeological efforts only trace back to the 2017 openSUSE patch[2],
the corrupted syntax suggests even older origins that remain elusive -
perhaps maintainers with longer institutional memory could shed light
on its provenance.

1. https://lore.kernel.org/all/20221123111810.16017-2-trenn@suse.de/
2. https://build.opensuse.org/request/show/535512
---
Changes in v2:
- Simplify expression
- Link to v1: https://lore.kernel.org/r/20250806-mangled_cpupower-v1-1-1a559130326b@uniontech.com
---
 tools/power/cpupower/lib/powercap.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/tools/power/cpupower/lib/powercap.c b/tools/power/cpupower/lib/powercap.c
index 94a0c69e55ef5e4291b13a4218e706fa8d14e6a7..609943c829efce8045d97097b5f5e9ec86d0f519 100644
--- a/tools/power/cpupower/lib/powercap.c
+++ b/tools/power/cpupower/lib/powercap.c
@@ -87,8 +87,6 @@ int powercap_set_enabled(int mode)
 
 /*
  * Hardcoded, because rapl is the only powercap implementation
-- * this needs to get more generic if more powercap implementations
- * should show up
  */
 int powercap_get_driver(char *driver, int buflen)
 {

---
base-commit: 6bcdbd62bd56e6d7383f9e06d9d148935b3c9b73
change-id: 20250806-mangled_cpupower-5186789f8b2b

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

