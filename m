From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 01 Jun 2026 09:13:06 +0200
Subject: [PATCH 5/6] documentation.conf: remove do_package_write_tar doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-topic-packagemanager-cleanup-v1-5-926e4d5b724d@linaro.org>
References: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
In-Reply-To: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=1340;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=gJXJdXbIOcV8pEHaKXHwJEGJs0JU5ItGpBpISFuQBkg=;
 b=aT7oyIlEx26Y/SuP99/5B5SoY4R/GZaX3Ag0fvnH7AwWKVliKwmCWRMbaHGBQuqfCr/MRZ+/K
 5YCiXGVj+zUC+s8sEgPsaP5UkcBWKIIUtGOj1FtfNLlI8XiDfCdFIyn
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The package_tar.bbclass was removed in 90ce19122802
("meta/classes-global: remove package_tar.bbclass"), remove the
documentation variable associated with it as well.

No functional changes.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 meta/conf/documentation.conf | 1 -
 1 file changed, 1 deletion(-)

diff --git a/meta/conf/documentation.conf b/meta/conf/documentation.conf
index 94368d5c2b..953b2140d1 100644
--- a/meta/conf/documentation.conf
+++ b/meta/conf/documentation.conf
@@ -35,7 +35,6 @@ do_package_qa[doc] = "Runs QA checks on packaged files"
 do_package_write_deb[doc] = "Creates the actual DEB packages and places them in the Package Feed area"
 do_package_write_ipk[doc] = "Creates the actual IPK packages and places them in the Package Feed area"
 do_package_write_rpm[doc] = "Creates the actual RPM packages and places them in the Package Feed area"
-do_package_write_tar[doc] = "Creates tar archives for packages and places them in the Package Feed area"
 do_packagedata[doc] = "Creates package metadata used by the build system to generate the final packages"
 do_patch[doc] = "Locates patch files and applies them to the source code"
 do_populate_lic[doc] = "Writes license information for the recipe that is collected later when the image is constructed"

-- 
2.52.0

