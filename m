From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 12 Dec 2023 11:01:57 -0600
Subject: [PATCH v6 10/13] powerpc/pseries/papr-sysparm: Validate buffer
 object lengths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231212-papr-sys_rtas-vs-lockdown-v6-10-e9eafd0c8c6c@linux.ibm.com>
References: <20231212-papr-sys_rtas-vs-lockdown-v6-0-e9eafd0c8c6c@linux.ibm.com>
In-Reply-To: <20231212-papr-sys_rtas-vs-lockdown-v6-0-e9eafd0c8c6c@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702400518; l=3564;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=6bbrgd0ovnUjw1itj15WIksclWVAl56tP1qwG+1R09U=;
 b=yIf+rQapI2e+KByTvQvy9pG4088hNhSm6ShnMNgv9Sr/DkSaJHZcCP4ttAjlKIG+Aau6N0iwD
 HXiZjsDr5WWCJaSSYsQAuIFcHPAyhunzIoVzb+ZX4Q7VG7g87q0mbP1
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ability to get and set system parameters will be exposed to user
space, so let's get a little more strict about malformed
papr_sysparm_buf objects.

* Create accessors for the length field of struct papr_sysparm_buf.
  The length is always stored in MSB order and this is better than
  spreading the necessary conversions all over.

* Reject attempts to submit invalid buffers to RTAS.

* Warn if RTAS returns a buffer with an invalid length, clamping the
  returned length to a safe value that won't overrun the buffer.

These are meant as precautionary measures to mitigate both firmware
and kernel bugs in this area, should they arise, but I am not aware of
any.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/papr-sysparm.c | 47 +++++++++++++++++++++++++++
 1 file changed, 47 insertions(+)

diff --git a/arch/powerpc/platforms/pseries/papr-sysparm.c b/arch/powerpc/platforms/pseries/papr-sysparm.c
index fedc61599e6c..a1e7aeac7416 100644
--- a/arch/powerpc/platforms/pseries/papr-sysparm.c
+++ b/arch/powerpc/platforms/pseries/papr-sysparm.c
@@ -23,6 +23,46 @@ void papr_sysparm_buf_free(struct papr_sysparm_buf *buf)
 	kfree(buf);
 }
 
+static size_t papr_sysparm_buf_get_length(const struct papr_sysparm_buf *buf)
+{
+	return be16_to_cpu(buf->len);
+}
+
+static void papr_sysparm_buf_set_length(struct papr_sysparm_buf *buf, size_t length)
+{
+	WARN_ONCE(length > sizeof(buf->val),
+		  "bogus length %zu, clamping to safe value", length);
+	length = min(sizeof(buf->val), length);
+	buf->len = cpu_to_be16(length);
+}
+
+/*
+ * For use on buffers returned from ibm,get-system-parameter before
+ * returning them to callers. Ensures the encoded length of valid data
+ * cannot overrun buf->val[].
+ */
+static void papr_sysparm_buf_clamp_length(struct papr_sysparm_buf *buf)
+{
+	papr_sysparm_buf_set_length(buf, papr_sysparm_buf_get_length(buf));
+}
+
+/*
+ * Perform some basic diligence on the system parameter buffer before
+ * submitting it to RTAS.
+ */
+static bool papr_sysparm_buf_can_submit(const struct papr_sysparm_buf *buf)
+{
+	/*
+	 * Firmware ought to reject buffer lengths that exceed the
+	 * maximum specified in PAPR, but there's no reason for the
+	 * kernel to allow them either.
+	 */
+	if (papr_sysparm_buf_get_length(buf) > sizeof(buf->val))
+		return false;
+
+	return true;
+}
+
 /**
  * papr_sysparm_get() - Retrieve the value of a PAPR system parameter.
  * @param: PAPR system parameter token as described in
@@ -63,6 +103,9 @@ int papr_sysparm_get(papr_sysparm_t param, struct papr_sysparm_buf *buf)
 	if (token == RTAS_UNKNOWN_SERVICE)
 		return -ENOENT;
 
+	if (!papr_sysparm_buf_can_submit(buf))
+		return -EINVAL;
+
 	work_area = rtas_work_area_alloc(sizeof(*buf));
 
 	memcpy(rtas_work_area_raw_buf(work_area), buf, sizeof(*buf));
@@ -77,6 +120,7 @@ int papr_sysparm_get(papr_sysparm_t param, struct papr_sysparm_buf *buf)
 	case 0:
 		ret = 0;
 		memcpy(buf, rtas_work_area_raw_buf(work_area), sizeof(*buf));
+		papr_sysparm_buf_clamp_length(buf);
 		break;
 	case -3: /* parameter not implemented */
 		ret = -EOPNOTSUPP;
@@ -115,6 +159,9 @@ int papr_sysparm_set(papr_sysparm_t param, const struct papr_sysparm_buf *buf)
 	if (token == RTAS_UNKNOWN_SERVICE)
 		return -ENOENT;
 
+	if (!papr_sysparm_buf_can_submit(buf))
+		return -EINVAL;
+
 	work_area = rtas_work_area_alloc(sizeof(*buf));
 
 	memcpy(rtas_work_area_raw_buf(work_area), buf, sizeof(*buf));

-- 
2.41.0

