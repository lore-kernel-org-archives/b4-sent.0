From: Jim Cromie <jim.cromie@gmail.com>
Date: Mon, 23 Nov 2026 18:30:33 -0700
Subject: [PATCH v2 1/6] vmlinux.lds.h: drop unused HEADERED_SECTION* macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-vmlinux-lds-v2-1-6f608abfa042@gmail.com>
References: <20261123-vmlinux-lds-v2-0-6f608abfa042@gmail.com>
In-Reply-To: <20261123-vmlinux-lds-v2-0-6f608abfa042@gmail.com>
To: Arnd Bergmann <arnd@arndb.de>, Jason Baron <jbaron@akamai.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795483834; l=1326;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=r1dUyd/GOk4emgp2lEgzstB+XZAgmG/k0LwDJ33Tzlo=;
 b=XcfDf8vMztEhdf2HTQOhdE1ZtFUAGMqfXPY9KU8Ij75MN/+QowdC2Xqj1tSM4YvzVo9dU/slY
 FpMqGyi6kYUA4lCJV2+lT8uWlq1pkV7VKOI8xpKB0doWAYVMSBXs2fS
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No callers of HEADERED_SECTION* remain in the tree; drop them before
refactoring BOUNDED_SECTION_*.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 include/asm-generic/vmlinux.lds.h | 15 ---------------
 1 file changed, 15 deletions(-)

diff --git a/include/asm-generic/vmlinux.lds.h b/include/asm-generic/vmlinux.lds.h
index 3eb732942d69..67aa59f67442 100644
--- a/include/asm-generic/vmlinux.lds.h
+++ b/include/asm-generic/vmlinux.lds.h
@@ -226,21 +226,6 @@
 
 #define BOUNDED_SECTION(_sec)	 BOUNDED_SECTION_BY(_sec, _sec)
 
-#define HEADERED_SECTION_PRE_LABEL(_sec_, _label_, _BEGIN_, _END_, _HDR_) \
-	_HDR_##_label_	= .;						\
-	KEEP(*(.gnu.linkonce.##_sec_))					\
-	BOUNDED_SECTION_PRE_LABEL(_sec_, _label_, _BEGIN_, _END_)
-
-#define HEADERED_SECTION_POST_LABEL(_sec_, _label_, _BEGIN_, _END_, _HDR_) \
-	_label_##_HDR_ = .;						\
-	KEEP(*(.gnu.linkonce.##_sec_))					\
-	BOUNDED_SECTION_POST_LABEL(_sec_, _label_, _BEGIN_, _END_)
-
-#define HEADERED_SECTION_BY(_sec_, _label_)				\
-	HEADERED_SECTION_PRE_LABEL(_sec_, _label_, __start, __stop)
-
-#define HEADERED_SECTION(_sec)	 HEADERED_SECTION_BY(_sec, _sec)
-
 #ifdef CONFIG_TRACE_BRANCH_PROFILING
 #define LIKELY_PROFILE()						\
 	BOUNDED_SECTION_BY(_ftrace_annotated_branch, _annotated_branch_profile)

-- 
2.56.1

