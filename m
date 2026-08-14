From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v2 0/4] sysctl: Disallow partial updates of miss-formatted
 sysctl vectors
Date: Fri, 14 Aug 2026 12:41:11 +0200
Message-Id: <20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMfwfmoC/32NQQ6CMBBFr0JmbU0LQtGV9zDElHaACRXIlDQaw
 t2tHMDle8l/f4OATBjglm3AGCnQPCXITxnYwUw9CnKJIZd5JWtVCD/6l1gMr2T8064+ohWtq+t
 Kt1q60kJaLowdvY/qo0k8UFhn/hwnUf3s/15UQgrXXbFUVhVaXu4j8oT+PHMPzb7vX/lcKly3A
 AAA
X-Change-ID: 20260813-lklm-partial_ctlvec-bd8867b70d5c
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: Jianlin Shi <shijianlin11@foxmail.com>, akpm@linux-foundation.org, 
 vbabka@kernel.org, hannes@cmpxchg.org, surenb@google.com, mhocko@suse.com, 
 jackmanb@google.com, ziy@nvidia.com, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-mm@kvack.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2346;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=VImGdtbQhVpxolptJjq7ucid3bvJX7n+SBXE+EDTI6I=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGp+8M9/63kdDlD1fFzjnvUMsa3BnyokcX0Mn
 YEESFUZ+6VyCIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqfvDPAAoJELqXzVK3
 lkFPX4gMAItfGWXct2+B8L4J8D1LbaCtRErVfSZzNrw+UZZyeZNt9JD07OYY9rsCAbsAFl9WfUZ
 h5bHqfGZYsTC3CqgEuMBBWzNfjbfbY8tRsSDYbAjhtuRa12ARpdCY1foDgI9LQVRFobA6pdfM2g
 5G3VdUH2cxloE2AINCYY5ntOz/JXI3vgTm7IY23HTYa6PbmfGxsGHG9oy5da6OY1YwuW7a6z8ST
 xJ/AGN/QeY1GZ7hxRjuRHB4G5sTtg8O1OD076hVqFuCPZu9/Y8g2mY1VtRCU3fLyw7hi45EW9N7
 TH8rO95bdxPKc4ZFYgvSlxN1H/zUJaALtIPzNRY5p1aVJkFMnvBo2WEC9M+Dk/EmhUCO77e1Dtv
 Pm08FU81/mg3v9Ax1i+7Jml6gtooXzQh67tuAlSzC4cGc9X5Ved8Zx+Q3rgDckoEMJbYAJtUfTH
 VFqkdgnK8WsG2rXGpQEV8u07ehdfBzL+0gicCr48XZaL6I4OZ2XjVJxSrEKBRgz1rZp0LdRBin7
 DU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What?
=====

Stage table->data when writing INT & ULONG ctl_tables. Commit staged
data to kernel variable only when all the conversions have succeeded.
This is applicable only to variables that represent a vector; paths
pertaining to scalers are left unchanged. Notice that partial updates
can still happen if less than the size of the vector are passed and
correctly formatted.

This is the behavior we are protecting against:

  # echo "4 4 1 7" > /proc/sys/kernel/printk
  # echo "1 x" > /proc/sys/kernel/printk
  -bash: echo: write error: Invalid argument
  # cat /proc/sys/kernel/printk
  1 4 1 7    <- the write failed, the first element changed anyway

Why?
====
Allowing a partial change to a vector after returning from an erroneous
proc_handler is just plain wrong. This should be handled within sysctl
to avoid users having to do it for themselves [1]. 

Behavioral Changes
==================
1. A failed write will not update the vector
2. Vector writes can now fail with -ENOMEM

Testing
=======
This went through regular sysctl kunit and self test. Also is posted to
0-day.

I always find it difficult to know who wants to receive this. Please let
me know if you want to be removed from the Cc/To.

Best

[1] https://lore.kernel.org/all/tencent_A860C873956A52E26AD8D309A308A241BA08@qq.com/

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Changes in v2:
- Avoid doc compilation warnings related to apply_conv_on_vec function
- Initialize rc in testing to avoid a false positive when executing 0013
  individually
- Link to v1: https://lore.kernel.org/r/20260813-lklm-partial_ctlvec-v1-0-df9e51c13704@kernel.org

---
Joel Granados (4):
      sysctl: Split data conversion and file position handling
      sysctl: Reject uint arrays before calling the general proc_vec
      sysctl: Disallow partial updates for erroneous sysctl vectors
      sysctl: Add 0013 to test partially updated vectors

 kernel/sysctl.c                          | 237 ++++++++++++++++++++-----------
 tools/testing/selftests/sysctl/sysctl.sh |  60 ++++++++
 2 files changed, 217 insertions(+), 80 deletions(-)
---
base-commit: 4c12287001da60f3c022bb25932aa7a5590fc0b1
change-id: 20260813-lklm-partial_ctlvec-bd8867b70d5c

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

