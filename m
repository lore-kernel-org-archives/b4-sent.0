From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 06 Aug 2025 15:08:02 +0800
Subject: [PATCH] cpupower: repair mangled powercap comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250806-mangled_cpupower-v1-1-1a559130326b@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAFH/kmgC/x2MWwqAIBAAryL7naBCZV0lIsq2WigVpQeEd0/6n
 IGZFyIGwggteyHgRZGczSALBmYb7Yqc5syghCqFFhU/stxxHow/vbsx8FLqqtbNoic1Qc58wIW
 ef9n1KX0jUQ8aYgAAAA==
X-Change-ID: 20250806-mangled_cpupower-5186789f8b2b
To: Thomas Renninger <trenn@suse.com>, Shuah Khan <shuah@kernel.org>, 
 "John B. Wyatt IV" <jwyatt@redhat.com>, John Kacur <jkacur@redhat.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wangyuli@uniontech.com, Guanwentao@uniontech.com, Zhanjun@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754464082; l=1836;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=z8rySj9NTsoDFQbVKMmerKhopsqj2e1f45A+CAKIILE=;
 b=EPWBB+fmsrLX1f39+XlFGZVEiToICCSR/A6CF96dUJ1/N3zHxAYwSC6iBslGKvtIxG0jSlxwe
 tufnSpkl2mHDyJnptQnHm/rwA0jmLlP31QewFSc0jEaQLddbEIWCX3v
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current comment exhibits clear patch application artifacts:
1. A stray '-' prefix indicating failed line removal
2. Broken sentence structure from improper context patching

What appears to be version control residue has persisted since its
initial introduction and through the 2022 kernel submission[1]. While
my archaeological efforts only trace back to the 2017 openSUSE patch[2],
the corrupted syntax suggests even older origins that remain elusive -
perhaps maintainers with longer institutional memory could shed light
on its provenance.

Restore grammatical sanity by:
- Removing the redundant second line with its leading '-'
- Preserving only the primary statement about RAPL hardcoding
- Eliminating the fragmented "should show up" clause

The result reflects reality without speculative future-proofing.

1. https://lore.kernel.org/all/20221123111810.16017-2-trenn@suse.de/
2. https://build.opensuse.org/request/show/535512

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
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

