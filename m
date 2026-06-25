From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v3 00/10] sysctl: Consolidate do_proc_* functions into one
 function
Date: Thu, 25 Jun 2026 22:38:12 +0200
Message-Id: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALSRPWoC/3XNTQ6DIBCG4asY1qVhwD+66j2apkEdlNZAA4a0M
 d69aOKiC5fvl8wzMwnoDQZyyWbiMZpgnE0hThlpB2V7pKZLTTjjBXCo6VP1tHMR20frbHCj6dS
 EtFAVyzVXQsuGpNu3R20+m3u7px5MmJz/bm8irOsuygMxAmUUchCN5G3JcnZ9obc4np3vyUpGv
 jMlAwZHDE+M1hJqXRWiUfKPWZblB8+6ZOUCAQAA
X-Change-ID: 20251218-jag-dovec_consolidate-5a704f2a3f9b
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3374;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=FnrFcG+FUV3lzMmzW9w4B7dYwsGzVeVRkNtJnNzvRrk=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9kdf9+jFJgTAdzkbCTlg0ldT5yt1qswsTa
 L1F+mNosjwtpIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHXAAoJELqXzVK3
 lkFP/rML/3d/HspT7g/TuNVLEkb5VmQoIoE46VwC5rge6Dte+j2Onuj8gHUwwx8KtrobBT2lZEI
 RKdJ2h8cPRWwF0A0KJBSp9+x5PR5t4bQ0ELeE7omMhhTkaNp7Bs3wGxEwkUv9RQpTU1WABFh8fM
 8F9ujsY9/5N7Pvk7d6tDJPKZ1qn+M9HpR0K88X84dOj7BmciolEBt/4/0pF2IK8XZvWh7YRjdDX
 48QCKE+utrFr+hKj4TS2GMvsGDdHRfhpoFpz3NDL7/aXYGcLZTjMj3r6qlhCphOYEr+x7E9bKUL
 tRh5K8Jfu2WIuy5R0bGp62cJTPUCMkfQIllfbgW2C48SSKlUvqq1vm1xIRFtpe/aKlcWcQXS2Jt
 IXNZsXUVXdaLKfsHS2N5k2pjj4amCYVKsQIYieQrCiNtDIcE5h6ZRtWchcIAuev5g0M9FKJJqcE
 XU+Urjj1S8/w/EBzLisU9MfvmgI4jUrzDUWZc6vuQJoYYbDcdT/qYSOewh7rMz9Fp1gPpy0wER5
 vo=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What
====
Generate do_proc_{int,uint,ulong} with the new proc_vec_conv function.
Removed small differences between each implementation and put it all
under one roof. This function is meant for internal (to sysctl.c) static
functions; it should not be used from the outside.

Groups and document the proc handler and converter functions in
include/linux/sysctl.h. Document how to create custom converters
with examples for every converter type.

This series sits on top of v7.1, you can see the working branch here [1].

Why
===
Working with one instead of three slightly different implementations of
the same thing makes more sense to me for three reasons: 1. I don't have
to think about the different types separately (less context switches),
2. One place to begin debugging proc_handler issues and 3. A fix for
one type, fixes all types.

Why the intermediate macro
==========================
This series introduces a macro, only to remove it in the last commit.
I left it like this on purpose because I think the transition to one
function is made more clear with the intermediate step.

A word on checkpatch
====================
* It does not like that ENOSYS is returned for the no-op functions. I'm
  just following the pattern that was initially there. Does -EINVAL
  makes more sense?
* It has a false positive on a spacing around a pointer.

Testing
=======
Ran sysctl selftest/kunit on x86_64 and 0-day.

Changes in v3:
- Replaced the initial macro implementation with a function.
- Rebased on top of v7.1
- Link to v2: https://lore.kernel.org/r/20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org

Changes in v2:
- Handle neg more carefully in the macro:
  1. Initialize neg to false. So it does not inadvertently return
     a negative value to user space from an unsigned variable
  2. Return -EINVAL when the user passes a negative value to an unsigned
     type.
- Link to v1: https://lore.kernel.org/r/20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org

Comments are greatly appreciated

[1] https://git.kernel.org/pub/scm/linux/kernel/git/joel.granados/linux.git/log/?h=jag/dovec_consolidate

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
---
Joel Granados (10):
      sysctl: Move default converter assignment out of do_proc_dointvec
      sysctl: Replace do_proc_dointvec with a type-generic macro
      sysctl: Generate do_proc_doulongvec_minmax with do_proc_dotypevec macro
      sysctl: Add negp parameter to douintvec converter functions
      sysctl: Generate do_proc_douintvec with a type-generic macro
      sysctl: Rename do_proc_dotypevec macro to do_proc_typevec
      sysctl: Group proc_handler declarations and document
      sysctl: Rename proc_doulongvec_minmax_conv to proc_doulongvec_conv
      sysctl: Update API function documentation
      sysctl: Replace do_proc_typevec macro with do_proc_vec function

 fs/pipe.c              |   2 +-
 include/linux/sysctl.h | 123 +++++++++----
 kernel/sysctl.c        | 475 ++++++++++++++++++++++++++-----------------------
 kernel/time/jiffies.c  |  28 ++-
 4 files changed, 364 insertions(+), 264 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20251218-jag-dovec_consolidate-5a704f2a3f9b

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

