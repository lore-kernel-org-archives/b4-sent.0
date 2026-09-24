From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC 0/4] sysctl: add a registration context to share
 ctl_table arrays
Date: Thu, 24 Sep 2026 16:34:08 +0200
Message-Id: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOA0tWoC/x3NQQrCMBBG4auUWTsQQyjoVvAAbsVFTP7YwbSWT
 JBK6d0bXH6b91ZSFIHSuVup4Csqn6nheOgoDH56gSU2kzW2NyfrOL/zyPrTUDMP8BEl1IUrxjn
 7Ck7W4OlSSM5FapG5IMnyH9zpdr3QY9t2NvaAvXUAAAA=
X-Change-ID: 20260924-lklm-sysctl-headerctx-template-f20eb4fcf44d
To: Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 =?utf-8?q?Ondrej_Mosn=C3=A1=C4=8Dek?= <omosnacek@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Ryan Roberts <ryan.roberts@arm.com>, Serge Hallyn <serge@hallyn.com>, 
 "Eric W . Biederman" <ebiederm@xmission.com>, 
 Alexey Gladkov <legion@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2648;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=h2zuKv01W2GBHhhSPUoJkC8Y2+NacqkljzX7RT/fQr0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGq1NOQcxJriZEBqHv6XbeWhxKf+F6iCAI5fI
 yQymRMUkli6BIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqtTTkAAoJELqXzVK3
 lkFPjHoL/2JfFLokO82nj0ToZf68vDui9OHHxBd8b8icYvOFcNOrjJBroYcBLe1CRg+wcBI93cK
 RRq01tjdqCw8SBnZRgri/Zfhde6CNEA6lx/42tGex/o0IJIohASBotJx6Kpx//2mHa6mFABt0+r
 gnBokfmhdKI6s3ahk9U68WfsoTs67deaK9DBe8QMYXcKL48A/GN1uilkuH+zEiYnApnNegedbqR
 ETy7HbL5hyta6jAoat+Dp3dohap7xNtS+VUC5NZkInyJTBwNbF7b1y1Bgr5n9i65TgWzZLrGq90
 0UwirAikj7PL4RaEZsYFot4Zv6SwZRZiqWkDo9VCvps0RKDHA+uK/O2qqtdzfyJgLhkcam0Kcbm
 qVDmtO02vaQnlZp4XARAvmXhlhF2aCVJxXoup/U1rQTYbQicgg8mOG57PmGUehEL2Sa6jKwoyX/
 95H1cgsuHkf9EGQhEZTtSfJUW5hepR+ygHkheeHxtG5OBL/cKD8M7wvzjFZayuqSKUD/Fk7Rrk4
 qI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What
====
This series adds a context (containing a template and an instance
struct) to the ctl_table_header. When ctl_table entries are flagged, the
context is used to update .data against the instance given at
registration time. This is done on a stack copy just before proc_handler
and before ->permissions, so handlers keep using container_of() on .data
as they do today. The table stays const and shared, and the only change
to an entry is one .flags line.

The first two patches add the context and the resolution to the sysctl
core. The last two convert ipc and mqueue. They are an example of the
interface and show the kmemdup() going away.

Why
===
To avoid the duplication of ctl_table arrays for every namespace just to
change the ".data" member in ctl_table.

Comment on void* inside ctx
===========================
I use void pointers inside the context because I want to avoid having
non-sysctl types within sysctl. However, I do a compiler time check with
SYSCTL_CTX(_inst, _tmpl) to make sure that they are both the same time
(we can add further checks in that macro as we need them)

Comment on Alexey's series
==========================
Alexey posted a series for the same problem [1]. This RFC tries to do
the same, but with a smaller change. Both keep a struct sysctl_context
in the header. This RFC covers .data only, not the limits in
extra1/extra2, and it needs a template with a constant address, so
objects only reachable through a pointer would need an offset variant
that is not here.

Comments are greatly appreciated

Best

[1] https://lore.kernel.org/cover.1789987960.git.legion@kernel.org

PS : its always difficult for me to know who wants to be CCed in these
mails. please let me know if you want to be removed from the cc.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (4):
      sysctl: add a registration context to ctl_table_header
      sysctl: Apply sysctl context when flag is active
      ipc: Use sysctl context to register ipc namespaces
      mqueue: Use sysctl context to register mq_sysctls

 fs/proc/proc_sysctl.c  | 56 +++++++++++++++++++++++++++++++++++++----
 include/linux/sysctl.h | 55 ++++++++++++++++++++++++++++++++++++++--
 ipc/ipc_sysctl.c       | 68 ++++++++++++--------------------------------------
 ipc/mq_sysctl.c        | 44 ++++++++------------------------
 4 files changed, 130 insertions(+), 93 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260924-lklm-sysctl-headerctx-template-f20eb4fcf44d

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

