From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 18 Feb 2025 10:31:25 +0000
Subject: [PATCH 1/2] iio: backend: make sure to NULL terminate stack buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250218-dev-iio-misc-v1-1-bf72b20a1eb8@analog.com>
References: <20250218-dev-iio-misc-v1-0-bf72b20a1eb8@analog.com>
In-Reply-To: <20250218-dev-iio-misc-v1-0-bf72b20a1eb8@analog.com>
To: linux-iio@vger.kernel.org
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739874693; l=1076;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=GWhpZSmFhwwDXoVILtCDzIY2OPcm7moo7iOg8HbVPw0=;
 b=gcjTgcpdLyggP+hspMVta0xX5lJ736ImFTbFr5TUJ2hiq1L+ckq8hBR1y0ahnS10KyT2zLXRH
 GyXXqKY0fGeAhhxVud3BA/2tXOB4nrHy70VoC5gm5XsiD7REgdJrNli
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure to NULL terminate the buffer in
iio_backend_debugfs_write_reg() before passing it to sscanf(). It is a
stack variable so we should not assume it will 0 initialized.

Fixes: cdf01e0809a4 ("iio: backend: add debugFs interface")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/industrialio-backend.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index d4ad36f54090204bf3bef08457d4aa55aa7c11fc..a43c8d1bb3d0f4dda4277cac94b0ea9232c071e4 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -155,10 +155,12 @@ static ssize_t iio_backend_debugfs_write_reg(struct file *file,
 	ssize_t rc;
 	int ret;
 
-	rc = simple_write_to_buffer(buf, sizeof(buf), ppos, userbuf, count);
+	rc = simple_write_to_buffer(buf, sizeof(buf) - 1, ppos, userbuf, count);
 	if (rc < 0)
 		return rc;
 
+	buf[count] = '\0';
+
 	ret = sscanf(buf, "%i %i", &back->cached_reg_addr, &val);
 
 	switch (ret) {

-- 
2.48.1

