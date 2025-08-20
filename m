From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 20 Aug 2025 17:22:42 +0800
Subject: [PATCH] libbpf: add documentation to version and error API
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250820-libbpf-doc-1-v1-1-13841f25a134@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAOGTpWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyMD3ZzMpKSCNN2U/GRdQ10DkyQDU9M0gzRLc3MloJaCotS0zAqwcdG
 xtbUAPRJMcF4AAAA=
X-Change-ID: 20250820-libbpf-doc-1-04b055f0f977
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 niecheng1@uniontech.com, guanwentao@uniontech.com, zhanjun@uniontech.com, 
 yt.xyxx@gmail.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755681763; l=1980;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=HqKLuwaahaE8X4oGAqmIDONf3wOJcCZcDPM6er4Q6CA=;
 b=0bW0OAnjBtipT/YwZfM4duneD+8q120OUp8cSpQzdLcmOJMiwfT5AOVOgCxEigeXOxBG86m7X
 Hyt2KCsq0ULCukJESeDbbYtyGLx7v6rbAgfb40kpGMkJwg4fhDAHLj/
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds documentation for the following API functions:
- libbpf_major_version()
- libbpf_minor_version()
- libbpf_version_string()
- libbpf_strerror()

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 tools/lib/bpf/libbpf.h | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/tools/lib/bpf/libbpf.h b/tools/lib/bpf/libbpf.h
index 455a957cb702cab53266ea948fec061f3b65c9ee..3b809cd08f01ce1576ac822fb89cfd589b9f0d44 100644
--- a/tools/lib/bpf/libbpf.h
+++ b/tools/lib/bpf/libbpf.h
@@ -24,8 +24,25 @@
 extern "C" {
 #endif
 
+/**
+ * @brief **libbpf_major_version()** provides the major version of libbpf.
+ * @return An integer, the major version number
+ */
 LIBBPF_API __u32 libbpf_major_version(void);
+
+/**
+ * @brief **libbpf_minor_version()** provides the minor version of libbpf.
+ * @return An integer, the minor version number
+ */
 LIBBPF_API __u32 libbpf_minor_version(void);
+
+/**
+ * @brief **libbpf_version_string()** provides the version of libbpf in a
+ * human-readable form, e.g., "v1.7".
+ * @return Pointer to a static string containing the version
+ *
+ * The format is *not* a part of a stable API and may change in the future.
+ */
 LIBBPF_API const char *libbpf_version_string(void);
 
 enum libbpf_errno {
@@ -49,6 +66,14 @@ enum libbpf_errno {
 	__LIBBPF_ERRNO__END,
 };
 
+/**
+ * @brief **libbpf_strerror()** converts the provided error code into a
+ * human-readable string.
+ * @param err The error code to convert
+ * @param buf Pointer to a buffer where the error message will be stored
+ * @param size The number of bytes in the buffer
+ * @return 0, on success; negative error code, otherwise
+ */
 LIBBPF_API int libbpf_strerror(int err, char *buf, size_t size);
 
 /**

---
base-commit: b19a97d57c15643494ac8bfaaa35e3ee472d41da
change-id: 20250820-libbpf-doc-1-04b055f0f977

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

