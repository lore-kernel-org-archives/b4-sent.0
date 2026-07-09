From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 03:21:40 +0800
Subject: [PATCH v3 2/2] pvscsi: add a comment to explain the endianness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-pvscsi-endianness-v3-2-27fe1c4d1f6e@gmail.com>
References: <20260710-pvscsi-endianness-v3-0-27fe1c4d1f6e@gmail.com>
In-Reply-To: <20260710-pvscsi-endianness-v3-0-27fe1c4d1f6e@gmail.com>
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, Fam Zheng <fam@euphon.net>, 
 Dmitry Fleytman <dmitry.fleytman@gmail.com>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Peter Maydell <peter.maydell@linaro.org>, Michael Tokarev <mjt@tls.msk.ru>, 
 Arvind Kumar <arvindkumar@vmware.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1559;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=ilFQcJu1FqULtEwtbouLfW4e6TfQJNaWKZ3bD1ZIn78=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT/TFKjL0nmPHCRwaa0V1BJ3JVJNwT/k9Zxj5+
 zlhY0nfzXuJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/0xQAKCRCwMePKe/7Z
 bpXEEADRXXAQvPJlLCB69LrkHODV3wVmKAHt6lMCBwtFvfcvLvfdkjC+Q6NiAfAQLOf7seQ7vhj
 CTfIQEH4D9VHRPAH0n4MdLxSlioFBCVi41IJ49hFPsZecwIlCmDz+sX0hr7aKtuQ6Ftk0p8cmzt
 232eG58P3yBWtUlOzBU+FP4hiPIcW9oZJR2b/wdVvKhmeIfTIgWQZVBe8ihj3oWuj2rUYO1ybge
 oChplst5yikQhbKFWnaH/jRQxwDmgy/NwUzv2u5O8v/zoV3P/hP2NNu1+6oAsXSv6i/lMFD+vNn
 WaqEwiEzG769p1UyqjHg1MVRifs1egv2Xzobf65p0nIn7HO+cXspXeav8+6Q97LIHWZz8oWpz/5
 JTzJ3p6CeZlpSOL+9v4rXecUymJfQPu7dWBvp3Nz9E63tsYglfu01pkkZg1D7qBcIFFT5MGx6kk
 LHDoNaxgN6iIKc1ut+3TqQHlmksoiz8/3uUGuS9kZe3+pObXBg+AWH/kI8m3p25ik2AItz2bayT
 uUKQad9O06PI9d8wg3aLzsXFG8KnJpHU0Dv1tfZHdUG2eLWGILsJxJ8CFMlZu/GGsxE5gaQB7kw
 vwajCcNxmrNPsOqjoYMqR/USmIw5d2snRs6CzoWIqvWqdi1Y7ccRcii43jIrwcMh5w7sS8qhRY4
 EyS/Oo61gViPtlA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a comment to explain the endianness of the pvscsi device. We have
no information about the endianness should be little-endian or CPU
native endian because the current driver code is designed to work only
on x86 and is not endianness aware. We assume that the pvscsi device is
implicitly little-endian.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 hw/scsi/vmw_pvscsi.h | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/hw/scsi/vmw_pvscsi.h b/hw/scsi/vmw_pvscsi.h
index a3ae517e19934c2377cd84efe993264917ecefde..defff9e179ecbe888194e3f31547ecbee801f432 100644
--- a/hw/scsi/vmw_pvscsi.h
+++ b/hw/scsi/vmw_pvscsi.h
@@ -108,6 +108,20 @@ enum PVSCSICommands {
 #define PVSCSI_COMMAND_PROCESSING_FAILED     (-1)
 #define PVSCSI_COMMAND_NOT_ENOUGH_DATA       (-2)
 
+/*
+ * About endianess for the below structs:
+ *
+ * These structs are used to describe the data that is exchanged between the
+ * guest and the PVSCSI device. The endianess of the fields in these structs
+ * is not defined by any standard. The current implemented drivers are designed
+ * to only work on x86 architecture, so there is no endianess awareness in the
+ * drivers and thus we have no idea whether the fields should be in little-
+ * endian or target native endian format.
+ *
+ * Considering the above, we assume that PVSCSI is implicitly little-endian and
+ * expect the fields in these structs to be in little-endian format.
+ */
+
 /*
  * Command descriptor for PVSCSI_CMD_RESET_DEVICE --
  */

-- 
2.49.0

