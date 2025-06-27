From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/5] sysctl: Remove last two ctl_tables from the kern_table
 array
Date: Fri, 27 Jun 2025 11:27:24 +0200
Message-Id: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPxjXmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMyNz3azEdN3iyuLkkhxdCyPjxJQ0U3Njo6RUJaCGgqLUtMwKsGHRsbW
 1ABCM55RcAAAA
X-Change-ID: 20250627-jag-sysctl-823adf5732be
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2264;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=VlBSbuV26ATgj5QJpDedzhjO9BPdGw9zgUZj/bdJy/U=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGheZG85WIoisMVONIVO95YWzjTczwH2jER2l
 i8nRrb3TqJUaIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoXmRvAAoJELqXzVK3
 lkFPAiAL/3vF4gCqCRj8+Iw00lNSe6lSk5rEbDjpvuYQtRTvudFemFMWd/pSUgG7RGr6Ouyq48D
 dZVeueDgS/pqxA5bAb4+nmEpDLHxQUf6Xmkt6BH3T9Sw0l4PqXSpFDwMBXoOd8/KY5y8Lpk2gpE
 MM+w2343xdxTsoEaEzt5l4ZlWIL7QEh9DcKQ8xjOpyo6t2yt85XMf+OjIZntTOZ/BMotfkZxi/9
 wLHB1MYC/lY+o5yoHA31ZRhHPA/XGJKA5C1fWpl10orbvQpXTX8MlnOY9yfMejUtGhFLSavqR6r
 RmQzMQii6xhmb0M+1gGd7mICt7Bk9DFoNMRACH2hknP5bzVsEQPd104ZgdW8PuCjOqEM4cgMGyX
 IJWgYPYHK5HZV0DMSyViXtfFujyUad0Xle4n/O6Txlm3YOR9EupiLVKXjLlKxBH5RHxe0lWGH8s
 tGajcvqo3SvWL9O/emhv8kIU/tKFi0yLVQe7yjtUPyCaAYqnYS8Zok/1VFNsVxUH65G4Hr6oCW5
 SA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the last series to relocate sysctl tables from kernel/sysctl.c
into their respective subsystems. After the move of two ctl_tables
(uevent_helper & overflow{uid,gid}), five remain. They either handle
variables defined within sysctl.c or serve as a common place for
variables that are defined in different architectures. These five will
not be moved. Note that this series includes two auxiliary changes:
Removal of an unused variable and Nix-based rework of sysctl.sh test
script

By decentralizing sysctl registrations, subsystem maintainers regain
control over their sysctl interfaces, improving maintainability and
reducing the likelihood of merge conflicts. All this is made possible by
the work done to reduce the ctl_table memory footprint in commit
d7a76ec87195 ("sysctl: Remove check for sentinel element in ctl_table
arrays").

A few comments on the process:
1. If you prefer to merge this through a non-sysctl tree, please let me
   know so I can avoid conflicts in linux-next.
2. Apologies if you were copied by mistake—let me know if you'd like to
   be removed.
3. This series builds on [1], so please rebase accordingly for clean
   application.
4. Testing done by running sysctl selftests on x86_64 and 0-day.

Comments/Suggestions greatly appreciated

[1] https://lore.kernel.org/20250509-jag-mv_ctltables_iter2-v1-0-d0ad83f5f4c3@kernel.org

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (5):
      sysctl: Nixify sysctl.sh
      sysctl: Removed unused variable
      uevent: mv uevent_helper into kobject_uevent.c
      kernel/sys.c: Move overflow{uid,gid} sysctl into kernel/sys.c
      sysctl: rename kern_table -> sysctl_subsys_table

 include/linux/sysctl.h                   |  1 -
 kernel/sys.c                             | 29 +++++++++++++++++++
 kernel/sysctl.c                          | 49 +++++++-------------------------
 lib/kobject_uevent.c                     | 20 +++++++++++++
 tools/testing/selftests/sysctl/sysctl.sh |  2 +-
 5 files changed, 61 insertions(+), 40 deletions(-)
---
base-commit: 501dd0fbc76bcae57902ea000d9c6ccd9d5f226e
change-id: 20250627-jag-sysctl-823adf5732be

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

