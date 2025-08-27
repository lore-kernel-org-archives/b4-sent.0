From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 27 Aug 2025 17:46:04 +0800
Subject: [PATCH] cpupower: fix memory leak in print_{on,off}line_cpus()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-power-memoryleak-v1-1-e4baf7b59a41@uniontech.com>
X-B4-Tracking: v=1; b=H4sIANvTrmgC/x2MSQqAMAwAvyI5W9CAVv2KeJAaNWhbScEF6d8tH
 gdm5oVAwhSgy14QOjmwdwnKPAOzjm4hxVNiwAKrokGtDn+RKEvWy7PTuCldmbpFTILWkLJDaOb
 7X/ZDjB80im1xYgAAAA==
X-Change-ID: 20250827-power-memoryleak-75c692220277
To: Thomas Renninger <trenn@suse.com>, Shuah Khan <shuah@kernel.org>, 
 "John B. Wyatt IV" <jwyatt@redhat.com>, John Kacur <jkacur@redhat.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 niecheng1@uniontech.com, zhanjun@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756287965; l=1207;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=CIlvBttpFzObEhZv2UVHoutl1JwPsF3bnPu6l999qkU=;
 b=UkmkUmpkLJ8MK37NBRy+YepHCVbC0uEGXSWXdSsHmU48X4tg2mUFA/0caUeiIZmmhCQDT/90Z
 h+n0QUp/qJXBB3a9KD/P5kwrUyM7Z3dAMu7YMmmCqJIWXJlSkBUPEzm
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

{on,off}online_cpus_str not free after use

Suggested-by: Jun Zhan <zhanjun@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 tools/power/cpupower/utils/helpers/misc.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/tools/power/cpupower/utils/helpers/misc.c b/tools/power/cpupower/utils/helpers/misc.c
index 166dc1e470ea6d70079fea6570750885d549603a..f3b4fe95520ff96a1be8b1ba8e7be1ec116b1bc0 100644
--- a/tools/power/cpupower/utils/helpers/misc.c
+++ b/tools/power/cpupower/utils/helpers/misc.c
@@ -213,6 +213,8 @@ void print_online_cpus(void)
 		bitmask_displaylist(online_cpus_str, str_len, online_cpus);
 		printf(_("Following CPUs are online:\n%s\n"), online_cpus_str);
 	}
+
+	free(online_cpus_str);
 }
 
 /* print_offline_cpus
@@ -232,6 +234,8 @@ void print_offline_cpus(void)
 		printf(_("Following CPUs are offline:\n%s\n"), offline_cpus_str);
 		printf(_("cpupower set operation was not performed on them\n"));
 	}
+
+	free(offline_cpus_str);
 }
 
 /*

---
base-commit: fab1beda7597fac1cecc01707d55eadb6bbe773c
change-id: 20250827-power-memoryleak-75c692220277

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

