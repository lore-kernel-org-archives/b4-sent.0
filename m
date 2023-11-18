From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 17 Nov 2023 23:14:26 -0600
Subject: [PATCH v4 08/13] powerpc/uapi: Export papr-miscdev.h header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-8-b794d8cb8502@linux.ibm.com>
References: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
In-Reply-To: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=765;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=JMz2KShlBYHoqW3y8kJSBWwgwMz0qhqY8agvfGwn8cc=;
 b=z+xDUVUyBXQgFOMT80eBm1k1GRS3OgTN1abaGTVYhbqnkQ1HTqzSKGApGf4ZhMjLARgdOe8ps
 ybvtQaW8QdyDj9oZb/ZZzLKgx7/8cLG1ptux9N43ymeJPpAQnJSakJa
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocate one identifying code (the first column of the ioctl-number
table) for the collection of PAPR miscdev drivers to share.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/uapi/asm/papr-miscdev.h | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/powerpc/include/uapi/asm/papr-miscdev.h b/arch/powerpc/include/uapi/asm/papr-miscdev.h
new file mode 100644
index 000000000000..49a2a270b7f3
--- /dev/null
+++ b/arch/powerpc/include/uapi/asm/papr-miscdev.h
@@ -0,0 +1,9 @@
+/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
+#ifndef _UAPI_PAPR_MISCDEV_H_
+#define _UAPI_PAPR_MISCDEV_H_
+
+enum {
+	PAPR_MISCDEV_IOC_ID = 0xb2,
+};
+
+#endif /* _UAPI_PAPR_MISCDEV_H_ */

-- 
2.41.0

