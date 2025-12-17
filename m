From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/7] sysctl: Replace the converter macros with functions
Date: Wed, 17 Dec 2025 09:04:38 +0100
Message-Id: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABZkQmkC/x3MQQqAIBBA0avErBtIQ6muEi1knGyCNBQiiO6et
 HyL/x8onIULTM0DmS8pkmKFahugzcXAKL4adKeN0sri7gLGhIejnJBSvLB3xrAdicgPULsz8yr
 3/5yX9/0A1qOb+WMAAAA=
X-Change-ID: 20251216-jag-no-macro-conv-3a55e69cccd8
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1787;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=grgbd7Roh/N0T9UiQSsIvroaXuc9Ova9XMV/cH1yCQQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlCZDUV3DIaQ0HKM5Fzs252AlZ+Ze2h/ZP9D
 qZsX8b4ZzxMUokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQmQ1AAoJELqXzVK3
 lkFPkGYL/jyQWWbgPXVTr+kyOhXzgSI6vRsLEMatWZxSHaVps5SqjIE+XgVyQz2GWGV9CfJqtJt
 QKwBff1YPXc6hZjJR6k0LOsbZl5AeVZwAsnB/ssYZHFJ6DR/isBuZejx5cmYQdpoNmKdRk2ipwr
 oRxJi/PnbcRPtV9+sutvKXEI3kpRJNwinrMjQvW9SOKwPKzBRVbKO2a4dSQDDcDXjWL0b2iemej
 XsvhrlIgP/wfDho02lor1xZm0tmr4GbG03oVQyWzBdWL+o/uGED6L3Dv3EG9lF/ZP+ff5NUJMdZ
 n0balmLvlIxEQkKfRbvxlttR6zTn1oMmtQq0iqVeoszqMqcjoqV7e+FLWPyElhaNUsbtJnspK3i
 nH9mvGIQImeZl25UxT7GwVOn1/geEVIBzXen76o22O4ZfIrVZIDwUMsP31WYWyRnDvH7wG5lr5P
 YM8j88wCxyMlUOwv6z3xf+03k7x/+WJ88MP9mKoKWe6jYDrEyDV8Y+scaFFCKAfHl/Ja8+TRXB5
 KU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove all the macros that were created to get jiffies out of sysctl.c.
In [1] we leaned a bit too hard on macros to generate the converter
functions needed in jiffies.c, pipe.c and sysctl.c. In this series we
replace the macros with regular functions to help in debugging and to
better align with coding-style.rst. This series has been tested with
sysctl self tests (x86_64) and with 0-day.

A note about checkpatch: It really dislikes the use of -ENOSYS and
unused arguments in the no-op versions of the functions. These are all
false positives IMO as -ENOSYS should be returned to the syscall that is
reading or writing the proc file.

Comments are greatly appreciated

Best

[1] https://lore.kernel.org/all/tqz52ig2b5jas3qqt6jqqek7uwyg64ny5qnwy6gclhgjcy4ltb@s7jiay5vyomg/

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (7):
      sysctl: Return -ENOSYS from proc_douintvec_conv when CONFIG_PROC_SYSCTL=n
      sysctl: clarify proc_douintvec_minmax doc
      sysctl: Add CONFIG_PROC_SYSCTL guards for converter macros
      sysctl: Replace UINT converter macros with functions
      sysctl: Add kernel doc to proc_douintvec_conv
      sysctl: Replace unidirectional INT converter macros with functions
      sysctl: replace SYSCTL_INT_CONV_CUSTOM macro with functions

 fs/pipe.c              |  22 +++-
 include/linux/sysctl.h | 120 +++-------------------
 kernel/sysctl.c        | 274 +++++++++++++++++++++++++++++++++++++++++++++----
 kernel/time/jiffies.c  | 134 ++++++++++++++++++++----
 4 files changed, 403 insertions(+), 147 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251216-jag-no-macro-conv-3a55e69cccd8

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

