From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH v3 0/2] linux: fstat related changes in Linux 6.11
Date: Wed, 21 Aug 2024 21:03:52 +0800
Message-Id: <20240821-loong-fstat-v3-0-0df9bd4f7ca6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALjlxWYC/32MQQ6CMBAAv0L2bE1ZKUVP/sN4aHELmwA1LWk0h
 L9bOHkwHmeSmQUiBaYIl2KBQIkj+ynD6VBA25upI8GPzIASK9mgFIP3UydcnM0snNKusVQ1Siv
 IxTOQ49d+u90z9xxnH977PJWb/f1JpSiFPp9tXaO2Ft21Gw0Px9aPsH0S/mkxt8qgqhw5qVr6b
 td1/QBERylP4gAAAA==
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2934;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=BeO2X5dmY1fMRRf0drxnnmD7cyicgpOf9DlgP2gHRkE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxeW6Lr8WuH5fy3FGHS3wvTC8xpF09dsFrxlWt
 bZAKUDKGAeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsXlugAKCRCwMePKe/7Z
 brpCD/0TXXCa87TK+IrTieJYqc6weRw0nJ/9vAHRTG1WlSWCyNb7/r3g68ytmzDKD6+aIqRr364
 VV4DhkeiuImJn2xp1JIvuFnYI3ICXyGyCfzrbetCYuwAHIIPmtR0stJI90o35f0zQ87IwQO9eL4
 gKAAmrgG/PH8SsaxY/uem6huwzL2bHTSCEHaCqE08SGIjfNEF2uMAoigeeG4zilNz2MwjELLA98
 zWl7w62alM6uBXbeE/VdGW3n/CeA53R2XyP7qiyWtGB1r+Ql+cmi1Rs/jS7y5WOot5HhNknVaTH
 XZOk/ACHgtJr2BO+siYFbyvx1qMqTfWCl6CJj0d2jAzJWYayYdcnqfNZ76YOMNrJa9WJ+Dlt9lb
 4tLDF4xdmGB8fSlu8TIrdROaNrl2sSn8XqeCIGiBKt5YLNFTZYtYGNfDCThK1wFGcJaeiJ72HdQ
 lBmloHfLYhw98vrTtCsM04fgKGHKBVCSwmPIWvJMWkkYm2tEZZwMp8K6D5O89H4SMPWw5Ncqrxd
 OUzr74nqvPcX/GQOiRZttrelr6IVb1z3eccLaun+Ydtce6b6KyFRDHrxOdQi42NNiCPOfGH7ZYb
 4gc5s/eqdPB/a03+16tkQAc0VKZiMjqrcftucgwcjgN6b8jMGdgVRMLaEd9hXQF/34T4pRxKzQy
 gQn8Nz6V3kStZgQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kernel 6.11 adds back fstat and newfstatat in commit 7697a0fe0154
("LoongArch: Define __ARCH_WANT_NEW_STAT in unistd.h") for loongarch.
With kernel headers from 6.11, make update-syscall-lists will generate
the following diffs:

> diff --git a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> index 8bb82448a7..7e732256fd 100644
> --- a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> +++ b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> @@ -59,6 +59,7 @@
>  #define __NR_fsmount 432
>  #define __NR_fsopen 430
>  #define __NR_fspick 433
> +#define __NR_fstat 80
>  #define __NR_fstatfs 44
>  #define __NR_fsync 82
>  #define __NR_ftruncate 46
> @@ -166,6 +167,7 @@
>  #define __NR_munmap 215
>  #define __NR_name_to_handle_at 264
>  #define __NR_nanosleep 101
> +#define __NR_newfstatat 79
>  #define __NR_nfsservctl 42
>  #define __NR_open_by_handle_at 265
>  #define __NR_open_tree 428

With the changes, the compiled libraries will unexpectedly include
calls to these two syscalls, and be incompatible withi the previous
kernel versions.

This series addresses this issue by removing the two definitions if the
targeted kernel version is below 6.10.6. I have tested this patch
along with the change to arch-syscall.h with or without the
configuration option --enable-kernel=6.10.6.

Kernel 6.11 also adds support for passing NULL to statx(fd, NULL,
AT_EMPTY_PATH), which improves the performance. This series utilize this
feature when statx is used to implement fstat, on some 32-bit platforms and
on loongarch with targeting kernel version below 6.10.6.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v3:
- Changed the starting version where fstat/newfstatat are supported to
  6.10.6.
- Add a new patch to this series, addressing the support of statx(fd,
  NULL, AT_EMPTY_PATH).
- Link to v2: https://sourceware.org/pipermail/libc-alpha/2024-August/159300.html

Changes in v2:
- Improve commit message for better patch handling
- Link to v1: https://sourceware.org/pipermail/libc-alpha/2024-August/159295.html

---
Miao Wang (2):
      Loongarch: adapt for the re-introduction of fstat and newfstatat in 6.11
      linux: Add linux statx(fd, NULL, AT_EMPTY_PATH) support

 sysdeps/unix/sysv/linux/fstatat64.c                |  9 +++-
 sysdeps/unix/sysv/linux/fxstat64.c                 |  4 +-
 sysdeps/unix/sysv/linux/kernel-features.h          |  5 ++
 .../unix/sysv/linux/loongarch/kernel-features.h    | 27 +++++++++++
 sysdeps/unix/sysv/linux/loongarch/sysdep.h         |  5 ++
 sysdeps/unix/sysv/linux/statx_empty_path.h         | 53 ++++++++++++++++++++++
 6 files changed, 99 insertions(+), 4 deletions(-)
---
base-commit: 2eee835eca960c9d4119279804214b7a1ed5d156
change-id: 20240820-loong-fstat-f57f8be48575

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

