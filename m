From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 03:20:19 +0000
Subject: [PATCH 6.1.y] iio: frequency: admv1013: fix NULL pointer
 dereference on str
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261128-admv1013-61b-v1-1-c9c20290b9be@certik.com>
X-B4-Tracking: v=1; b=H4sIAHJICmsC/02NSQ7CMBAEvxLNGQePiczyFcTBy5gYgR15QgSK8
 ndiuHDsUnf1DEwlEsOpmaHQFDnmtAbcNOB6k64kol8zKKk0ojoI4x8TStwJjVaoEI4obeg6vYd
 1MhQK8fXVnUG32L7h8sP8tDdyY1XVojVMwhaTXF8RU/JjzndR+fb/ApblA6Mm9zqkAAAA
X-Change-ID: 20261128-admv1013-61b-2ff910bf4467
In-Reply-To: <2026050125-bullfrog-earring-0c74@gregkh>
References: <2026050125-bullfrog-earring-0c74@gregkh>
To: stable@vger.kernel.org
Cc: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, linux-iio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795836018; l=3298;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=acstfVNnYL2yFV1bAV5V3kbzxfSp/mALpENhHosfVzE=;
 b=/75Jkk946WcbJgqEtH/uIbE1Ldg/SYaSC2V5alserJC0uMI7+rNaWiG+45XE3FRmC8MKUukEc
 4jjb8FZk/HjAnFgmejOirpt4FBDI/HF3SjceV0N88VLHlX+87eAAUTS
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Antoniu Miclaus <antoniu.miclaus@analog.com>

commit aac0a51b16700b403a55b67ba495de021db78763 upstream.

When device_property_read_string() fails, str is left uninitialized
but the code falls through to strcmp(str, ...), dereferencing a garbage
pointer. Replace manual read/strcmp with
device_property_match_property_string() and consolidate the SE mode
enums into a single sequential enum, mapping to hardware register
values via a switch consistent with other bitfields in the driver.

Several cleanup patches have been applied to this driver recently so
this will need a manual backport.

Fixes: da35a7b526d9 ("iio: frequency: admv1013: add support for ADMV1013")
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Antoniu Miclaus <antoniu.miclaus@analog.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Cc: Stable@vger.kernel.org
Signed-off-by: Jonathan Cameron <Jonathan.Cameron@huawei.com>
[ adapted to 6.1.y: keep strcmp() parsing, fall back on unknown values ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This failed to apply to 6.1.y, which still has the older property
parsing and the original register encodings. Rather than pulling in the
enum rework and device_property_match_property_string(), this keeps the
read_string()/strcmp() code and only looks at str when the read
succeeded. As upstream, an unknown value now falls back to the default
mode (IQ, and differential for adi,quad-se-mode) instead of failing the
probe.

Tested on 6.1.193: W=1 build of admv1013.o, base vs patched, no new
warnings, and the patched kernel boots under QEMU. I don't have the
hardware, so the probe path was checked in the source.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/iio/frequency/admv1013.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/frequency/admv1013.c b/drivers/iio/frequency/admv1013.c
index 5238dfdb1de5..a274576bc8f3 100644
--- a/drivers/iio/frequency/admv1013.c
+++ b/drivers/iio/frequency/admv1013.c
@@ -536,26 +536,24 @@ static int admv1013_properties_parse(struct admv1013_state *st)
 	ret = device_property_read_string(&spi->dev, "adi,input-mode", &str);
 	if (ret)
 		st->input_mode = ADMV1013_IQ_MODE;
-
-	if (!strcmp(str, "iq"))
+	else if (!strcmp(str, "iq"))
 		st->input_mode = ADMV1013_IQ_MODE;
 	else if (!strcmp(str, "if"))
 		st->input_mode = ADMV1013_IF_MODE;
 	else
-		return -EINVAL;
+		st->input_mode = ADMV1013_IQ_MODE;
 
 	ret = device_property_read_string(&spi->dev, "adi,quad-se-mode", &str);
 	if (ret)
 		st->quad_se_mode = ADMV1013_SE_MODE_DIFF;
-
-	if (!strcmp(str, "diff"))
+	else if (!strcmp(str, "diff"))
 		st->quad_se_mode = ADMV1013_SE_MODE_DIFF;
 	else if (!strcmp(str, "se-pos"))
 		st->quad_se_mode = ADMV1013_SE_MODE_POS;
 	else if (!strcmp(str, "se-neg"))
 		st->quad_se_mode = ADMV1013_SE_MODE_NEG;
 	else
-		return -EINVAL;
+		st->quad_se_mode = ADMV1013_SE_MODE_DIFF;
 
 	st->reg = devm_regulator_get(&spi->dev, "vcm");
 	if (IS_ERR(st->reg))

---
base-commit: 1ca1436ccc68275d0b43b6a730b3940fcc46b7c2
change-id: 20261128-admv1013-61b-2ff910bf4467

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

