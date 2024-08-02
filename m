From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 02 Aug 2024 16:27:01 +0200
Subject: [PATCH v2 3/8] iio: backend: add a modified prbs23 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-3-4cb62852f0d0@analog.com>
References: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
In-Reply-To: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=666;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=gmG6owXx7+vNZNRlhh8piqNGl0cPxLcyjp7ksNBda48=;
 b=dSYQG/EOsIvahMNnhWGicaCBOOKBYi/OPeFdnkclAAc6wHGRKDWS8bH2zsTOkHFc+WK7f5fVF
 xwGDz49zfk4DlXTlFalEl8CKl4DviIW9GnR9iq/HT8Ce9Bzk3LbAK2h
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support ADI specific prb23 sequence that can be used both for
calibrating or debugging digital interfaces.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 include/linux/iio/backend.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/include/linux/iio/backend.h b/include/linux/iio/backend.h
index 9d0dba7ab9e7..2b9d1aa86552 100644
--- a/include/linux/iio/backend.h
+++ b/include/linux/iio/backend.h
@@ -56,6 +56,8 @@ enum iio_backend_test_pattern {
 	IIO_BACKEND_NO_TEST_PATTERN,
 	/* modified prbs9 */
 	IIO_BACKEND_ADI_PRBS_9A = 32,
+	/* modified prbs23 */
+	IIO_BACKEND_ADI_PRBS_23A,
 	IIO_BACKEND_TEST_PATTERN_MAX
 };
 

-- 
2.45.2

