From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 05:32:19 +0000
Subject: [PATCH] lib: rsa: build the engine code only when OpenSSL supports
 engines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rsa-no-engine-v1-1-8dfdd9e5dd7f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz1jCqEDEVRBDElwwg0FxW1VC3
 J3Qjm/4/wDjJGzQFwck/ojJphlUFhAXrzOjTNlQV3VLRBUm86gbss6ijOS6GDrXuPDwkJs98VO
 +v98w/m3vsHJ83RM4zwvsZVZtcQAAAA==
X-Change-ID: 20261110-rsa-no-engine-187cb7858b4a
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Eddie Kovsky <ekovsky@redhat.com>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794288740; l=5048;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8vIq9x7mmtXhjFfbVpDBv1WfSQuuLSYG8L2+i8KEkuw=;
 b=/gDYIXub6b4WgMLZAPQJLooerMvtALoC0PomC2D6WZnUagC7HOZNSaEr6Xq9+9j7U/ugJjBVt
 jC9rhwrFUipB0G5FuObos4B2DlGm89zDaXbwPOmtCwcxNiIIy/pKPb1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OpenSSL 4.0 removed the ENGINE API: <openssl/engine.h> only has
deprecated declarations left and the functions are gone from libcrypto,
so building the host tools with it fails:

  rsa-sign.c: undefined reference to `ENGINE_load_builtin_engines'
  rsa-sign.c: undefined reference to `ENGINE_by_id'
  ...

OpenSSL 3.x can also be built without engines (OPENSSL_NO_ENGINE), or
hide them behind OPENSSL_NO_DEPRECATED_3_0.

Compile the bodies of the engine helpers only when OpenSSL is older than
4.0 and has engine support. Otherwise rsa_engine_init() reports that the
engine is not available and returns -ENOTSUP, so "mkimage -N <engine>"
fails instead of quietly signing with a key file of the same name. Keys
from files work as before; with an OpenSSL that has engines nothing
changes.

This is the "unbreak the build on OpenSSL 4" part that Quentin Schulz
asked to be split out of Eddie Kovsky's "Add support for OpenSSL
Provider API" series (v5) in his review on 2026-11-05, following the
design he spelled out there (the condition, the OSSL_ENGINE_SUPPORTED
name and failing with -ENOTSUP inside the engine helpers). Eddie did the
groundwork for this; I'm happy to drop this patch in favour of his v6.

This only fixes the build. The binman engine tests
(tools/binman/test/fit/dummy-rsa-engine.c) still need an OpenSSL with
engine support, and OpenSSL provider support is a separate topic.

Tested by building tools-only_defconfig against OpenSSL 4.0.3 (link
failure before, clean after, no ENGINE_* symbols left in mkimage) and
against OpenSSL 3.5.9 with engine support (unchanged, ENGINE code still
built); with both, mkimage signs a FIT with a key file, and
"mkimage -N <engine>" fails with an error.

Suggested-by: Quentin Schulz <quentin.schulz@cherry.de>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Eddie, Quentin: this is only the OpenSSL 4 build fix from Quentin's
review of v5, kept to what he described, so the tools build on OpenSSL 4
while the provider work continues. Eddie, if you would rather carry it
in your v6, please say so and I'll drop this one.

I developed this patch with Claude (Anthropic) as a coding assistant: it
read the review thread, wrote the code and the commit message, and ran
the builds. I reviewed the result and the testing is as described in the
commit message.
---
 lib/rsa/rsa-sign.c | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/lib/rsa/rsa-sign.c b/lib/rsa/rsa-sign.c
index 0e38c9e802f..aedf68cf966 100644
--- a/lib/rsa/rsa-sign.c
+++ b/lib/rsa/rsa-sign.c
@@ -19,7 +19,17 @@
 #include <openssl/err.h>
 #include <openssl/ssl.h>
 #include <openssl/evp.h>
+
+/*
+ * OpenSSL 4.0 removed the ENGINE API, and OpenSSL 3.x can be built without it
+ * (OPENSSL_NO_ENGINE). Keys can then only be read from files; asking for an
+ * engine (mkimage -N) fails instead of silently using a key file.
+ */
+#if OPENSSL_VERSION_NUMBER < 0x40000000L && !defined(OPENSSL_NO_ENGINE) && \
+	!defined(OPENSSL_NO_DEPRECATED_3_0)
+#define OSSL_ENGINE_SUPPORTED
 #include <openssl/engine.h>
+#endif
 
 static int rsa_err(const char *msg)
 {
@@ -101,6 +111,7 @@ err_cert:
 static int rsa_engine_get_pub_key(const char *keydir, const char *name,
 				  ENGINE *engine, EVP_PKEY **evpp)
 {
+#ifdef OSSL_ENGINE_SUPPORTED
 	const char *engine_id;
 	char key_id[1024];
 	EVP_PKEY *key = NULL;
@@ -156,6 +167,11 @@ static int rsa_engine_get_pub_key(const char *keydir, const char *name,
 	*evpp = key;
 
 	return 0;
+#else
+	fprintf(stderr, "Built without OpenSSL engine support\n");
+
+	return -ENOTSUP;
+#endif
 }
 
 /**
@@ -230,6 +246,7 @@ static int rsa_engine_get_priv_key(const char *keydir, const char *name,
 				   const char *keyfile,
 				   ENGINE *engine, EVP_PKEY **evpp)
 {
+#ifdef OSSL_ENGINE_SUPPORTED
 	const char *engine_id;
 	char key_id[1024];
 	EVP_PKEY *key = NULL;
@@ -292,6 +309,11 @@ static int rsa_engine_get_priv_key(const char *keydir, const char *name,
 	*evpp = key;
 
 	return 0;
+#else
+	fprintf(stderr, "Built without OpenSSL engine support\n");
+
+	return -ENOTSUP;
+#endif
 }
 
 /**
@@ -327,6 +349,7 @@ static int rsa_init(void)
 
 static int rsa_engine_init(const char *engine_id, ENGINE **pe)
 {
+#ifdef OSSL_ENGINE_SUPPORTED
 	const char *key_pass;
 	ENGINE *e;
 	int ret;
@@ -371,14 +394,22 @@ err_set_rsa:
 err_engine_init:
 	ENGINE_free(e);
 	return ret;
+#else
+	fprintf(stderr, "Engine '%s' isn't available: built without OpenSSL engine support\n",
+		engine_id);
+
+	return -ENOTSUP;
+#endif
 }
 
 static void rsa_engine_remove(ENGINE *e)
 {
+#ifdef OSSL_ENGINE_SUPPORTED
 	if (e) {
 		ENGINE_finish(e);
 		ENGINE_free(e);
 	}
+#endif
 }
 
 static int rsa_sign_with_key(EVP_PKEY *pkey, struct padding_algo *padding_algo,

---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261110-rsa-no-engine-187cb7858b4a

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

