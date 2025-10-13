From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/8] sysctl: Generalize proc handler converter creation
Date: Mon, 13 Oct 2025 15:24:50 +0200
Message-Id: <20251013-jag-sysctl_conv-v1-0-4dc35ceae733@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKL97GgC/x3MQQqAIBBA0avErBNUkqKrRITYWBOh4UQU0t2Tl
 m/xfwbGRMjQVxkSXsQUQ4GqK3CrDQsKmotBS22UVFpsdhH8sDv3ycVwCdPKrmm88bP1UKojoaf
 7Pw7j+36lopEFYQAAAA==
X-Change-ID: 20251012-jag-sysctl_conv-570844f5fdaf
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3177;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=EQftlmgTvzftJHVOqEL+YlrIiJf4J+wLDyJnZMuRg8I=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjs/bfHX8L8LqWeSVVbJjkR/ozj7Zgcsrvnr
 r/D2BQO5rfcsYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo7P23AAoJELqXzVK3
 lkFPM+AL/3wbIXJF4mMOzfCjRJdeSYvamDvfRCzOMIYRKj10o/QVWNQYxkhpZJqqjrFFSOsf8On
 tDKgr5mkDsfJm5h1tXXa9Jsey+5NWBdOKVofjLX3huiYpKFdFPaJqO26MycOryEE9SVNE4dX2jq
 S4iZZF76eJbX7Odhc/c/rOyLHuNryc/1YAtaQCYoa01D0vO/OB+roomOkWhzoJ0kShNXJ6p5/Ml
 kKds3eIbPF5pd1+wySmlyjV6g+MTCKPGp7fBwAZW5Ulx1LMp8jBCHYAy8UhenQRWoDWj0IIhK4J
 djFPf4mL42o2yW7MgsarrX4ZMmdiW4rOk2P3c8VolFgmCPfuGpd6SNtePVlVIL26ZQKd1GtrWkA
 C2Nnn8ctQdte0LAhJfxieKjZSBcDIoGkSkzTjgY81OuM+mAJObo8XfeC7/aq6wmnCkl68nrAMo9
 oOMjkrPdoyMdlfKKLpOPxMVAfHGFUN2gkqOInxYzyBCclqitff2llmS4hxzrnu6emCO/+EVKDa7
 Wc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement new converter generation macros this removes repeated logic
and preps the proc handler converter infrastructure for exposure to the
greater kernel. Macros will be exposed in a later series in such a way
that they can be used in the jiffie proc handlers (you can see an
example of how this might look here [1]) and in the proc_dopipe_max_size.

What is done?
=============

Three macros (SYSCTL_{KERN_TO_USER,USER_TO_KERN,INT_CONV_CUSTOM}) are
created. SYSCTL_INT_CONV_CUSTOM creates a bi-directional (meaning that
it handles both user to kernel and kernel to user writes) converter that
optionally implements a range checker for when kernel memory is written.
SYSCTL_KERN_TO_USER is a uni-directional converter that writes to a user
buffer avoiding tears with READ_ONCE and setting the negp variable
appropriately; it generates functions that do not fail.
SYSCTL_USER_TO_KERN is a uni-directional converter that writes to a
kernel buffer, checks for integer overflow and avoids tears by using
with WRITE_ONCE; it returns -EINVAL when an overflow is detected.

For now these macros produce static functions that are used from within
kernel/sysctl.c but the idea is to move them to include/kernel/sysctl.h
so they can be used to create custom converters.

Why it is done?
===============

This is a prep series to get jiffies out of kernel/sysctl.c which had
become a dumping ground for a considerable number ctl_tables.

kernel/sysctl.c had become a dumping ground for a considerable amount of
ctl_tables. Though this trend was corrected in the commits leading to
73184c8e4ff4 ("sysctl: rename kern_table -> sysctl_subsys_table"), some
non-sysctl logic still remained in the form of the jiffies converters.
This series does not move the jiffie logic out, but it sets things up so
it can eventually be evicted from kernel/sysctl.c.

Testing
=======

* I ran this through the sysctl selftests and sysctl kunit tests on an
  x86_64 arch
* This also goes through the sysctl-testing 0-day CI infra.

Any comments are greatly appreciated

[1] https://git.kernel.org/pub/scm/linux/kernel/git/joel.granados/linux.git/log/?h=jag/sysctl_jiffies

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (8):
      sysctl: Replace void pointer with const pointer to ctl_table
      sysctl: Remove superfluous tbl_data param from "dovec" functions
      sysctl: Remove superfluous __do_proc_* indirection
      sysctl: Indicate the direction of operation with macro names
      sysctl: Discriminate between kernel and user converter params
      sysctl: Create converter functions with two new macros
      sysctl: Create integer converters with one macro
      sysctl: Add optional range checking to SYSCTL_INT_CONV_CUSTOM

 fs/pipe.c              |   6 +-
 include/linux/sysctl.h |   5 +-
 kernel/sysctl.c        | 648 ++++++++++++++++++++-----------------------------
 3 files changed, 269 insertions(+), 390 deletions(-)
---
base-commit: e5f0a698b34ed76002dc5cff3804a61c80233a7a
change-id: 20251012-jag-sysctl_conv-570844f5fdaf

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

