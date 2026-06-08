From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Mon, 08 Jun 2026 13:33:25 +0300
Subject: [PATCH v3 1/5] ufs: Expose selected UFS functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ufs_tool2-v3-1-a9f181e86229@mobileye.com>
References: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
In-Reply-To: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3263;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=tjVVnkP/yyjwwqNo6tVzv9fccgwCQWNEWJR2cUikUkk=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJpqUCc2cgzcbqEL8AyUlDmbqeRJ7EC2hHEtVN
 y/Qi/rVbqSJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiaalAAKCRCfmumUluiO
 OfOPD/9tQTrR7PxnlUJYtp2dynahoED/rmcduan5Vx6L41iOkWMr0UHmiyEHq/IgCj2dglvO50J
 cEGTNqKg4kT0OnbSz7dgFC0gIhK5Af+TGAMOk4el9MmddnpVyPonH0kKcpmb65ALtFyBmtLiGw5
 g3JRxXxHHhPb8W8Ro0YifvqfpvKgh7II0tgDHaRCWXd9ldwxG/lWZadOcoUtv6fNyxq0XSd5TDN
 N7Etb9z+c5fknR7lYAqf+j58nQ/gTuLUGFRJ9hD3YKJbF0GakUlSh/usTqaKd5UKqTsIBHOwToo
 lH0S3X+xKmD1vDT5p46OOmOopWCwbPQae/GfAj3S2aBA4hL15af92WGKcyuNoDLizTjhxG90pQQ
 sEj8HN2L7HblEualkTKPJ+kcaCsO2KqWwpVyzI8MdyT9+WvN+jix5/NZsu6sBjZPd0+cOeCuqbe
 3UmqnZE3pr7PMg/qVITKg6WbzRXAqXueqJS897N5awtZIne8+02VcB0HRg/PEJ0qTXWZAyrgF/1
 8sNLUpLE35cg8/JasFwONv3xaf4QoD60r7mzOE/zsIRKbIUcajQPAuB82Ybsxh8jUs5Rns+msdb
 Yh/iWuHijNg/uYC7HbTSKBS3FrCs+gtdshcS5+flCZF/k6LgopKa9MiX71xXGuCYM6Q4hzC62VA
 1tVw/W7yieaObnw==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove static qualifier from selected functios to allow
future use

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 drivers/ufs/ufs-uclass.c | 18 +++++++++---------
 drivers/ufs/ufs.h        | 13 +++++++++++++
 2 files changed, 22 insertions(+), 9 deletions(-)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 6a51f337e47..78f6064ddea 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -757,7 +757,7 @@ static inline u8 ufshcd_get_upmcrs(struct ufs_hba *hba)
  *
  * Flush cache in aligned address..address+size range.
  */
-static void ufshcd_cache_flush(void *addr, unsigned long size)
+void ufshcd_cache_flush(void *addr, unsigned long size)
 {
 	uintptr_t start_addr = (uintptr_t)addr & ~(ARCH_DMA_MINALIGN - 1);
 	uintptr_t end_addr = ALIGN((uintptr_t)addr + size, ARCH_DMA_MINALIGN);
@@ -1089,8 +1089,8 @@ static inline void ufshcd_init_query(struct ufs_hba *hba,
 /**
  * ufshcd_query_flag() - API function for sending flag query requests
  */
-static int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
-			     enum flag_idn idn, bool *flag_res)
+int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
+		      enum flag_idn idn, bool *flag_res)
 {
 	struct ufs_query_req *request = NULL;
 	struct ufs_query_res *response = NULL;
@@ -1320,9 +1320,9 @@ out:
 /**
  * ufshcd_query_descriptor_retry - API function for sending descriptor requests
  */
-static int ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
-					 enum desc_idn idn, u8 index, u8 selector,
-					 u8 *desc_buf, int *buf_len)
+int  ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
+				   enum desc_idn idn, u8 index, u8 selector,
+				   u8 *desc_buf, int *buf_len)
 {
 	int err;
 	int retries;
@@ -1457,9 +1457,9 @@ static int ufshcd_map_desc_id_to_length(struct ufs_hba *hba, enum desc_idn desc_
  * ufshcd_read_desc_param - read the specified descriptor parameter
  *
  */
-static int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
-				  int desc_index, u8 param_offset,
-				  u8 *param_read_buf, u8 param_size)
+int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
+			   int desc_index, u8 param_offset,
+			   u8 *param_read_buf, u8 param_size)
 {
 	int ret;
 	u8 *desc_buf;
diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index 0f6c93fbce7..213b489e5e4 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -809,4 +809,17 @@ static inline void ufshcd_rmwl(struct ufs_hba *hba, u32 mask, u32 val, u32 reg)
 
 int ufshcd_probe(struct udevice *dev, struct ufs_hba_ops *hba_ops);
 
+int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
+			   int desc_index, u8 param_offset, u8 *param_read_buf,
+			   u8 param_size);
+
+void ufshcd_cache_flush(void *addr, unsigned long size);
+
+int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
+		      enum flag_idn idn, bool *flag_res);
+
+int ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
+				  enum desc_idn idn, u8 index, u8 selector,
+				  u8 *desc_buf, int *buf_len);
+
 #endif

-- 
2.43.0

