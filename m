From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 01 Jun 2026 09:13:07 +0200
Subject: [PATCH 6/6] nopackages: remove do_package_write_tar deltask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-topic-packagemanager-cleanup-v1-6-926e4d5b724d@linaro.org>
References: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
In-Reply-To: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=789;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=DOK9GWkLP0QWTJCQRcbnEmJ/60AChxh34Rz0QgASB+M=;
 b=PXevJkGuSb8g+A5nZwPN13srTem2uyOFFWIUwWxMOHTo+lTlC8q/zktV2ifw6GOsQ2nqB9OxE
 1d6KhuJK5y2CdzjjSsevJNTpkK4vhwFmG7sXseXRcLg83OqgBIpW9oL
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The package_tar class was removed in 90ce19122802
("meta/classes-global: remove package_tar.bbclass"), remove the deltask
for the nopackages class as well.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 meta/classes-recipe/nopackages.bbclass | 1 -
 1 file changed, 1 deletion(-)

diff --git a/meta/classes-recipe/nopackages.bbclass b/meta/classes-recipe/nopackages.bbclass
index 9ea7273530..8c433a285f 100644
--- a/meta/classes-recipe/nopackages.bbclass
+++ b/meta/classes-recipe/nopackages.bbclass
@@ -8,7 +8,6 @@ deltask do_package
 deltask do_package_write_rpm
 deltask do_package_write_ipk
 deltask do_package_write_deb
-deltask do_package_write_tar
 deltask do_package_qa
 deltask do_packagedata
 deltask do_package_setscene

-- 
2.52.0

