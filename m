From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v2 00/11] sysctl: Generalize proc handler converter
 creation
Date: Thu, 16 Oct 2025 14:57:46 +0200
Message-Id: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMrr8GgC/2WNywrDIBQFfyXcdS0+Semq/1FCEb0a26BBgzSE/
 HttoKsuZ+DM2aBgDljg2m2QsYYSUmzATx2YUUePJNjGwClXjDJOntqTshazTA+TYiWqpxcpnXJ
 WO2irOaML76N4HxqPoSwpr8dBZV/7a4m/VmWEEmmNUAY19kLcXpgjTueUPQz7vn8ASGbnx68AA
 AA=
X-Change-ID: 20251012-jag-sysctl_conv-570844f5fdaf
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4137;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=4+HSqZIQ5bS9EKW17QMDP9M3ASEnduvLXw6N2k0mFYQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjw69TK4Q/XJn/jNUe2s4Idect6fUZtE12V5
 urDrI+vxczpUYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8OvUAAoJELqXzVK3
 lkFPWUIL/AppNzwct+2sP6xYBFj8qjy1lU+wa6BJ35raoOLGlVN7PD5ZdINjwlXhtwMIq70O0H9
 B9KdxN5LVk1cVlNZd9xh6/irFwPgbUhSL1ZQj4DVSnrlWvzRp+qvep6G4GI+hUaccBbHJ8zoe5D
 IQOJueiLr9iA/vOrVwywyyoVnZuoVW1LUUKhXkWqsKWmRrtU5MNcueILGVB/3wDNvo0eSFCkw08
 0KJtYzhJPnbzctb6HYRlQJe/usmoOAfX9VdOFvzAUm3M9BDlqkapC3daZscAQkvfUSPqzTpbMky
 l6aWV5Zz34xn4/ZLhIi7I1SBpoLorDu/6YYLbgfijyYhaAK0SIcSh7vkQzwNtHTd8R6ssXFFJD6
 cSQpWKemFEUb0qWN9gvvmQMK+Q1NU7c9P/TaE4x84XWPhQbJoihNlHlxO5dUP9xKFhB0qnvv73K
 B78E+iFMxAnBcs0ukeHaGKynlRrgcH5+DbYpFrAme+g37O7Q4YukQxRVgcQ2k0wyNLVIZwjCzu7
 Hk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement new converter generation macros that remove repeated logic and
prep the proc handler converter infrastructure for exposure to the
greater kernel. Macros will be exposed in a later series so they can be
used in jiffies.c and pipe.c (like in this branch [1]).

What is done?
=============

Three integer macros (SYSCTL_{KERN_TO_USER,USER_TO_KERN}_INT_CONV and
SYSCTL_INT_CONV_CUSTOM) are created.
  * SYSCTL_INT_CONV_CUSTOM: creates a bi-directional (handles both user
    to kernel and kernel to user writes) converter that optionally
    implements a range checker for when kernel memory is written.
  * SYSCTL_KERN_TO_USER_INT_CONV: is a uni-directional converter that
    writes to a user buffer avoiding tears with READ_ONCE and setting
    the negp variable appropriately; it generates functions that do not
    fail.
  * SYSCTL_USER_TO_KERN_INT_CONV: is a uni-directional converter that
    writes to a kernel buffer, checks for integer overflow and avoids
    tears by using with WRITE_ONCE; returns -EINVAL when an overflow is
    detected.

Two unsigned integer macros (SYSCTL_USER_TO_KERN_UINT_CONV and
SYSCTL_UINT_CONV_CUSTOM) are created.
  * SYSCTL_UINT_CONV_CUSTOM: Same as SYSCTL_INT_CONV_CUSTOM except that
    there are no special cases for negative values.
  * SYSCTL_USER_TO_KERN_UINT_CONV: Same as SYSCTL_USER_TO_KERN_INT_CONV
    except that there is no need to indicate when the value is negative.
    The check for overflow is done against UINT_MAX instead of INT_MAX.

For now these macros produce static functions that are used from within
kernel/sysctl.c. The idea is to move them to include/kernel/sysctl.h in
another series so they can be used to create custom converters.

Why it is done?
===============

Motivation is to move non-sysctl logic out of kernel/sysctl.c which had
become a dumping ground for ctl_tables until this trend was changed by
the commits leading to (and including) 73184c8e4ff4 ("sysctl: rename
kern_table -> sysctl_subsys_table"). This series does not move the
jiffie logic out, but it sets things up so it can eventually be evicted
from kernel/sysctl.c.

Testing
=======

* I ran this through the sysctl selftests and sysctl kunit tests on an
  x86_64 arch
* This also goes through the sysctl-testing 0-day CI infra.

Versions
========

Changes in v2:
- Corrected cover letter wording
- Added macros for unsigned int converters. Three new commits:
    - sysctl: Create macro for user-to-kernel uint converter
    - sysctl: Add optional range checking to SYSCTL_UINT_CONV_CUSTOM
    - sysctl: Create unsigned int converter using new macro
  Added to prepare for when the macros will be used from outside of
  sysctl.c (to be added in another series)
- Link to v1: https://lore.kernel.org/r/20251013-jag-sysctl_conv-v1-0-4dc35ceae733@kernel.org

Any comments are greatly appreciated

[1] https://git.kernel.org/pub/scm/linux/kernel/git/joel.granados/linux.git/log/?h=jag/sysctl_jiffies

---
Joel Granados (11):
      sysctl: Replace void pointer with const pointer to ctl_table
      sysctl: Remove superfluous tbl_data param from "dovec" functions
      sysctl: Remove superfluous __do_proc_* indirection
      sysctl: Indicate the direction of operation with macro names
      sysctl: Discriminate between kernel and user converter params
      sysctl: Create converter functions with two new macros
      sysctl: Create integer converters with one macro
      sysctl: Add optional range checking to SYSCTL_INT_CONV_CUSTOM
      sysctl: Create unsigned int converter using new macro
      sysctl: Add optional range checking to SYSCTL_UINT_CONV_CUSTOM
      sysctl: Create macro for user-to-kernel uint converter

 fs/pipe.c              |   6 +-
 include/linux/sysctl.h |   5 +-
 kernel/sysctl.c        | 694 +++++++++++++++++++++----------------------------
 3 files changed, 298 insertions(+), 407 deletions(-)
---
base-commit: e5f0a698b34ed76002dc5cff3804a61c80233a7a
change-id: 20251012-jag-sysctl_conv-570844f5fdaf

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

