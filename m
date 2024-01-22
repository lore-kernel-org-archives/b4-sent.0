From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 22 Jan 2024 15:15:41 +0100
Subject: [PATCH] iio: commom: st_sensors: ensure proper DMA alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240122-dev_dma_safety_stm-v1-1-3a021614cbfb@analog.com>
X-B4-Tracking: v=1; b=H4sIAIx4rmUC/x3MTQqAIBBA4avErBPUQqGrRIjoWLPoByeikO6et
 PwW7xVgzIQMQ1Mg40VM+1ah2gbC4rcZBcVq0FL3UmktIl4urt6xT3g+js9VBCuVMbZLPQao4ZE
 x0f1Px+l9P0UNhMdkAAAA
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Denis Ciocca <denis.ciocca@st.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705932947; l=1249;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=9nc0+XuBHPSAJAnQqlzH9FoKWs6rxhh6XjIELsbUJ8k=;
 b=XkTCa2kD81PCT+5L9/nqtyL6c8/7wjsk3pgUGHQbVGGLvtudi/0zBwePsZ3f2i8S3xWvnh9jg
 LZTeCBTwsMjDJ5ecxSwGTVSZz0/NmxwaKL3OU5jUqEB+DLsLSyvM7RE
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Aligning the buffer to the L1 cache is not sufficient in some platforms
as they might have larger cacheline sizes for caches after L1 and thus,
we can't guarantee DMA safety.

That was the whole reason to introduce IIO_DMA_MINALIGN in [1]. Do the same
for st_sensors common buffer.

[1]: https://lore.kernel.org/linux-iio/20220508175712.647246-2-jic23@kernel.org/

Fixes: e031d5f558f1 ("iio:st_sensors: remove buffer allocation at each buffer enable")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 include/linux/iio/common/st_sensors.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/iio/common/st_sensors.h b/include/linux/iio/common/st_sensors.h
index 607c3a89a647..a02652cf4862 100644
--- a/include/linux/iio/common/st_sensors.h
+++ b/include/linux/iio/common/st_sensors.h
@@ -258,7 +258,7 @@ struct st_sensor_data {
 	bool hw_irq_trigger;
 	s64 hw_timestamp;
 
-	char buffer_data[ST_SENSORS_MAX_BUFFER_SIZE] ____cacheline_aligned;
+	char buffer_data[ST_SENSORS_MAX_BUFFER_SIZE] __aligned(IIO_DMA_MINALIGN);
 
 	struct mutex odr_lock;
 };

---
base-commit: f9c0358aadcba16d04d139a5412b413eeee87afe
change-id: 20240122-dev_dma_safety_stm-c7016673f4ec
--

Thanks!
- Nuno Sá

