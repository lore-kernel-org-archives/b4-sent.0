From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/6] Backport statx(..., NULL, AT_EMPTY_PATH, ...)
Date: Wed, 18 Sep 2024 22:12:19 +0800
Message-Id: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMPf6mYC/x2MQQqDMBAAvyJ77koSVmv6FekhbVa7IGlJbEgR/
 27qZWAOMxskjsIJbs0GkbMkeYcq+tLA8+XCzCi+OhhlSFk9YFrdWv58LIyLhG/BDgl/6K7Wk+m
 HXikPNf9EnqSc6xFy1xJmarWF+74frUPbBnYAAAA=
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Christoph Hellwig <hch@lst.de>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 Mateusz Guzik <mjguzik@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2501;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=MWja5gq1myzI/hKB8LURe6H7sCXfI8wL1RS650wd8Nk=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t/cJqKOM6uWkaZUkmOyn7cxe0TFjXwAm+NAJ
 Qt2UNoFUtCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurf3AAKCRCwMePKe/7Z
 bgLDD/wNnNJSwdDp7lUTdgM0o7IpmdpNVUbiCyQ6k9P90DFf4oBjy3icLJWsec5kK7lpAh+CfKo
 xEV60OI0+9W+LpgU+TP0wYjFUR4r1sOePGEPrwR4EXAkP5sS1HmdByT0/E4koN9k5VrEr5ltBn9
 SZxyVRJ9aOYbPu4nIjEcA4rudQhLHDgSieSeputBvF1/DDAIt/LgWdCJ83gj+Axjy99FXU09w+C
 ZWG2W3shPo7N9Erpu/5AdrR6P7tFvDYYzftyFgpinBarZ83S4x5IGR8eR2bBZR3th7aHwu3h3fk
 0TbtsJ6np8MHDLVrNzeLTQlU60FtGHvy8bUtfrruYBcI5BPMqPeqctlPSVXjdGRWaHrHVHhKr0e
 d1wVkkZuFGQBx5GaoJuD6dN0jifWomgU3sbXLtaBQtIPItt7gxCpNcidZkGBvMOXxBJ+m/o0TSW
 y5RkqKG1OdUla8rLqBfBcFksZ1Ygn4M4mMeSsoc7dH/ZnjHn+hZadCqm/zr5FjNYdiiEdshjmR7
 B8Fr0bufcnK/th+AXIbARaBWycGEcnxNUEsT7YiElxphqWlJVkF5rY8k6aV97qmc8mPgBVjaOy/
 rd4L4/Yf7t7NItQrwIEjmbs5HRz26pz3bv5F2La7z4DqH2CHTJjPw+5h+w5iqYPAw+3+9BU5c26
 IaTTtKQ4+MWns6A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0ef625bba6fb ("vfs: support statx(..., NULL, AT_EMPTY_PATH,
...)") added support for passing in NULL when AT_EMPTY_PATH is given,
improving performance when statx is used for fetching stat informantion
from a given fd, which is especially important for 32-bit platforms.
This commit also improved the performance when an empty string is given
by short-circuiting the handling of such paths.

This series is based on the commits in the Linus’ tree. Comparing to the
original patches, the helper vfs_empty_path() is moved to stat.c from
linux/fs.h, because get_user() is only available in fs.h since v5.7,
where commit 80fbaf1c3f29 ('rcuwait: Add @State argument to
rcuwait_wait_event()') added linux/sched/signal.h to rcuwait.h, and
uaccess.h finally got its way to fs.h along the path uaccess.h -> 
sched/task.h -> sched/signal.h -> rcuwait.h -> percpu-rwsem.h -> fs.h.
uaccess.h cannot be directly included in fs.h before v5.7, where commit
df23e2be3d24 ('acpi: Remove header dependency') removed proc_fs.h from
acpi/acpi_bus.h, preventing arch/x86/boot/compressed/cmdline.c from
indirectly including fs.h. Otherwise, the function set_fs() defined in
asm/uaccess.h will get into cmdline.c, which contains another set_fs(),
resulting conflicting function definations. There is no users of
vfs_empty_path() except stat.c, and as a result, putting it in stat.c is
acceptable.

The existing vfs_statx_fd(), which is removed since v5.10, is utilized
to implement short-circuit handling of NULL and "" paths, instead of
introducing vfs_statx_path(), simplifying the implementation.

Tested-by: Xi Ruoyao <xry111@xry111.site>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Christian Brauner (2):
      fs: new helper vfs_empty_path()
      stat: use vfs_empty_path() helper

Christoph Hellwig (2):
      fs: implement vfs_stat and vfs_lstat in terms of vfs_fstatat
      fs: move vfs_fstatat out of line

Linus Torvalds (1):
      vfs: mostly undo glibc turning 'fstat()' into 'fstatat(AT_EMPTY_PATH)'

Mateusz Guzik (1):
      vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)

 fs/stat.c          | 58 +++++++++++++++++++++++++++++++++++++++++++++++++-----
 include/linux/fs.h | 26 ++++++++++--------------
 2 files changed, 63 insertions(+), 21 deletions(-)
---
base-commit: 661f109c057497c8baf507a2562ceb9f9fb3cbc2
change-id: 20240918-statx-stable-linux-5-4-y-a79d4268600d

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

