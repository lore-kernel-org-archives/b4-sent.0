From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 08 Apr 2025 10:02:41 +0200
Subject: [PATCH 1/3] scripts: nixify archive-source.sh
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-jag-sysctl-v1-1-f5c4aba3e7ff@kernel.org>
References: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
In-Reply-To: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=650;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=jDZDxLJWDYW927mYZ8/+pBOhs25t9wQSY97XH11aeAA=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGf02Faj1DKAYHDqx/kKZPsjQ3i9Phux8mt71OUrDxjr6Z1nJ
 okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9NhWAAoJELqXzVK3lkFPcDAL/0Iy
 pIVPxBOEOQ+jZl+UQOKsbCfNNf92FNe9pydYTZljCOaGBnzaBX+Pjxk3kJsJx+RXhijuWWToYR7
 Q25yUE7FMdACKNBuNmtQNBWppdvFh1ewuyxomDlbcbRbDjqKhG+P5VJSIaM937uVAVdMcgadOKS
 MaVsU32GDZ2Z551KGbvS+tMev5kXbdBoen+k9sUL+gUSp7Lc53h5WKhuVDE/F5/fZF4Y/0bm4u2
 p+xnzmnEHvkCUoNP9LkBBGlM9XK/OvsIKP4T0afONcv4JLzKh9KAYW6rL+GvPdOzYtCOHoZ6dJs
 YlYamsGERjPBKvyk4kPnLPuOTTcvjGynhYsl6BD6g8CHPnyRjEH9wm4c4oMWMrNU6si9sbWB/VJ
 iXpj/jyFlL7bUgzwecZgd5sr+4vj8GYHV0jR7aSZcPFhKy1zEK5DKNUzlXqMNFEXxu+rpNdJNXj
 pW1P/Mquomke/NGmvQaf3UA/cd9OgUEtRcKjDUe/bvgyBOnFG3brXwpnATzA==
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

