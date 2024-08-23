From: Miao Wang <shankerwangmiao@gmail.com>
Date: Sat, 24 Aug 2024 03:07:23 +0800
Subject: [PATCH] sys_statx: support for statx(fd, NULL, AT_EMPTY_PATH)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240824-statx-null-path-v1-1-8432bfb60a57@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOrdyGYC/x3MQQqAIBBA0avErBswi4iuEi1MpxoQE7UQwrsnL
 d/i/xciBaYIc/NCoIcjX66iaxvQp3IHIZtqkEIOYpIDxqRSRndbi16lEyciPZIwqt801MoH2jn
 /x2Ut5QOt98ANYQAAAA==
To: Julian Seward <jseward@acm.org>
Cc: valgrind-developers@lists.sourceforge.net, b4-sent@lore.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1551;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=J7RWbkj9h58k1btacYhFraRzpMs8KU2Xju5/16FagGo=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmyN3s7ssXoKLynwC8GljIU1Uu0T+TpWfVb4Ic4
 yCT0oby22qJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsjd7AAKCRCwMePKe/7Z
 br94EACFSYXMWOrY5m+6uPgkkxh9qd2C7dTN3Vge5/tqZP5CyfFt+dmxWluAy8BO/0r6EfiKkgu
 KYLjInfqLL+CBQr+21mmyJ2l9WijjOer6x8Ylvxn/o4tR5CvKWpFLkJVaXC0/GyZZABpSTScoVu
 70DaxdhevkCRVqZPSZ9NPTAH1V/Szxvub9u4zBMKR/7o+ETvsVPp5JzBttuXJcHFGFwLKVfUffn
 znVR+U2b+w6+r1zRhFAsOb5mZluJwysuBc2w+XXFelRBnSImqWQS6SFCvYbmWfhYPtI9ID9um/a
 byH5MqcaVJldA7JC4MRtqxXOpFUgFwNV/i7suJ5XnMw7Bc/dKXZqa09vhLFW/SA4j3LlEW38NCd
 FVgUmgkaF9KsDnl7QLwOS+sJj2xem6aXjL2JtA903O4HfxexOV6lsINdOEQkqVrhDjIFKzRAedc
 7Z9P6zfmLkq7vJRWgphRi6YsLrcp5Z15Qh+j3O4zfO3/poTav7K48HdM4cyEzedcBXf18mHVNjf
 d/4YljjWsIeOZku/eVAjlY3LAzLLls43i2wrhPjXBaoxV3Rkjx3lHPKvTgaYraFNo2Vmx6pC8Jx
 GlE/1QvPhnOid0+pgd4r6RuieWLMmoC1tooz0gr3tgT1xuFt8QrbzUFXXERlZSUlmDRxJwipdzT
 jPlfwwsmuO6AQbQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

statx(fd, NULL, AT_EMPTY_PATH) is supported since Linux 6.11 and this
patch addes the support to valgrind, so that it won't complain when
NULL is used as |filename| and |flags| includes AT_EMPTY_PATH.

Ref: commit 0ef625bba6fb ("vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)")

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 coregrind/m_syswrap/syswrap-linux.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/coregrind/m_syswrap/syswrap-linux.c b/coregrind/m_syswrap/syswrap-linux.c
index 9f3c51c17..453385599 100644
--- a/coregrind/m_syswrap/syswrap-linux.c
+++ b/coregrind/m_syswrap/syswrap-linux.c
@@ -4209,8 +4209,12 @@ PRE(sys_statx)
    // in which it passes NULL for both filename and buf, and then looks at the
    // return value, so as to determine whether or not this syscall is supported.
    Bool both_filename_and_buf_are_null = ARG2 == 0 && ARG5 == 0;
+   Bool statx_null_path = (ARG2 == 0) && (ARG3 & VKI_AT_EMPTY_PATH);
    if (!both_filename_and_buf_are_null) {
-      PRE_MEM_RASCIIZ( "statx(filename)", ARG2 );
+      // Since Linux 6.11, the kernel allows passing a NULL filename when
+      // the AT_EMPTY_PATH flag is set.
+      if (!statx_null_path)
+         PRE_MEM_RASCIIZ( "statx(filename)", ARG2 );
       PRE_MEM_WRITE( "statx(buf)", ARG5, sizeof(struct vki_statx) );
    }
 }

---
base-commit: 61e44a4aef8775b925a7a91f403ebd7f4f6670a4
change-id: 20240824-statx-null-path-8eec6e0da3bc

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

