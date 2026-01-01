From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v2 0/9] SYSCTL: Consolidate do_proc_* functions into one
 macro
Date: Thu, 01 Jan 2026 13:57:04 +0100
Message-Id: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACBvVmkC/3WNwQrCMBAFf6Xs2UiSpmo9+R9SJE037WpJJClBK
 fl3Y8Gjxxl481aIGAgjnKsVAiaK5F0BuavATNqNyGgoDJLLRkhxYnc9ssEnNDfjXfQzDXpB1ug
 jV1bq2rY9lO0zoKXX1r12hSeKiw/v7SaJr/0V2z/FJBhnQom6b6U5cMUvDwwO570PI3Q55w/yN
 BBEuwAAAA==
X-Change-ID: 20251218-jag-dovec_consolidate-5a704f2a3f9b
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3344;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=P8pBvn3ZWdAwB7rC0DXSvNqtAF6IY5L/WLAEk47zMbI=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlWbym5HxbIW8nxZn775VefAYTMcqjmZinOl
 wnVI2FFkkifWokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8pAAoJELqXzVK3
 lkFPSUoL/3HcnzKn20B/Wg1/1/GsoFz797zPwcTY+WXTsaUt2agMfYVz6VIj5ttLgFla1/wQ0zP
 +GtTOs723E/p9F571U/2A76zrwqb66vna+jWbDJVwayxUZAZ+oNXUREJF8B5g6/QcPP8Gdi7xK/
 jYfstubA34Csskr6goT8Aqb3Jl4G+wA2bhLQkBAV8FuASF23nX6M34iKdy1bQ6HCtlnJGuXX1BD
 O65Q2XWjg4N1tKMBK1nnDbGQgcyJcIja4inErf4VT6X6sinU7lD3vLfQCsLrMh0g3dfoqnUdBDI
 M/a4MDp7YvPahECG9HmLmaupgkUGBiCI7TgERu4g1SUgR7WZH4A8Ab1TYh7nlsFqRAaBX4Tdw/x
 0r3sAQOFhKBCOsBnf32TillvvEoJLHnOblEr10yWD49qd6gN7JH82qVuutZu+uymEj98BXslkBq
 3sYD6RRkpFrAuqASyZe2oXuO6X9BD5fPXdfoiG/pMlBGTxPF/r1DBGuCCyIfi9B+xj+4vU54JT8
 IE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What
====
Generate do_proc_{int,uint,ulong} with the new do_proc_typevec macro.
Removed small differences between each implementation and put it all
under one roof. This macro is meant for internal (to sysctl.c) static
functions; it should not be used from the outside.

Groups and document the proc handler and converter functions in
include/linux/sysctl.h. Document how to create custom converters
with examples for every converter type.

This series sits on top of [1], you can see the working branch here [2].

Why
===
Working with one instead of three slightly different implementations of
the same thing makes more sense to me for three reasons: 1. I don't have
to think about the different types separately (less context switches),
2. One place to begin debugging proc_handler issues and 3. A fix for
one type, fixes all types.

A word on macros
================
I have mixed feelings about the use of macros here, especially because
it is such a long function. But I see it as the first step. Having this
in mainline will validate that the three types **indeed** have the same
logic (I have tested extensively, but linux-next & mainline are the
ultimate tests). Once in mainline, implementing an alternative way of
parametrizing becomes easier.

A word on checkpatch
====================
* It does not like that ENOSYS is returned for the no-op functions. I'm
  just following the pattern that was initially there. Does -EINVAL
  makes more sense?
* It has a false positive on a spacing around a pointer.

Testing
=======
Ran sysctl selftest/kunit on x86_64 and 0-day.

Changes in v2:
- Handle neg more carefully in the macro:
  1. Initialize neg to false. So it does not inadvertently return
     a negative value to user space from an unsigned variable
  2. Return -EINVAL when the user passes a negative value to an unsigned
     type.
- Link to v1: https://lore.kernel.org/r/20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org

Comments are greatly appreciated

[1] https://lore.kernel.org/20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org
[2] https://git.kernel.org/pub/scm/linux/kernel/git/joel.granados/linux.git/log/?h=jag/dovec_consolidate

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
---
Joel Granados (9):
      sysctl: Move default converter assignment out of do_proc_dointvec
      sysctl: Replace do_proc_dointvec with a type-generic macro
      sysctl: Generate do_proc_doulongvec_minmax with do_proc_dotypevec macro
      sysctl: Add negp parameter to douintvec converter functions
      sysctl: Generate do_proc_douintvec with a type-generic macro
      sysctl: Rename do_proc_dotypevec macro to do_proc_typevec
      sysctl: Group proc_handler declarations and document
      sysctl: Rename proc_doulongvec_minmax_conv to proc_doulongvec_conv
      sysctl: Update API function documentation

 fs/pipe.c              |   2 +-
 include/linux/sysctl.h | 123 +++++++----
 kernel/sysctl.c        | 541 +++++++++++++++++++++++--------------------------
 kernel/time/jiffies.c  |  28 ++-
 4 files changed, 373 insertions(+), 321 deletions(-)
---
base-commit: 0616c77e5d877006efe3bea27ca195d396de08dc
change-id: 20251218-jag-dovec_consolidate-5a704f2a3f9b

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

