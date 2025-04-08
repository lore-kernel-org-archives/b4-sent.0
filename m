From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 08 Apr 2025 22:14:46 +0200
Subject: [PATCH 1/3] scripts: nixify archive-source.sh
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-jag-sysctl-v1-1-3f4f38b751be@kernel.org>
References: <20250408-jag-sysctl-v1-0-3f4f38b751be@kernel.org>
In-Reply-To: <20250408-jag-sysctl-v1-0-3f4f38b751be@kernel.org>
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: qemu-devel@nongnu.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=650;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=jDZDxLJWDYW927mYZ8/+pBOhs25t9wQSY97XH11aeAA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGf1g7rJbMQQkzbdZqLcZJzh0WcwjGuMQApmR
 33bK9Y0z2YQv4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9YO6AAoJELqXzVK3
 lkFPlu8L/i9v4XmyqdS1lNI3HCDOjistZIit3XDMeA+Ovd83zSGGEk+kUjK4JitVQbg0Nk/3f+t
 y3zydEuvQ5+9PAOmLbBklYA5tyJUNZzdJYTXLXtE3e9iJz00yo/mQPHp11YzwMWX40Mw7N4ZVvx
 dzzQtmq0CY0eNDT3y67Jvo0wgX+Wpw23u6lUnqnIzo5+WkLmgn8dpr00G1FVq/7dpdfgjuwzCmJ
 xQaTeS/eu9q0wcpWRLPrikkWZXFrPFtZrB/L1aJV9Al87qFhO/jfst42PHjtzsczfr7QUX7G9G1
 JWD29hg2F3rlfTwfThN3kp1kyUFiqRt2bTK8I3H8hkeiUyRAHdZxkGruVJ376QgvL5flgf2iEdz
 R2j1+Pe5EwMogmkIsSlmKo1k7Mj6BEdSQxXWUlWJch27XagCbX5Vpg5teS7GRpL4RbxIh/c4r4n
 1y2oybLqA4HSp8on0r4Pi9SnQsQ9ycId9RgQSF/6YQJwtUG4HnFWIFtygbQkULJZe1cn9uZsuq6
 sI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use "#!/usr/bin/env bash" instead of "#!/bin/bash". This is necessary
for nix environments as they only provide /usr/bin/env at the standard
location.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/archive-source.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/archive-source.sh b/scripts/archive-source.sh
index 30677c3ec9032ea01090f74602d839d1c571d012..a469a5e2dec4b05e51474f0a1af190c1ccf23c7e 100755
--- a/scripts/archive-source.sh
+++ b/scripts/archive-source.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 #
 # Author: Fam Zheng <famz@redhat.com>
 #

-- 
2.44.1

