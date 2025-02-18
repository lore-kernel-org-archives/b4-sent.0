From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 18 Feb 2025 10:31:26 +0000
Subject: [PATCH 2/2] iio: core: make use of simple_write_to_buffer()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250218-dev-iio-misc-v1-2-bf72b20a1eb8@analog.com>
References: <20250218-dev-iio-misc-v1-0-bf72b20a1eb8@analog.com>
In-Reply-To: <20250218-dev-iio-misc-v1-0-bf72b20a1eb8@analog.com>
To: linux-iio@vger.kernel.org
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739874693; l=1029;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=XSfph9ScrctizABSM0SAUyR4HL7Q5VFFkc9KAHORCIQ=;
 b=WtkAqNh6pJ1VanNffMmjSRxLtfRCNB6dJavd+KtTeyGbWdvRL/293piuSiEt2QhMSNVf0feX+
 xLKB+MDVle5DOXivrz7fua/Cecjr/zvArX7ZAWzt6oWtFB4SToztRh3
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of open coding (kind of) simple_write_to_buffer(), use it.

While at it, use ascii representation to terminate the string as that is
the more common way of doing it.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/industrialio-core.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index a2117ad1337d55468c0f21c274fcbedd352c97ff..b9f4113ae5fc3ee1ef76be6808cc437286690dae 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -410,11 +410,12 @@ static ssize_t iio_debugfs_write_reg(struct file *file,
 	char buf[80];
 	int ret;
 
-	count = min(count, sizeof(buf) - 1);
-	if (copy_from_user(buf, userbuf, count))
-		return -EFAULT;
+	ret = simple_write_to_buffer(buf, sizeof(buf) - 1, ppos, userbuf,
+				     count);
+	if (ret < 0)
+		return ret;
 
-	buf[count] = 0;
+	buf[count] = '\0';
 
 	ret = sscanf(buf, "%i %i", &reg, &val);
 

-- 
2.48.1

